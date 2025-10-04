from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models.expense import Expense
from app.models.group import Group
from app.models.user import GroupMember
from datetime import datetime, timedelta

expenses_bp = Blueprint('expenses', __name__)

@expenses_bp.route('/', methods=['GET'])
@jwt_required()
def get_user_expenses():
    """Obter todas as despesas do usuário (recentes)"""
    user_id = get_jwt_identity()
    
    # Buscar grupos do usuário
    user_groups = db.session.query(GroupMember.group_id).filter_by(user_id=user_id).subquery()
    
    # Buscar despesas dos últimos 30 dias nos grupos do usuário
    thirty_days_ago = datetime.now() - timedelta(days=30)
    
    expenses = Expense.query.join(Group, Expense.group_id == Group.id)\
                           .filter(Group.id.in_(user_groups))\
                           .filter(Expense.date >= thirty_days_ago.date())\
                           .order_by(Expense.date.desc())\
                           .limit(20)\
                           .all()
    
    # Converter para dicionário com informações extras
    expenses_data = []
    for expense in expenses:
        expense_dict = expense.to_dict()
        expense_dict['group_name'] = expense.group.name
        expense_dict['payer_name'] = expense.payer.name
        expenses_data.append(expense_dict)
    
    return jsonify({
        'expenses': expenses_data,
        'total_count': len(expenses_data)
    })

@expenses_bp.route('/recent', methods=['GET'])
@jwt_required()
def get_recent_expenses():
    """Obter despesas mais recentes do usuário"""
    user_id = get_jwt_identity()
    
    # Buscar grupos do usuário
    user_groups = db.session.query(GroupMember.group_id).filter_by(user_id=user_id).subquery()
    
    # Buscar as 10 despesas mais recentes
    expenses = Expense.query.join(Group, Expense.group_id == Group.id)\
                           .filter(Group.id.in_(user_groups))\
                           .order_by(Expense.date.desc(), Expense.created_at.desc())\
                           .limit(10)\
                           .all()
    
    # Converter para dicionário com informações extras
    expenses_data = []
    for expense in expenses:
        expense_dict = expense.to_dict()
        expense_dict['group_name'] = expense.group.name
        expense_dict['payer_name'] = expense.payer.name
        expenses_data.append(expense_dict)
    
    return jsonify(expenses_data)

@expenses_bp.route('/summary', methods=['GET'])
@jwt_required()
def get_expenses_summary():
    """Obter resumo das despesas do usuário"""
    user_id = get_jwt_identity()
    
    # Buscar grupos do usuário
    user_groups = db.session.query(GroupMember.group_id).filter_by(user_id=user_id).subquery()
    
    # Calcular totais
    current_month = datetime.now().replace(day=1).date()
    
    # Total gasto no mês atual
    monthly_expenses = Expense.query.join(Group, Expense.group_id == Group.id)\
                                   .filter(Group.id.in_(user_groups))\
                                   .filter(Expense.date >= current_month)\
                                   .all()
    
    total_monthly = sum(expense.amount for expense in monthly_expenses)
    
    # Total de despesas pagas pelo usuário
    user_paid_expenses = Expense.query.filter_by(payer_id=user_id)\
                                     .filter(Expense.date >= current_month)\
                                     .all()
    
    total_paid = sum(expense.amount for expense in user_paid_expenses)
    
    return jsonify({
        'monthly_total': float(total_monthly),
        'user_paid_total': float(total_paid),
        'monthly_count': len(monthly_expenses),
        'user_paid_count': len(user_paid_expenses)
    })