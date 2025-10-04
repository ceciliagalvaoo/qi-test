from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
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
    
    return jsonify([group.to_dict() for group in groups if group])

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

@groups_bp.route('/<int:group_id>', methods=['GET'])
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
    expenses = Expense.query.filter_by(group_id=group_id).all()
    
    # Buscar dívidas do grupo
    debts = []
    for expense in expenses:
        debts.extend(expense.debts)
    
    return jsonify({
        'group': group.to_dict(),
        'members': [member.to_dict() for member in members],
        'expenses': [expense.to_dict() for expense in expenses],
        'debts': [debt.to_dict() for debt in debts if debt.status == 'pending']
    })

@groups_bp.route('/<int:group_id>/members', methods=['POST'])
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

@groups_bp.route('/<int:group_id>/expenses', methods=['POST'])
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

@groups_bp.route('/<int:group_id>/expenses/<int:expense_id>', methods=['DELETE'])
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