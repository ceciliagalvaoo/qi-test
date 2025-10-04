from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models.user import User
from app.models.receivable import Receivable
from app.models.debt import Debt
from app.models.wallet import Wallet

marketplace_bp = Blueprint('marketplace', __name__)

@marketplace_bp.route('/', methods=['GET'])
@jwt_required()
def get_marketplace_items():
    """Obter todos os títulos à venda no marketplace"""
    user_id = get_jwt_identity()
    
    # Buscar todos os recebíveis à venda, exceto os do usuário atual
    receivables = Receivable.query.filter(
        Receivable.status == 'for_sale',
        Receivable.owner_id != user_id
    ).all()
    
    # Retornar dados anonimizados
    marketplace_items = []
    for receivable in receivables:
        item = receivable.to_dict(anonymous=True)
        item['seller_anonymous_id'] = f"Usuário {receivable.owner_id}"
        marketplace_items.append(item)
    
    # Ordenar por lucro estimado (descendente)
    marketplace_items.sort(key=lambda x: x['profit_estimated'], reverse=True)
    
    return jsonify(marketplace_items)

@marketplace_bp.route('/sell', methods=['POST'])
@jwt_required()
def create_receivable():
    """Colocar uma dívida à venda"""
    user_id = get_jwt_identity()
    data = request.get_json()
    
    # Validar dados
    required_fields = ['debt_id', 'selling_price']
    for field in required_fields:
        if field not in data:
            return jsonify({'error': f'{field} é obrigatório'}), 400
    
    # Buscar a dívida
    debt = Debt.query.get(data['debt_id'])
    if not debt:
        return jsonify({'error': 'Dívida não encontrada'}), 404
    
    # Verificar se o usuário é o credor da dívida
    if debt.creditor_id != user_id:
        return jsonify({'error': 'Você não é o credor desta dívida'}), 403
    
    # Verificar se a dívida está pendente
    if debt.status != 'pending':
        return jsonify({'error': 'Apenas dívidas pendentes podem ser vendidas'}), 400
    
    # Verificar se já não existe um recebível para esta dívida
    existing_receivable = Receivable.query.filter_by(debt_id=debt.id, status='for_sale').first()
    if existing_receivable:
        return jsonify({'error': 'Esta dívida já está à venda'}), 400
    
    selling_price = float(data['selling_price'])
    
    # Validar preço de venda (deve ser menor que o valor nominal)
    if selling_price >= debt.amount:
        return jsonify({'error': 'Preço de venda deve ser menor que o valor da dívida'}), 400
    
    # Criar recebível
    receivable = Receivable(
        owner_id=user_id,
        debt_id=debt.id,
        nominal_amount=debt.amount,
        selling_price=selling_price
    )
    
    db.session.add(receivable)
    db.session.commit()
    
    return jsonify({
        'message': 'Título colocado à venda com sucesso',
        'receivable': receivable.to_dict()
    }), 201

@marketplace_bp.route('/buy/<int:receivable_id>', methods=['POST'])
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
    
    # Realizar a compra
    if receivable.sell_to_buyer(user_id):
        return jsonify({
            'message': 'Título comprado com sucesso',
            'receivable': receivable.to_dict(),
            'profit_when_paid': receivable.nominal_amount - receivable.selling_price
        })
    else:
        return jsonify({'error': 'Erro ao processar compra'}), 500

@marketplace_bp.route('/my-receivables', methods=['GET'])
@jwt_required()
def get_my_receivables():
    """Obter meus recebíveis (vendendo e comprados)"""
    user_id = get_jwt_identity()
    
    # Recebíveis que estou vendendo
    selling = Receivable.query.filter_by(owner_id=user_id, status='for_sale').all()
    
    # Recebíveis que comprei
    bought = Receivable.query.filter_by(buyer_id=user_id, status='sold').all()
    
    return jsonify({
        'selling': [r.to_dict() for r in selling],
        'bought': [r.to_dict() for r in bought]
    })

@marketplace_bp.route('/cancel/<int:receivable_id>', methods=['DELETE'])
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
    
    receivable.status = 'cancelled'
    db.session.commit()
    
    return jsonify({'message': 'Venda cancelada com sucesso'})

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