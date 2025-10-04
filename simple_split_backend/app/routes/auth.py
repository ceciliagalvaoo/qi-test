from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from app import db
from app.models.user import User
from app.models.wallet import Wallet

auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/health', methods=['GET'])
def health():
    """Endpoint de teste para verificar se a API está funcionando"""
    return jsonify({'status': 'OK', 'message': 'Auth API funcionando!'})

@auth_bp.route('/register', methods=['POST'])
def register():
    """Registrar novo usuário"""
    data = request.get_json()
    
    # Validar dados obrigatórios
    required_fields = ['name', 'email', 'password']
    for field in required_fields:
        if field not in data:
            return jsonify({'error': f'{field} é obrigatório'}), 400
    
    # Verificar se email já existe
    if User.query.filter_by(email=data['email']).first():
        return jsonify({'error': 'Email já cadastrado'}), 400
    
    # Criar usuário
    user = User(
        name=data['name'],
        email=data['email'],
        phone=data.get('phone')
    )
    user.set_password(data['password'])
    
    db.session.add(user)
    db.session.commit()
    
    # Criar carteira para o usuário
    wallet = Wallet(user_id=user.id)
    db.session.add(wallet)
    db.session.commit()
    
    # Criar token de acesso
    access_token = create_access_token(identity=user.id)
    
    return jsonify({
        'message': 'Usuário criado com sucesso',
        'user': user.to_dict(),
        'access_token': access_token
    }), 201

@auth_bp.route('/login', methods=['POST'])
def login():
    """Fazer login"""
    data = request.get_json()
    
    if 'email' not in data or 'password' not in data:
        return jsonify({'error': 'Email e senha são obrigatórios'}), 400
    
    user = User.query.filter_by(email=data['email']).first()
    
    if user and user.check_password(data['password']):
        access_token = create_access_token(identity=user.id)
        return jsonify({
            'message': 'Login realizado com sucesso',
            'user': user.to_dict(),
            'access_token': access_token
        })
    
    return jsonify({'error': 'Email ou senha incorretos'}), 401

@auth_bp.route('/verify-2fa', methods=['POST'])
def verify_2fa():
    """Verificar código 2FA (simulado para MVP)"""
    data = request.get_json()
    
    if 'code' not in data:
        return jsonify({'error': 'Código é obrigatório'}), 400
    
    # Para MVP, aceitar código "123456"
    if data['code'] == '123456':
        return jsonify({'message': '2FA verificado com sucesso'})
    
    return jsonify({'error': 'Código inválido'}), 400

@auth_bp.route('/profile', methods=['GET'])
@jwt_required()
def get_profile():
    """Obter perfil do usuário logado"""
    print(f"[DEBUG] Acessando /api/auth/profile")
    user_id = get_jwt_identity()
    print(f"[DEBUG] User ID do token: {user_id}")
    user = User.query.get(user_id)
    print(f"[DEBUG] Usuário encontrado: {user.name if user else 'Não encontrado'}")
    
    if not user:
        return jsonify({'error': 'Usuário não encontrado'}), 404
    
    return jsonify({'user': user.to_dict()})

@auth_bp.route('/profile', methods=['PUT'])
@jwt_required()
def update_profile():
    """Atualizar perfil do usuário"""
    user_id = get_jwt_identity()
    user = User.query.get(user_id)
    
    if not user:
        return jsonify({'error': 'Usuário não encontrado'}), 404
    
    data = request.get_json()
    
    # Atualizar campos permitidos
    if 'name' in data:
        user.name = data['name']
    if 'phone' in data:
        user.phone = data['phone']
    
    db.session.commit()
    
    return jsonify({
        'message': 'Perfil atualizado com sucesso',
        'user': user.to_dict()
    })