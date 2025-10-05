from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models.debt import Debt
from app.models.user import User
from app.models.receivable import Receivable

debts_bp = Blueprint('debts', __name__)

@debts_bp.route('/', methods=['GET'])
@jwt_required()
def get_user_debts():
    """Obter todas as dívidas do usuário (consolidadas por devedor/credor)"""
    user_id = get_jwt_identity()
    
    # Buscar dívidas onde o usuário é devedor ou credor (apenas pendentes)
    debts_as_debtor = Debt.get_pending_debts(debtor_id=user_id).all()
    debts_as_creditor = Debt.get_pending_debts(creditor_id=user_id).all()
    
    # Converter para dicionário com informações extras
    debts_data = []
    
    # Dívidas onde o usuário deve (valores negativos) - não precisam consolidação
    for debt in debts_as_debtor:
        debt_dict = debt.to_dict()
        debt_dict['type'] = 'owe'  # o usuário deve
        debt_dict['amount'] = -abs(debt_dict['amount'])  # valor negativo
        debt_dict['other_user'] = debt.creditor.name
        debt_dict['other_user_id'] = debt.creditor_id
        debt_dict['expense_description'] = debt.expense.description if debt.expense else 'Despesa removida'
        debts_data.append(debt_dict)
    
    # Dívidas onde devem ao usuário - CONSOLIDAR POR DEVEDOR
    from collections import defaultdict
    consolidated_debts = defaultdict(lambda: {
        'total_amount': 0.0,
        'group_amount': 0.0,
        'purchased_amount': 0.0,
        'debtor_name': '',
        'debtor_id': '',
        'descriptions': [],
        'debt_ids': []
    })
    
    for debt in debts_as_creditor:
        debtor_id = debt.debtor_id
        amount = abs(debt.amount)
        
        # Identificar origem da dívida
        related_receivable = Receivable.query.filter_by(
            consolidated_group_id=debt.debtor_id,
            status='sold'
        ).first()
        
        is_purchased = (related_receivable and related_receivable.buyer_id == user_id)
        
        # Consolidar informações
        consolidated_debts[debtor_id]['total_amount'] += amount
        consolidated_debts[debtor_id]['debtor_name'] = debt.debtor.name
        consolidated_debts[debtor_id]['debtor_id'] = debtor_id
        consolidated_debts[debtor_id]['descriptions'].append(debt.expense.description if debt.expense else 'Despesa removida')
        consolidated_debts[debtor_id]['debt_ids'].append(str(debt.id))
        
        if is_purchased:
            consolidated_debts[debtor_id]['purchased_amount'] += amount
        else:
            consolidated_debts[debtor_id]['group_amount'] += amount
    
    # Converter consolidação em formato de resposta
    for debtor_id, data in consolidated_debts.items():
        debt_dict = {
            'id': f"consolidated_{debtor_id}",
            'type': 'owed',
            'amount': data['total_amount'],
            'other_user': data['debtor_name'],
            'other_user_id': debtor_id,
            'debtor_id': debtor_id,
            'creditor_id': user_id,
            'status': 'pending',
            'expense_description': f"Saldo consolidado ({len(data['descriptions'])} despesas)",
            'debt_ids': data['debt_ids']  # Para permitir pagamento individual se necessário
        }
        
        # Adicionar detalhes da consolidação
        if data['group_amount'] > 0 and data['purchased_amount'] > 0:
            # Tem ambos os tipos
            debt_dict['source'] = 'mixed'
            debt_dict['group_amount'] = data['group_amount']
            debt_dict['purchased_amount'] = data['purchased_amount']
            debt_dict['source_description'] = f"R$ {data['group_amount']:.2f} (grupo) + R$ {data['purchased_amount']:.2f} (título comprado)"
            debt_dict['can_resell'] = True  # Pode vender a parte do grupo
        elif data['purchased_amount'] > 0:
            # Apenas título comprado
            debt_dict['source'] = 'purchased_title'
            debt_dict['source_description'] = 'Adquirido via compra de título'
            debt_dict['can_resell'] = False
        else:
            # Apenas dívida de grupo
            debt_dict['source'] = 'group_debt'
            debt_dict['source_description'] = 'Dívida de grupo'
            debt_dict['can_resell'] = True
            
        debts_data.append(debt_dict)
    
    # Ordenar por valor (maiores primeiro)
    debts_data.sort(key=lambda x: abs(x['amount']), reverse=True)
    
    return jsonify({
        'debts': debts_data,
        'total_count': len(debts_data)
    })

@debts_bp.route('/consolidated', methods=['GET'])
@jwt_required()
def get_consolidated_debts():
    """Obter dívidas consolidadas por usuário em todos os grupos (para marketplace)"""
    from app.models.user import GroupMember
    from app.models.expense import Expense
    from collections import defaultdict
    
    user_id = get_jwt_identity()
    
    # Buscar todos os grupos do usuário
    user_groups = GroupMember.query.filter_by(user_id=user_id).all()
    
    # Consolidar saldos por usuário em todos os grupos
    global_balances = defaultdict(float)
    
    for group_member in user_groups:
        group_id = group_member.group_id
        
        # Calcular saldos do grupo usando a mesma lógica da otimização
        group_balances = _calculate_group_balances(group_id)
        
        # Somar os saldos de cada usuário globalmente
        for other_user_id, balance in group_balances.items():
            if other_user_id != user_id:
                # Se balance é positivo para o outro usuário, significa que ele me deve
                # Se balance é negativo para o outro usuário, significa que eu devo para ele
                # Queremos apenas quem me deve (balance negativo do devedor = positivo para mim)
                global_balances[other_user_id] -= balance  # Inverter a perspectiva
    
    # Criar títulos apenas para quem me deve (saldo positivo)
    consolidated_debts = []
    for debtor_id, amount_owed in global_balances.items():
        if amount_owed > 0.01:  # Apenas dívidas significativas
            # Verificar se já existe um recebível ativo para este devedor
            existing_receivable = Receivable.query.filter_by(
                owner_id=user_id,
                consolidated_group_id=debtor_id,
                status='for_sale'
            ).first()
            
            # Também verificar se há recebíveis vendidos recentemente (pode ser ainda válido)
            sold_receivable = Receivable.query.filter_by(
                owner_id=user_id,
                consolidated_group_id=debtor_id,
                status='sold'
            ).first()
            
            # Se já existe recebível ativo (à venda ou vendido), pular esta dívida
            if existing_receivable or sold_receivable:
                print(f"[DEBUG] Skipping debt for {debtor_id} - already has receivable")
                continue
                
            # Buscar informações do devedor
            debtor = User.query.get(debtor_id)
            if not debtor:
                continue
                
            consolidated_debts.append({
                'id': f"consolidated_{debtor_id}",  # ID único por devedor
                'debtor_id': debtor_id,
                'creditor_id': user_id,
                'amount': amount_owed,
                'other_user': debtor.name,
                'other_user_id': debtor_id,
                'type': 'owed',
                'status': 'pending',
                'expense_description': f"Saldo consolidado de todos os grupos"
            })
    
    # Ordenar por valor (maiores primeiro)
    consolidated_debts.sort(key=lambda x: x['amount'], reverse=True)
    
    return jsonify({
        'debts': consolidated_debts,
        'total_count': len(consolidated_debts)
    })


def _calculate_group_balances(group_id):
    """Calcula o saldo líquido de cada membro do grupo baseado apenas em dívidas PENDENTES"""
    from app.models.user import GroupMember
    from collections import defaultdict
    
    # Buscar membros do grupo
    members = GroupMember.query.filter_by(group_id=group_id).all()
    if len(members) == 0:
        return {}
    
    # NOVA LÓGICA: Calcular com base apenas em dívidas PENDENTES
    balances = defaultdict(float)
    
    # Buscar todas as dívidas pendentes relacionadas a este grupo
    # (dívidas entre membros deste grupo)
    member_ids = [member.user_id for member in members]
    
    pending_debts = Debt.get_pending_debts().filter(
        Debt.creditor_id.in_(member_ids),
        Debt.debtor_id.in_(member_ids)
    ).all()
    
    # Calcular saldos baseado nas dívidas pendentes
    for debt in pending_debts:
        # Creditor tem saldo positivo (deve receber)
        balances[debt.creditor_id] += debt.amount
        # Debtor tem saldo negativo (deve pagar)  
        balances[debt.debtor_id] -= debt.amount
    
    # Converter para dict normal e garantir que todos os membros estejam presentes
    final_balances = {}
    for member in members:
        final_balances[member.user_id] = balances.get(member.user_id, 0.0)
    
    return final_balances

@debts_bp.route('/summary', methods=['GET'])
@jwt_required()
def get_debts_summary():
    """Obter resumo das dívidas do usuário"""
    user_id = get_jwt_identity()
    
    # Calcular totais (apenas dívidas pendentes)
    debts_as_debtor = Debt.get_pending_debts(debtor_id=user_id).all()
    debts_as_creditor = Debt.get_pending_debts(creditor_id=user_id).all()
    
    total_owe = sum(debt.amount for debt in debts_as_debtor)  # o que devo
    total_owed = sum(debt.amount for debt in debts_as_creditor)  # o que me devem
    
    net_balance = total_owed - total_owe  # saldo líquido
    
    return jsonify({
        'total_owe': float(total_owe),
        'total_owed': float(total_owed),
        'net_balance': float(net_balance),
        'debts_count': len(debts_as_debtor),
        'credits_count': len(debts_as_creditor)
    })

@debts_bp.route('/<debt_id>/pay', methods=['POST'])
@jwt_required()
def pay_debt(debt_id):
    """Marcar dívida como paga"""
    user_id = get_jwt_identity()
    
    debt = Debt.query.get(debt_id)
    if not debt:
        return jsonify({'error': 'Dívida não encontrada'}), 404
    
    # Verificar se o usuário é o devedor
    if debt.debtor_id != user_id:
        return jsonify({'error': 'Você não pode pagar esta dívida'}), 403
    
    # Marcar como paga
    debt.mark_as_paid()
    
    return jsonify({
        'message': 'Dívida marcada como paga',
        'debt': debt.to_dict()
    })

@debts_bp.route('/<debt_id>/confirm', methods=['POST'])
@jwt_required()
def confirm_payment(debt_id):
    """Confirmar pagamento de dívida (apenas para o credor)"""
    user_id = get_jwt_identity()
    
    debt = Debt.query.get(debt_id)
    if not debt:
        return jsonify({'error': 'Dívida não encontrada'}), 404
    
    # Verificar se o usuário é o credor
    if debt.creditor_id != user_id:
        return jsonify({'error': 'Você não pode confirmar esta dívida'}), 403
    
    # Confirmar pagamento
    debt.confirm_payment()
    
    return jsonify({
        'message': 'Pagamento confirmado',
        'debt': debt.to_dict()
    })