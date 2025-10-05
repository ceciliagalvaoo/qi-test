from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models.user import User
from app.models.receivable import Receivable
from app.models.debt import Debt
from app.models.wallet import Wallet, Transaction

marketplace_bp = Blueprint('marketplace', __name__)

@marketplace_bp.route('/', methods=['GET'])
@jwt_required()
def get_marketplace_items():
    """Obter todos os títulos à venda no marketplace"""
    try:
        user_id = get_jwt_identity()
        print(f"[DEBUG] Getting marketplace items for user: {user_id}")
        
        # Buscar todos os recebíveis à venda, exceto os do usuário atual
        receivables = Receivable.query.filter(
            Receivable.status == 'for_sale',
            Receivable.owner_id != user_id
        ).all()
        
        # Debug: mostrar todos os recebíveis à venda
        all_for_sale = Receivable.query.filter(Receivable.status == 'for_sale').all()
        print(f"[DEBUG] Total receivables for sale: {len(all_for_sale)}")
        for r in all_for_sale:
            print(f"[DEBUG] Receivable {r.id[:8]}... owner: {r.owner_id}, current user: {user_id}, match: {r.owner_id == user_id}")
        
        print(f"[DEBUG] Found {len(receivables)} receivables after filtering")
    
        # Retornar dados anonimizados
        marketplace_items = []
        for receivable in receivables:
            item = receivable.to_dict(anonymous=True)
            item['seller_anonymous_id'] = f"Usuário {receivable.owner_id}"
            marketplace_items.append(item)
        
        # Ordenar por lucro estimado (descendente)
        marketplace_items.sort(key=lambda x: x['profit_estimated'], reverse=True)
        
        print(f"[DEBUG] Returning {len(marketplace_items)} marketplace items")
        return jsonify(marketplace_items)
        
    except Exception as e:
        print(f"[ERROR] Error in get_marketplace_items: {str(e)}")
        return jsonify({'error': f'Erro ao carregar marketplace: {str(e)}'}), 500

@marketplace_bp.route('/sell', methods=['POST'])
@jwt_required()
def create_receivable():
    """Colocar uma dívida à venda"""
    user_id = get_jwt_identity()
    data = request.get_json()
    
    print(f"\n🔥 [MARKETPLACE] NOVA CHAMADA CREATE_RECEIVABLE")
    print(f"[MARKETPLACE] User: {user_id[:8]}...")
    print(f"[MARKETPLACE] Data recebida: {data}")
    
    # Validar dados
    selling_price = float(data.get('selling_price', 0))
    
    # Verificar se é uma dívida consolidada (ID fictício) ou individual
    debt_id = data.get('debt_id')
    debtor_id = data.get('debtor_id')
    
    if debt_id and debt_id.startswith('consolidated_'):
        # Extrair debtor_id do ID consolidado
        debtor_id = debt_id.split('consolidated_')[1]
        debt_id = None  # ⭐ CORREÇÃO: Limpar debt_id para que seja tratado como consolidado
        print(f"[MARKETPLACE] ID consolidado detectado - debtor_id: {debtor_id[:8]}...")
        
    if debtor_id:
        # Validar se o devedor existe e calcular saldo consolidado real
        from app.models.user import GroupMember
        from collections import defaultdict
        
        debtor = User.query.get(debtor_id)
        if not debtor:
            return jsonify({'error': 'Devedor não encontrado'}), 404
        
        # Calcular saldo consolidado real usando a mesma lógica do endpoint /consolidated
        user_groups = GroupMember.query.filter_by(user_id=user_id).all()
        global_balance_for_debtor = 0.0
        
        for group_member in user_groups:
            group_id = group_member.group_id
            
            # Verificar se o devedor também está neste grupo
            debtor_in_group = GroupMember.query.filter_by(
                user_id=debtor_id, 
                group_id=group_id
            ).first()
            
            if debtor_in_group:
                # Calcular saldos do grupo
                from app.routes.debts import _calculate_group_balances
                group_balances = _calculate_group_balances(group_id)
                
                debtor_balance = group_balances.get(debtor_id, 0.0)
                # Se balance é negativo para o devedor, ele me deve (inverter perspectiva)
                global_balance_for_debtor += -debtor_balance
        
        if global_balance_for_debtor <= 0.01:
            return jsonify({'error': 'Este usuário não tem saldo devedor significativo'}), 400
            
        total_amount = global_balance_for_debtor
        
        # Verificar se já existe um recebível consolidado para este devedor
        existing_receivable = Receivable.query.filter_by(
            owner_id=user_id,
            consolidated_group_id=debtor_id,  # Usar o novo campo
            status='for_sale'
        ).first()
        
        if existing_receivable:
            return jsonify({'error': 'Já existe um título à venda para este devedor'}), 400
            
    elif debt_id:
        # Dívida individual
        debt = Debt.query.get(debt_id)
        if not debt:
            return jsonify({'error': 'Dívida não encontrada'}), 404
            
        # Verificar se o usuário é o credor da dívida
        if debt.creditor_id != user_id:
            return jsonify({'error': 'Você não é o credor desta dívida'}), 403
            
        # Verificar se a dívida está pendente
        if debt.status != 'pending':
            return jsonify({'error': 'Apenas dívidas pendentes podem ser vendidas'}), 400
            
        debts = [debt]
        total_amount = debt.amount
        debtor_id = debt.debtor_id
        
        # Verificar se já não existe um recebível para esta dívida
        existing_receivable = Receivable.query.filter_by(debt_id=debt.id, status='for_sale').first()
        if existing_receivable:
            return jsonify({'error': 'Esta dívida já está à venda'}), 400
    else:
        return jsonify({'error': 'debt_id ou debtor_id é obrigatório'}), 400
    
    # Validar preço de venda (deve ser menor que o valor nominal total)
    if selling_price >= total_amount:
        return jsonify({'error': 'Preço de venda deve ser menor que o valor total das dívidas'}), 400
    
    # Criar um único recebível consolidado
    if debtor_id and not debt_id:
        # Recebível consolidado (virtual)
        receivable = Receivable(
            owner_id=user_id,
            debt_id=None,  # Sem dívida específica, é consolidado
            nominal_amount=total_amount,
            selling_price=selling_price,
            consolidated_group_id=debtor_id  # ID do devedor consolidado
        )
    else:
        # Recebível individual (dívida específica)
        receivable = Receivable(
            owner_id=user_id,
            debt_id=debt_id,
            nominal_amount=total_amount,
            selling_price=selling_price,
            consolidated_group_id=None
        )
    
    db.session.add(receivable)
    
    # ====== CRÍTICO: Marcar dívidas como vendidas/indisponíveis ======
    if debtor_id and not debt_id:
        # Para recebível consolidado, marcar TODAS as dívidas pendentes deste devedor
        from datetime import datetime
        
        # Buscar todas as dívidas pendentes deste devedor para este credor
        debts_to_mark = Debt.query.filter_by(
            creditor_id=user_id,
            debtor_id=debtor_id,
            status='pending'
        ).all()
        
        for debt in debts_to_mark:
            debt.status = 'sold_as_title'
            debt.sold_at = datetime.utcnow()
            
        print(f"[MARKETPLACE] Marcadas {len(debts_to_mark)} dívidas como sold_as_title para debtor {debtor_id}")
        
    elif debt_id:
        # Para dívida individual, marcar apenas ela
        from datetime import datetime
        debt = Debt.query.get(debt_id)
        if debt:
            debt.status = 'sold_as_title'
            debt.sold_at = datetime.utcnow()
            print(f"[MARKETPLACE] Dívida {debt_id[:8]}... marcada como sold_as_title")
    
    try:
        db.session.commit()
        
        print(f"🎯 [MARKETPLACE] SUCESSO! Receivable {receivable.id[:8]}... criado")
        print(f"[MARKETPLACE] ===== FIM DA CHAMADA =====\n")
        
        return jsonify({
            'message': 'Título colocado à venda com sucesso',
            'receivable': receivable.to_dict(),
            'total_nominal': total_amount,
            'selling_price': selling_price
        }), 201
            
    except Exception as e:
        db.session.rollback()
        print(f'[ERROR] Erro ao criar recebível: {e}')
        return jsonify({'error': 'Erro interno do servidor'}), 500

@marketplace_bp.route('/buy/<receivable_id>', methods=['POST'])
@jwt_required()
def buy_receivable(receivable_id):
    """Comprar um título de recebível"""
    user_id = get_jwt_identity()
    
    # Buscar o recebível
    receivable = Receivable.query.get(receivable_id)
    if not receivable:
        return jsonify({'error': 'Título não encontrado'}), 404
    
    # Verificar se está à venda
    if receivable.status != 'for_sale':
        return jsonify({'error': 'Título não está disponível para venda'}), 400
    
    # Verificar se não é o próprio dono
    if receivable.owner_id == user_id:
        return jsonify({'error': 'Você não pode comprar seu próprio título'}), 400
    
    # Verificar saldo do comprador
    buyer_wallet = Wallet.query.filter_by(user_id=user_id).first()
    if not buyer_wallet or buyer_wallet.balance < receivable.selling_price:
        return jsonify({'error': 'Saldo insuficiente'}), 400
    
    try:
        # Buscar carteira do vendedor
        seller_wallet = Wallet.query.filter_by(user_id=receivable.owner_id).first()
        if not seller_wallet:
            return jsonify({'error': 'Carteira do vendedor não encontrada'}), 404
        
        # Usar os métodos da wallet sem commit automático para gerenciar a transação completa
        if not buyer_wallet.withdraw_funds(
            receivable.selling_price, 
            f'Compra de título #{receivable.id[:8]}... (R$ {receivable.nominal_amount:.2f})',
            auto_commit=False
        ):
            return jsonify({'error': 'Erro ao debitar comprador'}), 500
            
        if not seller_wallet.add_funds(
            receivable.selling_price,
            f'Venda de título #{receivable.id[:8]}... (R$ {receivable.nominal_amount:.2f})',
            auto_commit=False
        ):
            db.session.rollback()
            return jsonify({'error': 'Erro ao creditar vendedor'}), 500
        
        # Realizar a compra (transferir a dívida)
        if receivable.sell_to_buyer(user_id):
            # Commit final de toda a transação
            db.session.commit()
            return jsonify({
                'message': 'Título comprado com sucesso',
                'receivable': receivable.to_dict(),
                'profit_when_paid': receivable.nominal_amount - receivable.selling_price
            })
        else:
            # Reverter todas as transações
            db.session.rollback()
            return jsonify({'error': 'Erro ao transferir propriedade do título'}), 500
            
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Erro ao processar compra: {str(e)}'}), 500

@marketplace_bp.route('/my-receivables', methods=['GET'])
@jwt_required()
def get_my_receivables():
    """Obter meus recebíveis (vendendo e comprados)"""
    user_id = get_jwt_identity()
    
    # Recebíveis que estou vendendo
    selling = Receivable.query.filter_by(owner_id=user_id, status='for_sale').all()
    
    # Recebíveis que comprei
    bought = Receivable.query.filter_by(buyer_id=user_id, status='sold').all()
    
    # Recebíveis que vendi (foram comprados por outros)
    sold = Receivable.query.filter_by(owner_id=user_id, status='sold').all()
    
    return jsonify({
        'selling': [r.to_dict() for r in selling],
        'bought': [r.to_dict() for r in bought],
        'sold': [r.to_dict() for r in sold]
    })

@marketplace_bp.route('/cancel/<receivable_id>', methods=['DELETE'])
@jwt_required()
def cancel_receivable(receivable_id):
    """Cancelar venda de um recebível"""
    user_id = get_jwt_identity()
    
    receivable = Receivable.query.get(receivable_id)
    if not receivable:
        return jsonify({'error': 'Título não encontrado'}), 404
    
    # Verificar se é o dono
    if receivable.owner_id != user_id:
        return jsonify({'error': 'Você não é o dono deste título'}), 403
    
    # Verificar se está à venda
    if receivable.status != 'for_sale':
        return jsonify({'error': 'Título não está à venda'}), 400
    
    # ====== CRÍTICO: Reverter dívidas para status 'pending' ======
    try:
        if receivable.consolidated_group_id:
            # Recebível consolidado - reverter todas as dívidas do devedor
            debts_to_revert = Debt.query.filter_by(
                creditor_id=user_id,
                debtor_id=receivable.consolidated_group_id,
                status='sold_as_title'
            ).all()
            
            for debt in debts_to_revert:
                debt.status = 'pending'
                debt.sold_at = None
                
            print(f"[MARKETPLACE] Revertidas {len(debts_to_revert)} dívidas para pending")
            
        elif receivable.debt_id:
            # Recebível individual
            debt = Debt.query.get(receivable.debt_id)
            if debt and debt.status == 'sold_as_title':
                debt.status = 'pending'
                debt.sold_at = None
                print(f"[MARKETPLACE] Dívida {debt.id[:8]}... revertida para pending")
        
        receivable.status = 'cancelled'
        db.session.commit()
        
        return jsonify({'message': 'Venda cancelada com sucesso'})
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Erro ao cancelar venda: {str(e)}'}), 500

@marketplace_bp.route('/stats', methods=['GET'])
@jwt_required()
def get_marketplace_stats():
    """Obter estatísticas do marketplace"""
    # Total de títulos à venda
    total_for_sale = Receivable.query.filter_by(status='for_sale').count()
    
    # Volume total em venda
    total_volume = db.session.query(db.func.sum(Receivable.selling_price))\
        .filter_by(status='for_sale').scalar() or 0
    
    # Maior desconto oferecido
    max_discount = db.session.query(
        db.func.max(Receivable.nominal_amount - Receivable.selling_price)
    ).filter_by(status='for_sale').scalar() or 0
    
    return jsonify({
        'total_titles_for_sale': total_for_sale,
        'total_volume': total_volume,
        'max_discount_available': max_discount,
        'average_discount': (max_discount / 2) if max_discount > 0 else 0
    })