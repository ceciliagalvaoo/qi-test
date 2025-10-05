from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models.user import User
from app.models.receivable import Receivable
from app.models.debt import Debt

contacts_bp = Blueprint('contacts', __name__)

@contacts_bp.route('/', methods=['GET'])
@jwt_required()
def get_contacts():
    """Obter todos os contatos do usuário"""
    user_id = get_jwt_identity()
    
    # Para MVP, vamos considerar como contatos todos os usuários que têm dívidas com o usuário atual
    # ou estão no mesmo grupo
    
    # Buscar usuários que têm dívidas com o usuário atual (excluindo vendidas)
    debts_as_creditor = Debt.get_pending_debts(creditor_id=user_id).all()
    debts_as_debtor = Debt.get_pending_debts(debtor_id=user_id).all()
    
    contact_ids = set()
    for debt in debts_as_creditor:
        contact_ids.add(debt.debtor_id)
    for debt in debts_as_debtor:
        contact_ids.add(debt.creditor_id)
    
    # Buscar os usuários
    contacts = User.query.filter(User.id.in_(contact_ids)).all()
    
    # Para cada contato, buscar anúncios de recebíveis
    contacts_data = []
    for contact in contacts:
        contact_data = contact.to_dict()
        
        # Buscar recebíveis à venda deste contato
        receivables = Receivable.query.filter_by(
            owner_id=contact.id, 
            status='for_sale'
        ).all()
        
        contact_data['receivables_for_sale'] = [r.to_dict() for r in receivables]
        contacts_data.append(contact_data)
    
    return jsonify(contacts_data)

@contacts_bp.route('/all', methods=['GET'])
@jwt_required()
def get_all_users():
    """Obter todos os usuários (para adicionar em grupos)"""
    user_id = get_jwt_identity()
    
    # Buscar todos os usuários exceto o atual
    users = User.query.filter(User.id != user_id).all()
    
    return jsonify([user.to_dict() for user in users])

@contacts_bp.route('/<int:contact_id>/receivables', methods=['GET'])
@jwt_required()
def get_contact_receivables(contact_id):
    """Obter recebíveis de um contato específico"""
    # Buscar recebíveis à venda do contato
    receivables = Receivable.query.filter_by(
        owner_id=contact_id,
        status='for_sale'
    ).all()
    
    return jsonify([r.to_dict() for r in receivables])

@contacts_bp.route('/search', methods=['GET'])
@jwt_required()
def search_contacts():
    """Buscar contatos por nome ou email"""
    user_id = get_jwt_identity()
    query = request.args.get('q', '')
    
    if len(query) < 2:
        return jsonify({'error': 'Query deve ter pelo menos 2 caracteres'}), 400
    
    # Buscar usuários que correspondem à query
    users = User.query.filter(
        User.id != user_id,
        db.or_(
            User.name.ilike(f'%{query}%'),
            User.email.ilike(f'%{query}%')
        )
    ).limit(10).all()
    
    return jsonify([user.to_dict() for user in users])