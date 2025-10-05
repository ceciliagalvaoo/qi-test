from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from collections import defaultdict
from app import db
from app.models.user import User, GroupMember
from app.models.group import Group
from app.models.expense import Expense
from app.models.debt import Debt
from app.services.log_service import LogService
from datetime import datetime

groups_bp = Blueprint('groups', __name__)

@groups_bp.route('/', methods=['GET'])
@jwt_required()
def get_user_groups():
    """Obter grupos do usuário"""
    user_id = get_jwt_identity()
    
    # Buscar grupos onde o usuário é membro
    memberships = GroupMember.query.filter_by(user_id=user_id).all()
    groups = [Group.query.get(membership.group_id) for membership in memberships]
    
    return jsonify({
        "groups": [group.to_dict() for group in groups if group]
    })

@groups_bp.route('/', methods=['POST'])
@jwt_required()
def create_group():
    """Criar novo grupo"""
    user_id = get_jwt_identity()
    data = request.get_json()
    
    if 'name' not in data:
        return jsonify({'error': 'Nome do grupo é obrigatório'}), 400
    
    group = Group(
        name=data['name'],
        description=data.get('description', ''),
        created_by=user_id
    )
    
    db.session.add(group)
    db.session.commit()
    
    # Adicionar criador como membro
    group.add_member(user_id)
    
    return jsonify({
        'message': 'Grupo criado com sucesso',
        'group': group.to_dict()
    }), 201

@groups_bp.route('/<string:group_id>', methods=['GET'])
@jwt_required()
def get_group_detail(group_id):
    """Obter detalhes de um grupo"""
    user_id = get_jwt_identity()
    
    # Verificar se usuário é membro do grupo
    membership = GroupMember.query.filter_by(user_id=user_id, group_id=group_id).first()
    if not membership:
        return jsonify({'error': 'Acesso negado'}), 403
    
    group = Group.query.get(group_id)
    if not group:
        return jsonify({'error': 'Grupo não encontrado'}), 404
    
    # Buscar membros, despesas e dívidas
    members = group.get_members()
    
    # Buscar todas as despesas do grupo
    all_expenses = Expense.query.filter_by(group_id=group_id).all()
    
    # Buscar todas as despesas do grupo (agora que a despesa incorreta foi removida)
    expenses = all_expenses
    
    # Buscar dívidas das despesas filtradas (não vendidas como títulos)
    debts = []
    for expense in expenses:
        for debt in expense.debts:
            if debt.status == 'pending':
                debts.append(debt)
    
    # Buscar pagamentos via wallet relacionados ao grupo
    wallet_payments = []
    
    # 1. Pagamentos de despesas do grupo
    paid_debts = Debt.query.join(Expense).filter(
        Expense.group_id == group_id,
        Debt.status == 'paid'
    ).all()
    
    for debt in paid_debts:
        wallet_payments.append({
            'id': f'payment_{debt.id}',
            'type': 'wallet_payment',
            'description': f'{debt.debtor.name} pagou R$ {debt.amount:.2f} para {debt.creditor.name} via carteira',
            'amount': debt.amount,
            'payer_id': debt.debtor_id,
            'payer_name': debt.debtor.name,
            'creditor_id': debt.creditor_id,
            'creditor_name': debt.creditor.name,
            'paid_at': debt.paid_at.isoformat() if debt.paid_at else None,
            'original_expense_description': debt.expense.description if debt.expense else None,
            'debt_id': debt.id
        })
    
    # 2. Pagamentos virtuais entre membros do grupo
    # Buscar membros do grupo para filtrar pagamentos virtuais
    group_members = GroupMember.query.filter_by(group_id=group_id).all()
    member_ids = [m.user_id for m in group_members]
    
    virtual_payments = Debt.query.filter(
        Debt.source == 'virtual_payment',
        Debt.status == 'paid',
        Debt.debtor_id.in_(member_ids),
        Debt.creditor_id.in_(member_ids)
    ).all()
    
    for debt in virtual_payments:
        wallet_payments.append({
            'id': f'virtual_payment_{debt.id}',
            'type': 'virtual_wallet_payment',
            'description': f'{debt.debtor.name} pagou R$ {debt.amount:.2f} para {debt.creditor.name} via carteira (pagamento virtual)',
            'amount': debt.amount,
            'payer_id': debt.debtor_id,
            'payer_name': debt.debtor.name,
            'creditor_id': debt.creditor_id,
            'creditor_name': debt.creditor.name,
            'paid_at': debt.paid_at.isoformat() if debt.paid_at else None,
            'original_expense_description': 'Pagamento direto entre membros',
            'debt_id': debt.id
        })
    
    # Incluir dados do grupo no root para compatibilidade com Flutter
    group_dict = group.to_dict()
    
    return jsonify({
        # Dados do grupo no root
        'id': group_dict['id'],
        'name': group_dict['name'],
        'description': group_dict['description'],
        'created_by': group_dict['created_by'],
        'creator_name': group_dict['creator_name'],
        'created_at': group_dict['created_at'],
        'members_count': group_dict['members_count'],
        'expenses_count': group_dict['expenses_count'],
        'total_expenses': group_dict['total_expenses'],
        
        # Dados relacionados
        'group': group_dict,  # Manter para compatibilidade
        'members': [member.to_dict() for member in members],
        'expenses': [expense.to_dict() for expense in expenses],
        'debts': [debt.to_dict() for debt in debts],
        'wallet_payments': wallet_payments  # Pagamentos via carteira
    })

@groups_bp.route('/<string:group_id>/members', methods=['POST'])
@jwt_required()
def add_member_to_group(group_id):
    """Adicionar membro ao grupo"""
    user_id = get_jwt_identity()
    data = request.get_json()
    
    # Verificar se usuário é membro do grupo
    membership = GroupMember.query.filter_by(user_id=user_id, group_id=group_id).first()
    if not membership:
        return jsonify({'error': 'Acesso negado'}), 403
    
    group = Group.query.get(group_id)
    if not group:
        return jsonify({'error': 'Grupo não encontrado'}), 404
    
    # Buscar usuário por email
    if 'email' not in data:
        return jsonify({'error': 'Email do usuário é obrigatório'}), 400
    
    new_member = User.query.filter_by(email=data['email']).first()
    if not new_member:
        return jsonify({'error': 'Usuário não encontrado'}), 404
    
    # Adicionar ao grupo
    if group.add_member(new_member.id):
        return jsonify({
            'message': f'{new_member.name} adicionado ao grupo',
            'member': new_member.to_dict()
        })
    else:
        return jsonify({'error': 'Usuário já é membro do grupo'}), 400

@groups_bp.route('/<string:group_id>/expenses', methods=['POST'])
@jwt_required()
def add_expense(group_id):
    """Adicionar despesa ao grupo"""
    user_id = get_jwt_identity()
    data = request.get_json()
    
    # Verificar se usuário é membro do grupo
    membership = GroupMember.query.filter_by(user_id=user_id, group_id=group_id).first()
    if not membership:
        return jsonify({'error': 'Acesso negado'}), 403
    
    # Validar dados
    required_fields = ['description', 'amount']
    for field in required_fields:
        if field not in data:
            return jsonify({'error': f'{field} é obrigatório'}), 400
    
    # Criar despesa
    expense = Expense(
        group_id=group_id,
        payer_id=user_id,
        description=data['description'],
        amount=float(data['amount']),
        date=datetime.strptime(data.get('date', datetime.now().strftime('%Y-%m-%d')), '%Y-%m-%d').date()
    )
    
    db.session.add(expense)
    db.session.commit()
    
    # Dividir despesa automaticamente
    expense.split_expense(data.get('member_ids'))
    
    # Executar otimização automática
    LogService.optimize_debts()
    
    return jsonify({
        'message': 'Despesa adicionada com sucesso',
        'expense': expense.to_dict()
    }), 201

@groups_bp.route('/<string:group_id>/expenses/<string:expense_id>', methods=['DELETE'])
@jwt_required()
def delete_expense(group_id, expense_id):
    """Deletar despesa"""
    user_id = get_jwt_identity()
    
    expense = Expense.query.get(expense_id)
    if not expense or expense.group_id != group_id:
        return jsonify({'error': 'Despesa não encontrada'}), 404
    
    # Só o pagador pode deletar
    if expense.payer_id != user_id:
        return jsonify({'error': 'Apenas quem pagou pode deletar a despesa'}), 403
    
    # Cancelar todas as dívidas relacionadas
    for debt in expense.debts:
        debt.cancel()
    
    db.session.delete(expense)
    db.session.commit()
    
    return jsonify({'message': 'Despesa removida com sucesso'})


@groups_bp.route('/<group_id>/optimize', methods=['POST'])
@jwt_required()
def optimize_group_debts(group_id):
    """Otimiza manualmente as dívidas de um grupo específico"""
    user_id = get_jwt_identity()
    
    # Verificar se o usuário é membro do grupo
    membership = GroupMember.query.filter_by(
        user_id=user_id,
        group_id=group_id
    ).first()
    
    if not membership:
        return jsonify({'error': 'Usuário não é membro do grupo'}), 403
    
    # Calcular saldos antes da otimização
    balances_before = _calculate_group_balances(group_id)
    
    # Executar otimização
    optimized_count = LogService.optimize_debts()
    
    # Calcular saldos após otimização
    balances_after = _calculate_group_balances(group_id)
    
    # Preparar resumo dos saldos finais
    balance_summary = []
    for user_id, balance in balances_after.items():
        if abs(balance) > 0.01:  # Apenas mostrar se tiver saldo significativo
            user = User.query.get(user_id)
            if balance > 0:
                balance_summary.append({
                    'user': user.name,
                    'type': 'recebe',
                    'amount': abs(balance)
                })
            else:
                balance_summary.append({
                    'user': user.name,
                    'type': 'paga',
                    'amount': abs(balance)
                })
    
    message = f'Otimização concluída! {optimized_count} dívidas foram otimizadas.'
    if not balance_summary:
        message += ' Todos os saldos estão zerados! 🎉'
    
    return jsonify({
        'message': message,
        'optimized_count': optimized_count,
        'balance_summary': balance_summary
    })


def calculate_user_net_balance(user_id):
    """Calcula o saldo líquido real do usuário em todos os grupos"""
    from app.models.expense import Expense
    from app.models.user import GroupMember
    
    # Buscar todos os grupos do usuário
    user_groups = GroupMember.query.filter_by(user_id=user_id).all()
    
    total_net_balance = 0.0
    
    for membership in user_groups:
        group_id = membership.group_id
        
        # Calcular saldo neste grupo específico
        group_balances = _calculate_group_balances(group_id)
        user_balance = group_balances.get(user_id, 0.0)
        total_net_balance += user_balance
    
    return total_net_balance


def _calculate_group_balances(group_id):
    """Calcula o saldo líquido de cada membro do grupo baseado no que pagaram vs o que deveriam pagar"""
    from app.models.expense import Expense
    from app.models.user import GroupMember
    
    # Buscar todas as despesas do grupo
    expenses = Expense.query.filter_by(group_id=group_id).all()
    
    # Calcular quanto cada pessoa pagou
    paid_by_user = defaultdict(float)
    for expense in expenses:
        paid_by_user[expense.payer_id] += expense.amount
    
    # Calcular total de despesas
    total_expenses = sum(expense.amount for expense in expenses)
    
    # Buscar membros do grupo
    members = GroupMember.query.filter_by(group_id=group_id).all()
    member_count = len(members)
    
    if member_count == 0:
        return {}
    
    # Calcular quanto cada pessoa deveria pagar (divisão igual)
    should_pay_per_person = total_expenses / member_count
    
    # Calcular saldo líquido: quanto pagou - quanto deveria pagar
    balances = {}
    for member in members:
        paid = paid_by_user.get(member.user_id, 0.0)
        should_pay = should_pay_per_person
        balance = paid - should_pay  # Positivo = recebe, Negativo = paga
        balances[member.user_id] = balance
    
    # CORREÇÃO: Ajustar saldos considerando pagamentos via wallet
    # 1. Buscar pagamentos via wallet dentro deste grupo (dívidas de despesas do grupo)
    paid_debts = Debt.query.join(Expense).filter(
        Expense.group_id == group_id,
        Debt.status == 'paid'
    ).all()
    
    print(f"[DEBUG] Grupo {group_id}: Encontrados {len(paid_debts)} pagamentos de despesas via wallet")
    
    for debt in paid_debts:
        debtor_id = debt.debtor_id
        creditor_id = debt.creditor_id
        amount = debt.amount
        
        print(f"[DEBUG] Pagamento de despesa: {debtor_id} pagou {amount} para {creditor_id}")
        
        if debtor_id in balances:
            balances[debtor_id] += amount
        if creditor_id in balances:
            balances[creditor_id] -= amount
    
    # 2. Buscar pagamentos virtuais (source='virtual_payment')
    # Estes são pagamentos diretos entre membros do grupo
    virtual_payments = Debt.query.filter(
        Debt.source == 'virtual_payment',
        Debt.status == 'paid',
        # Verificar se ambos os usuários são membros do grupo
        Debt.debtor_id.in_([m.user_id for m in members]),
        Debt.creditor_id.in_([m.user_id for m in members])
    ).all()
    
    print(f"[DEBUG] Grupo {group_id}: Encontrados {len(virtual_payments)} pagamentos virtuais")
    
    for payment in virtual_payments:
        debtor_id = payment.debtor_id
        creditor_id = payment.creditor_id
        amount = payment.amount
        
        print(f"[DEBUG] Pagamento virtual: {debtor_id} pagou {amount} para {creditor_id}")
        
        if debtor_id in balances:
            balances[debtor_id] += amount  # Quem pagou melhora
            print(f"[DEBUG] Novo saldo de {debtor_id}: {balances[debtor_id]}")
        if creditor_id in balances:
            balances[creditor_id] -= amount  # Quem recebeu piora
            print(f"[DEBUG] Novo saldo de {creditor_id}: {balances[creditor_id]}")
    
    # 3. CORREÇÃO: Descontar dívidas que foram vendidas como títulos
    # Quando alguém vende uma dívida, ela não tem mais direito a receber do devedor
    sold_debts = Debt.query.join(Expense).filter(
        Expense.group_id == group_id,
        Debt.status == 'sold_as_title'
    ).all()
    
    print(f"[DEBUG] Grupo {group_id}: Encontradas {len(sold_debts)} dívidas vendidas como títulos")
    
    for debt in sold_debts:
        debtor_id = debt.debtor_id
        creditor_id = debt.creditor_id  # Quem VENDEU a dívida
        amount = debt.amount
        
        print(f"[DEBUG] Dívida vendida: {creditor_id} vendeu dívida de {amount} do {debtor_id}")
        
        # Quem vendeu a dívida não tem mais direito a receber
        if creditor_id in balances:
            balances[creditor_id] -= amount  # Reduz o que tem a receber
            print(f"[DEBUG] Saldo ajustado de {creditor_id}: {balances[creditor_id]} (descontou R$ {amount} vendido)")
        
        # Quem devia não deve mais para o vendedor original
        if debtor_id in balances:
            balances[debtor_id] += amount  # Reduz o que deve pagar
            print(f"[DEBUG] Saldo ajustado de {debtor_id}: {balances[debtor_id]} (não deve mais R$ {amount} para vendedor)")
    
    return balances