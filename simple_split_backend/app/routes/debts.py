from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models.debt import Debt
from app.models.user import User

debts_bp = Blueprint('debts', __name__)

@debts_bp.route('/', methods=['GET'])
@jwt_required()
def get_user_debts():
    """Obter todas as dívidas do usuário"""
    user_id = get_jwt_identity()
    
    # Buscar dívidas onde o usuário é devedor ou credor
    debts_as_debtor = Debt.query.filter_by(debtor_id=user_id, status='pending').all()
    debts_as_creditor = Debt.query.filter_by(creditor_id=user_id, status='pending').all()
    
    # Converter para dicionário com informações extras
    debts_data = []
    
    # Dívidas onde o usuário deve (valores negativos)
    for debt in debts_as_debtor:
        debt_dict = debt.to_dict()
        debt_dict['type'] = 'owe'  # o usuário deve
        debt_dict['amount'] = -abs(debt_dict['amount'])  # valor negativo
        debt_dict['other_user'] = debt.creditor.name
        debt_dict['other_user_id'] = debt.creditor_id
        debt_dict['expense_description'] = debt.expense.description if debt.expense else 'Despesa removida'
        debts_data.append(debt_dict)
    
    # Dívidas onde devem ao usuário (valores positivos)
    for debt in debts_as_creditor:
        debt_dict = debt.to_dict()
        debt_dict['type'] = 'owed'  # devem ao usuário
        debt_dict['amount'] = abs(debt_dict['amount'])  # valor positivo
        debt_dict['other_user'] = debt.debtor.name
        debt_dict['other_user_id'] = debt.debtor_id
        debt_dict['expense_description'] = debt.expense.description if debt.expense else 'Despesa removida'
        debts_data.append(debt_dict)
    
    # Ordenar por valor (maiores primeiro)
    debts_data.sort(key=lambda x: abs(x['amount']), reverse=True)
    
    return jsonify({
        'debts': debts_data,
        'total_count': len(debts_data)
    })

@debts_bp.route('/summary', methods=['GET'])
@jwt_required()
def get_debts_summary():
    """Obter resumo das dívidas do usuário"""
    user_id = get_jwt_identity()
    
    # Calcular totais
    debts_as_debtor = Debt.query.filter_by(debtor_id=user_id, status='pending').all()
    debts_as_creditor = Debt.query.filter_by(creditor_id=user_id, status='pending').all()
    
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

@debts_bp.route('/<int:debt_id>/pay', methods=['POST'])
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

@debts_bp.route('/<int:debt_id>/confirm', methods=['POST'])
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