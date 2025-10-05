from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models.user import User
from app.models.debt import Debt
from app.models.log import Log
from app.models.expense import Expense
from app.models.group import Group
from datetime import datetime, timedelta

insights_bp = Blueprint('insights', __name__)

@insights_bp.route('/', methods=['GET'])
@jwt_required()
def get_insights():
    """Obter insights automáticos para o usuário"""
    user_id = get_jwt_identity()
    insights = []
    
    # Insight 1: Próximos pagamentos (dívidas que o usuário deve)
    debts_to_pay = Debt.query.filter_by(
        debtor_id=user_id,
        status='pending'
    ).join(Expense).all()
    
    for debt in debts_to_pay[:3]:  # Mostrar apenas as 3 primeiras
        due_date = debt.due_date or (datetime.now().date() + timedelta(days=7))
        insights.append({
            'type': 'payment_reminder',
            'title': 'Pagamento Pendente',
            'description': f'Você deve R${debt.amount:.2f} para {debt.creditor.name}',
            'details': {
                'amount': debt.amount,
                'creditor': debt.creditor.name,
                'due_date': due_date.isoformat(),
                'expense_description': debt.expense.description if debt.expense else None,
                'debt_id': debt.id
            },
            'priority': 'high' if due_date <= datetime.now().date() else 'medium'
        })
    
    # Insight 2: Dívidas a receber
    debts_to_receive = Debt.query.filter_by(
        creditor_id=user_id,
        status='pending'
    ).join(Expense).all()
    
    for debt in debts_to_receive[:3]:
        insights.append({
            'type': 'incoming_payment',
            'title': 'A Receber',
            'description': f'{debt.debtor.name} deve R${debt.amount:.2f} para você',
            'details': {
                'amount': debt.amount,
                'debtor': debt.debtor.name,
                'expense_description': debt.expense.description if debt.expense else None,
                'debt_id': debt.id
            },
            'priority': 'low'
        })
    
    # Insight 3: Logs recentes (otimizações, pagamentos)
    recent_logs = Log.query.filter(
        db.or_(
            Log.user_id == user_id,
            Log.type == 'optimization'
        )
    ).order_by(Log.created_at.desc()).limit(3).all()
    
    for log in recent_logs:
        if log.type == 'optimization':
            insights.append({
                'type': 'optimization',
                'title': 'Dívidas Otimizadas',
                'description': log.description,
                'details': {
                    'amount_optimized': log.amount,
                    'created_at': log.created_at.isoformat()
                },
                'priority': 'info'
            })
        elif log.type == 'payment':
            insights.append({
                'type': 'payment_completed',
                'title': 'Pagamento Realizado',
                'description': log.description,
                'details': {
                    'amount': log.amount,
                    'created_at': log.created_at.isoformat()
                },
                'priority': 'info'
            })
    
    # Insight 4: Score do usuário
    user = User.query.get(user_id)
    if user.score < 7.0:
        insights.append({
            'type': 'score_warning',
            'title': 'Score Baixo',
            'description': f'Seu score atual é {user.score:.1f}. Pague suas dívidas em dia para melhorar!',
            'details': {
                'current_score': user.score,
                'max_score': 10.0
            },
            'priority': 'high'
        })
    elif user.score >= 9.0:
        insights.append({
            'type': 'score_good',
            'title': 'Excelente Score!',
            'description': f'Parabéns! Seu score é {user.score:.1f}',
            'details': {
                'current_score': user.score,
                'max_score': 10.0
            },
            'priority': 'info'
        })
    
    # Insight 5: Resumo de gastos recentes por grupo
    recent_expenses = Expense.query.filter_by(payer_id=user_id)\
        .filter(Expense.created_at >= datetime.now() - timedelta(days=30))\
        .join(Group).all()
    
    if recent_expenses:
        total_spent = sum([expense.amount for expense in recent_expenses])
        insights.append({
            'type': 'spending_summary',
            'title': 'Gastos dos Últimos 30 Dias',
            'description': f'Você gastou R${total_spent:.2f} em {len(recent_expenses)} despesas',
            'details': {
                'total_amount': total_spent,
                'expense_count': len(recent_expenses),
                'period': '30 dias'
            },
            'priority': 'info'
        })
    
    # Ordenar por prioridade
    priority_order = {'high': 0, 'medium': 1, 'low': 2, 'info': 3}
    insights.sort(key=lambda x: priority_order.get(x['priority'], 3))
    
    return jsonify(insights)

@insights_bp.route('/summary', methods=['GET'])
@jwt_required()
def get_summary():
    """Obter resumo financeiro do usuário"""
    user_id = get_jwt_identity()
    
    # Total a pagar
    total_to_pay = db.session.query(db.func.sum(Debt.amount))\
        .filter_by(debtor_id=user_id, status='pending').scalar() or 0
    
    # Total a receber
    total_to_receive = db.session.query(db.func.sum(Debt.amount))\
        .filter_by(creditor_id=user_id, status='pending').scalar() or 0
    
    # Saldo da carteira
    user = User.query.get(user_id)
    wallet_balance = user.wallet.balance if user.wallet else 0
    
    # Número de grupos ativos
    from app.models.user import GroupMember
    active_groups = GroupMember.query.filter_by(user_id=user_id).count()
    
    return jsonify({
        'wallet_balance': wallet_balance,
        'total_to_pay': total_to_pay,
        'total_to_receive': total_to_receive,
        'net_balance': total_to_receive - total_to_pay,
        'active_groups': active_groups,
        'score': user.score
    })