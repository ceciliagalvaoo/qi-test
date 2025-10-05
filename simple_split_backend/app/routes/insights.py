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
    
    # Insight 1: Próximos pagamentos (dívidas que o usuário deve, excluindo vendidas)
    debts_to_pay = Debt.get_pending_debts(debtor_id=user_id).join(Expense).all()
    
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
    
    # Insight 2: Dívidas a receber (consolidadas por devedor)
    debts_to_receive = Debt.get_pending_debts(creditor_id=user_id).join(Expense).all()
    
    # Consolidar dívidas por devedor
    from collections import defaultdict
    debts_by_debtor = defaultdict(list)
    for debt in debts_to_receive:
        debts_by_debtor[debt.debtor_id].append(debt)
    
    for debtor_id, debts in list(debts_by_debtor.items())[:3]:  # Máximo 3 devedores
        total_amount = sum(debt.amount for debt in debts)
        debtor_name = debts[0].debtor.name
        
        # Verificar origem das dívidas
        from app.models.receivable import Receivable
        purchased_debts = []
        group_debts = []
        
        for debt in debts:
            # Verificar se há título comprado deste devedor
            related_receivable = Receivable.query.filter_by(
                consolidated_group_id=debt.debtor_id,
                buyer_id=user_id,
                status='sold'
            ).first()
            
            if related_receivable:
                # Se o valor da dívida exatamente igual ao do título, é dívida de título
                if abs(debt.amount - related_receivable.nominal_amount) < 0.01:
                    purchased_debts.append(debt.amount)
                else:
                    # Caso contrário, é dívida de grupo
                    group_debts.append(debt.amount)
            else:
                # Sem título relacionado = dívida de grupo
                group_debts.append(debt.amount)
        
        # Criar descrição com origem
        if purchased_debts and group_debts:
            description = f'{debtor_name} deve R${total_amount:.2f} (Grupo: R${sum(group_debts):.2f} + Títulos: R${sum(purchased_debts):.2f})'
        elif purchased_debts:
            description = f'{debtor_name} deve R${total_amount:.2f} (via título comprado)'
        else:
            description = f'{debtor_name} deve R${total_amount:.2f} (dívida de grupo)'
        
        insights.append({
            'type': 'incoming_payment',
            'title': 'A Receber',
            'description': description,
            'details': {
                'amount': total_amount,
                'debtor': debtor_name,
                'debt_count': len(debts),
                'group_amount': sum(group_debts),
                'purchased_amount': sum(purchased_debts),
                'debt_ids': [debt.id for debt in debts]
            },
            'priority': 'low'
        })
    
    # Insight 3: Logs recentes (apenas o mais recente de cada tipo)
    recent_optimization = Log.query.filter_by(type='optimization')\
        .order_by(Log.created_at.desc()).first()
    
    if recent_optimization:
        insights.append({
            'type': 'optimization',
            'title': 'Última Otimização',
            'description': f'Última otimização economizou R${recent_optimization.amount:.2f}',
            'details': {
                'amount_optimized': recent_optimization.amount,
                'created_at': recent_optimization.created_at.isoformat()
            },
            'priority': 'info'
        })
    
    # Log de pagamentos recentes do usuário
    recent_payment = Log.query.filter_by(user_id=user_id, type='payment')\
        .order_by(Log.created_at.desc()).first()
        
    if recent_payment:
        insights.append({
            'type': 'payment_completed',
            'title': 'Último Pagamento',
            'description': recent_payment.description,
            'details': {
                'amount': recent_payment.amount,
                'created_at': recent_payment.created_at.isoformat()
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
        # Total das despesas que o usuário pagou nos últimos 30 dias
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
    
    # Usar lógica otimizada (mesma do /user/profile e grupos)
    from app.routes.groups import calculate_user_net_balance
    from app.models.user import GroupMember
    
    # Calcular valores otimizados baseados nos saldos dos grupos
    user_groups = GroupMember.query.filter_by(user_id=user_id).all()
    
    optimized_total_to_pay = 0.0
    optimized_total_to_receive = 0.0
    
    for membership in user_groups:
        group_id = membership.group_id
        
        # Usar a função _calculate_group_balances
        from app.routes.groups import _calculate_group_balances
        group_balances = _calculate_group_balances(group_id)
        
        user_balance = group_balances.get(user_id, 0.0)
        
        if user_balance < 0:  # Usuário deve (saldo negativo)
            optimized_total_to_pay += abs(user_balance)
        elif user_balance > 0:  # Usuário deve receber (saldo positivo)
            optimized_total_to_receive += user_balance
    
    # Adicionar dívidas de títulos comprados (não são otimizadas)
    purchased_debts = Debt.query.filter_by(
        creditor_id=user_id,
        status='pending',
        source='purchased_title'
    ).all()
    
    for debt in purchased_debts:
        optimized_total_to_receive += debt.amount
    
    # Calcular totais usando a mesma lógica detalhada da API /insights/debts-categorized
    you_owe_total = 0.0
    others_owe_total = 0.0
    
    for membership in user_groups:
        group_id = membership.group_id
        group_balances = _calculate_group_balances(group_id)
        user_balance = group_balances.get(user_id, 0.0)
        
        if abs(user_balance) > 0.01:
            if user_balance < 0:  # Usuário deve (saldo negativo)
                for other_user_id, other_balance in group_balances.items():
                    if other_user_id != user_id and other_balance > 0.01:
                        total_positive = sum(balance for balance in group_balances.values() if balance > 0)
                        if total_positive > 0:
                            proportion = other_balance / total_positive
                            amount_owed = abs(user_balance) * proportion
                            
                            if amount_owed > 0.01:
                                # Verificar se há dívidas pagas individualmente que devem reduzir o saldo
                                paid_debts = Debt.query.filter_by(
                                    debtor_id=user_id,
                                    creditor_id=other_user_id,
                                    status='paid'
                                ).all()
                                
                                paid_amount = sum(d.amount for d in paid_debts)
                                amount_owed = max(0, amount_owed - paid_amount)
                                
                                you_owe_total += amount_owed
                                
            elif user_balance > 0:  # Usuário deve receber (saldo positivo)
                others_owe_total += user_balance
    
    # Adicionar dívidas de títulos comprados
    for debt in purchased_debts:
        others_owe_total += debt.amount
    
    total_to_pay = you_owe_total
    total_to_receive = others_owe_total
    
    print(f"[DEBUG] Summary totais corrigidos - A pagar: R$ {total_to_pay}, A receber: R$ {total_to_receive}")
    
    # Total gasto: soma da parte do usuário nas despesas (tanto como pagador quanto devedor)
    from app.models.expense import Expense
    # Total gasto (parte real do usuário nas despesas)
    # 1. Parte das despesas que ele pagou (valor dividido pelo número de pessoas)
    expenses_paid = Expense.query.filter_by(payer_id=user_id).all()
    spent_as_payer = 0
    for expense in expenses_paid:
        # Conta quantas pessoas participaram (pagador + devedores)
        debt_count = len(expense.debts)
        total_people = debt_count + 1  # +1 para o pagador
        spent_as_payer += expense.amount / total_people
    
    # 2. Parte das despesas que ele deve (já paga ou pendente)
    spent_as_debtor = db.session.query(db.func.sum(Debt.amount))\
        .filter_by(debtor_id=user_id).scalar() or 0
    
    total_spent = spent_as_payer + spent_as_debtor
    
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
        'total_spent': total_spent,
        'net_balance': total_to_receive - total_to_pay,
        'active_groups': active_groups,
        'score': user.score
    })

@insights_bp.route('/debts-categorized', methods=['GET'])
@jwt_required()
def get_debts_categorized():
    """Obter dívidas categorizadas usando saldos otimizados dos grupos (mesma lógica do OTIMIZAR)"""
    user_id = get_jwt_identity()
    
    # Importar função de cálculo de saldos dos grupos
    from app.routes.groups import calculate_user_net_balance
    from app.models.user import GroupMember, User
    from collections import defaultdict
    
    # Calcular saldo líquido total do usuário usando a mesma lógica dos grupos
    total_net_balance = calculate_user_net_balance(user_id)
    
    # Ajustar o saldo considerando pagamentos individuais feitos
    individual_payments = Debt.query.filter_by(
        debtor_id=user_id,
        status='paid'
    ).all()
    
    total_paid_individually = sum(debt.amount for debt in individual_payments)
    print(f"[DEBUG] Usuário {user_id} pagou individualmente: R$ {total_paid_individually}")
    
    # Ajustar o saldo líquido
    total_net_balance += total_paid_individually  # Se pagou individualmente, melhora o saldo
    
    # Buscar todos os grupos do usuário para calcular saldos individuais
    user_groups = GroupMember.query.filter_by(user_id=user_id).all()
    
    you_owe_list = []
    others_owe_list = []
    
    for membership in user_groups:
        group_id = membership.group_id
        
        # Usar a função _calculate_group_balances importada
        from app.routes.groups import _calculate_group_balances
        group_balances = _calculate_group_balances(group_id)
        
        user_balance = group_balances.get(user_id, 0.0)
        print(f"[DEBUG] Insights - Grupo {group_id}: saldo do usuário = {user_balance}")
        
        if abs(user_balance) > 0.01:  # Apenas se tiver saldo significativo
            if user_balance < 0:  # Usuário deve (saldo negativo)
                # Encontrar quem deve receber no grupo
                for other_user_id, other_balance in group_balances.items():
                    if other_user_id != user_id and other_balance > 0.01:
                        # Calcular quanto este usuário deve para este outro usuário
                        # Proporcionalmente ao quanto cada um deve receber
                        
                        total_positive = sum(balance for balance in group_balances.values() if balance > 0)
                        if total_positive > 0:
                            proportion = other_balance / total_positive
                            amount_owed = abs(user_balance) * proportion
                            
                            print(f"[DEBUG] Usuário deve para {other_user_id}: total_positive={total_positive}, proportion={proportion}, amount_owed={amount_owed}")
                            
                            if amount_owed > 0.01:  # Apenas valores significativos
                                other_user = User.query.get(other_user_id)
                                
                                # Verificar se já existe entrada para este credor
                                existing = None
                                for item in you_owe_list:
                                    if item['creditor_id'] == other_user_id:
                                        existing = item
                                        break
                                
                                if existing:
                                    existing['amount'] += amount_owed
                                    existing['amount'] = round(existing['amount'], 2)
                                else:
                                    # Buscar uma dívida individual real para este credor para ter um debt_id (excluindo vendidas)
                                    sample_debt = Debt.get_pending_debts(
                                        debtor_id=user_id,
                                        creditor_id=other_user_id
                                    ).first()
                                    
                                    # Verificar se há dívidas pagas individualmente que devem reduzir o saldo
                                    paid_debts = Debt.query.filter_by(
                                        debtor_id=user_id,
                                        creditor_id=other_user_id,
                                        status='paid'
                                    ).all()
                                    
                                    paid_amount = sum(d.amount for d in paid_debts)
                                    amount_owed = max(0, amount_owed - paid_amount)
                                    
                                    print(f"[DEBUG] Após descontar pagamentos: paid_amount={paid_amount}, amount_owed_final={amount_owed}")
                                    
                                    # Só incluir se ainda deve alguma coisa
                                    if amount_owed > 0.01:
                                        you_owe_list.append({
                                            'id': sample_debt.id if sample_debt else f'virtual_{user_id}_{other_user_id}',
                                            'creditor_id': other_user_id,
                                            'creditor_name': other_user.name,
                                            'amount': round(amount_owed, 2),
                                            'source': 'group_debt'
                                        })
                            
            elif user_balance > 0:  # Usuário deve receber (saldo positivo)
                # Encontrar quem deve no grupo
                for other_user_id, other_balance in group_balances.items():
                    if other_user_id != user_id and other_balance < -0.01:
                        # Calcular quanto este outro usuário deve para o usuário atual
                        
                        total_negative = sum(abs(balance) for balance in group_balances.values() if balance < 0)
                        if total_negative > 0:
                            proportion = abs(other_balance) / total_negative
                            amount_to_receive = user_balance * proportion
                            
                            if amount_to_receive > 0.01:  # Apenas valores significativos
                                other_user = User.query.get(other_user_id)
                                
                                # Verificar se já existe entrada para este devedor
                                existing = None
                                for item in others_owe_list:
                                    if item['debtor_id'] == other_user_id:
                                        existing = item
                                        break
                                
                                if existing:
                                    existing['amount'] += amount_to_receive
                                    existing['amount'] = round(existing['amount'], 2)
                                else:
                                    others_owe_list.append({
                                        'debtor_id': other_user_id,
                                        'debtor_name': other_user.name,
                                        'amount': round(amount_to_receive, 2),
                                        'source': 'group_debt'
                                    })
    
    # Adicionar dívidas de títulos comprados (purchased_title)
    purchased_debts = Debt.query.filter_by(
        creditor_id=user_id,
        status='pending',
        source='purchased_title'
    ).all()
    
    for debt in purchased_debts:
        # Verificar se já existe entrada para este devedor
        existing = None
        for item in others_owe_list:
            if item['debtor_id'] == debt.debtor_id:
                existing = item
                break
        
        if existing:
            existing['amount'] += debt.amount
            existing['amount'] = round(existing['amount'], 2)
            existing['source'] = 'mixed'  # Mistura de group_debt e purchased_title
        else:
            others_owe_list.append({
                'debtor_id': debt.debtor_id,
                'debtor_name': debt.debtor.name,
                'amount': round(debt.amount, 2),
                'source': 'purchased_title'
            })
    
    # Calcular totais ajustados
    total_you_owe = sum(item['amount'] for item in you_owe_list)
    total_others_owe = sum(item['amount'] for item in others_owe_list)
    adjusted_net_balance = total_others_owe - total_you_owe
    
    print(f"[DEBUG] Totais ajustados - Você deve: R$ {total_you_owe}, Outros devem: R$ {total_others_owe}")
    
    return jsonify({
        'you_owe': you_owe_list,
        'others_owe_you': others_owe_list,
        'net_balance': round(adjusted_net_balance, 2),
        'total_you_owe': round(total_you_owe, 2),
        'total_others_owe': round(total_others_owe, 2)
    })