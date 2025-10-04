from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models.user import User
from app.models.wallet import Wallet, Transaction
from app.models.debt import Debt
from app.models.receivable import Receivable

user_bp = Blueprint('user', __name__)

@user_bp.route('/profile', methods=['GET'])
@jwt_required()
def get_user_profile():
    """Obter perfil completo do usuário"""
    print(f"[DEBUG] Acessando /api/user/profile")
    user_id = get_jwt_identity()
    print(f"[DEBUG] User ID do token: {user_id}")
    user = User.query.get(user_id)
    print(f"[DEBUG] Usuário encontrado: {user.name if user else 'Não encontrado'}")
    
    if not user:
        return jsonify({'error': 'Usuário não encontrado'}), 404
    
    # Buscar carteira
    wallet = Wallet.query.filter_by(user_id=user_id).first()
    
    # Buscar dívidas a pagar
    debts_to_pay = Debt.query.filter_by(debtor_id=user_id, status='pending').all()
    
    # Buscar dívidas a receber (incluindo títulos comprados)
    debts_to_receive = Debt.query.filter_by(creditor_id=user_id, status='pending').all()
    
    # Buscar títulos de recebíveis comprados
    bought_receivables = Receivable.query.filter_by(buyer_id=user_id, status='sold').all()
    
    return jsonify({
        'user': user.to_dict(),
        'wallet': wallet.to_dict() if wallet else {'balance': 0},
        'debts_to_pay': [debt.to_dict() for debt in debts_to_pay],
        'debts_to_receive': [debt.to_dict() for debt in debts_to_receive],
        'bought_receivables': [r.to_dict() for r in bought_receivables],
        'score_info': {
            'current_score': user.score,
            'max_score': 10.0,
            'description': get_score_description(user.score)
        }
    })

@user_bp.route('/profile', methods=['PUT'])
@jwt_required()
def update_user_profile():
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

@user_bp.route('/wallet/add-funds', methods=['POST'])
@jwt_required()
def add_funds():
    """Adicionar saldo à carteira"""
    user_id = get_jwt_identity()
    data = request.get_json()
    
    if 'amount' not in data:
        return jsonify({'error': 'Valor é obrigatório'}), 400
    
    amount = float(data['amount'])
    if amount <= 0:
        return jsonify({'error': 'Valor deve ser positivo'}), 400
    
    wallet = Wallet.query.filter_by(user_id=user_id).first()
    if not wallet:
        # Criar carteira se não existir
        wallet = Wallet(user_id=user_id)
        db.session.add(wallet)
        db.session.commit()
    
    # Adicionar fundos
    wallet.add_funds(amount, data.get('description', 'Adição de saldo'))
    
    return jsonify({
        'message': f'R${amount:.2f} adicionado à carteira',
        'new_balance': wallet.balance
    })

@user_bp.route('/wallet/transactions', methods=['GET'])
@jwt_required()
def get_transactions():
    """Obter histórico de transações da carteira"""
    user_id = get_jwt_identity()
    
    wallet = Wallet.query.filter_by(user_id=user_id).first()
    if not wallet:
        return jsonify([])
    
    # Buscar transações com paginação
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 20, type=int)
    
    transactions = Transaction.query.filter_by(wallet_id=wallet.id)\
        .order_by(Transaction.created_at.desc())\
        .paginate(page=page, per_page=per_page, error_out=False)
    
    return jsonify({
        'transactions': [t.to_dict() for t in transactions.items],
        'total': transactions.total,
        'pages': transactions.pages,
        'current_page': page
    })

@user_bp.route('/pay-debt/<int:debt_id>', methods=['POST'])
@jwt_required()
def pay_debt(debt_id):
    """Pagar uma dívida"""
    user_id = get_jwt_identity()
    
    debt = Debt.query.get(debt_id)
    if not debt:
        return jsonify({'error': 'Dívida não encontrada'}), 404
    
    if debt.debtor_id != user_id:
        return jsonify({'error': 'Esta não é sua dívida'}), 403
    
    if debt.status != 'pending':
        return jsonify({'error': 'Dívida já foi paga ou cancelada'}), 400
    
    # Tentar pagar a dívida
    if debt.mark_as_paid():
        return jsonify({
            'message': f'Dívida de R${debt.amount:.2f} paga com sucesso',
            'debt': debt.to_dict()
        })
    else:
        return jsonify({'error': 'Saldo insuficiente'}), 400

@user_bp.route('/score-info', methods=['GET'])
@jwt_required()
def get_score_info():
    """Obter informações detalhadas sobre o score"""
    user_id = get_jwt_identity()
    user = User.query.get(user_id)
    
    return jsonify({
        'current_score': user.score,
        'max_score': 10.0,
        'description': get_score_description(user.score),
        'how_it_works': {
            'payment_on_time': '+0.1 pontos por pagamento em dia',
            'late_payment': '-0.5 pontos por atraso',
            'range': 'Score varia de 0 a 10',
            'benefits': {
                'high_score': 'Maior confiança no marketplace',
                'low_score': 'Pode afetar negociações'
            }
        }
    })

@user_bp.route('/summary', methods=['GET'])
@jwt_required()
def get_user_summary():
    """Obter resumo financeiro do usuário"""
    user_id = get_jwt_identity()
    
    # Total a pagar
    total_to_pay = db.session.query(db.func.sum(Debt.amount))\
        .filter_by(debtor_id=user_id, status='pending').scalar() or 0
    
    # Total a receber
    total_to_receive = db.session.query(db.func.sum(Debt.amount))\
        .filter_by(creditor_id=user_id, status='pending').scalar() or 0
    
    # Saldo da carteira
    wallet = Wallet.query.filter_by(user_id=user_id).first()
    wallet_balance = wallet.balance if wallet else 0
    
    # Títulos de recebíveis comprados
    bought_receivables = Receivable.query.filter_by(buyer_id=user_id, status='sold').all()
    potential_profit = sum([r.nominal_amount - r.selling_price for r in bought_receivables])
    
    return jsonify({
        'wallet_balance': wallet_balance,
        'total_to_pay': total_to_pay,
        'total_to_receive': total_to_receive,
        'net_balance': total_to_receive - total_to_pay,
        'potential_profit_from_receivables': potential_profit,
        'overall_financial_health': calculate_financial_health(wallet_balance, total_to_pay, total_to_receive)
    })

def get_score_description(score):
    """Obter descrição baseada no score"""
    if score >= 9.0:
        return "Excelente! Você é um usuário confiável."
    elif score >= 7.0:
        return "Bom! Continue pagando em dia."
    elif score >= 5.0:
        return "Regular. Tente melhorar pagando pontualmente."
    else:
        return "Baixo. Pague suas dívidas em dia para melhorar."

def calculate_financial_health(wallet_balance, total_to_pay, total_to_receive):
    """Calcular saúde financeira"""
    net_position = wallet_balance + total_to_receive - total_to_pay
    
    if net_position > 100:
        return "Excelente"
    elif net_position > 0:
        return "Boa"
    elif net_position > -100:
        return "Regular"
    else:
        return "Atenção necessária"