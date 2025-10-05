from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models.user import User
from app.models.wallet import Wallet, Transaction
from app.models.debt import Debt
from app.models.receivable import Receivable
from app.models.expense import Expense
from datetime import datetime

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
    
    # Buscar dívidas a pagar (apenas pendentes, excluindo vendidas como títulos)
    debts_to_pay = Debt.get_pending_debts(debtor_id=user_id).all()
    
    # Buscar dívidas a receber (incluindo títulos comprados, mas excluindo vendidas)
    debts_to_receive = Debt.get_pending_debts(creditor_id=user_id).all()
    
    # Buscar títulos de recebíveis comprados
    bought_receivables = Receivable.query.filter_by(buyer_id=user_id, status='sold').all()
    
    # Calcular totais otimizados para os cards do dashboard (mesma lógica do OTIMIZAR)
    from app.routes.groups import calculate_user_net_balance
    from app.models.user import GroupMember
    
    # Usar lógica otimizada baseada nos saldos dos grupos
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
            # Calcular quanto deve proporcional aos outros saldos positivos
            total_positive = sum(balance for balance in group_balances.values() if balance > 0)
            if total_positive > 0:
                user_debt_share = abs(user_balance)
                optimized_total_to_pay += user_debt_share
                
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
    
    # Usar valores otimizados
    total_to_pay = optimized_total_to_pay
    total_to_receive = optimized_total_to_receive
    
    return jsonify({
        'user': user.to_dict(),
        'wallet': wallet.to_dict() if wallet else {'balance': 0},
        'debts_to_pay': [debt.to_dict() for debt in debts_to_pay],
        'debts_to_receive': [debt.to_dict() for debt in debts_to_receive],
        'bought_receivables': [r.to_dict() for r in bought_receivables],
        # Campos para os cards do dashboard
        'total_to_pay': total_to_pay,
        'total_to_receive': total_to_receive,
        'net_balance': total_to_receive - total_to_pay,
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
    print(f"[DEBUG] Atualizando perfil do usuário")
    user_id = get_jwt_identity()
    print(f"[DEBUG] User ID: {user_id}")
    user = User.query.get(user_id)
    
    if not user:
        print(f"[DEBUG] Usuário não encontrado: {user_id}")
        return jsonify({'error': 'Usuário não encontrado'}), 404
    
    data = request.get_json()
    print(f"[DEBUG] Dados recebidos: {data}")
    
    # Atualizar campos permitidos
    if 'name' in data:
        user.name = data['name']
    if 'email' in data:
        # Verificar se o email já existe em outro usuário
        existing_user = User.query.filter(User.email == data['email'], User.id != user_id).first()
        if existing_user:
            return jsonify({'error': 'Email já está em uso por outro usuário'}), 400
        user.email = data['email']
    if 'phone' in data:
        user.phone = data['phone']
    
    try:
        db.session.commit()
        print(f"[DEBUG] Perfil atualizado com sucesso para usuário {user_id}")
        
        return jsonify({
            'success': True,
            'message': 'Perfil atualizado com sucesso',
            'user': user.to_dict()
        })
    except Exception as e:
        db.session.rollback()
        print(f"[DEBUG] Erro ao salvar no banco: {e}")
        return jsonify({'error': f'Erro interno: {str(e)}'}), 500

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

def _handle_virtual_debt_payment(debt_id, user_id):
    """Lidar com pagamento de dívidas virtuais otimizadas"""
    print(f"[DEBUG] Processando pagamento de dívida virtual: {debt_id}")
    
    # Extrair informações do ID virtual: virtual_debtor-id_creditor-id
    # Remover prefixo "virtual_"
    ids_part = debt_id.replace('virtual_', '')
    print(f"[DEBUG] IDs part após remover virtual_: {ids_part}")
    
    # O formato é: debtor_uuid_creditor_uuid
    # Procurar pela posição onde termina o primeiro UUID e começa o segundo
    # UUID tem formato: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx (36 caracteres)
    
    if len(ids_part) < 73:  # 36 + 1 + 36 = 73 caracteres mínimo
        print(f"[DEBUG] Erro: ID muito curto para conter 2 UUIDs")
        return jsonify({'error': 'ID de dívida virtual inválido - muito curto'}), 400
    
    # Procurar o underscore que separa os dois UUIDs
    # O primeiro UUID sempre tem 36 caracteres
    debtor_id = ids_part[:36]
    creditor_id = ids_part[37:]  # Pula o underscore
    
    print(f"[DEBUG] Debtor ID extraído (36 chars): {debtor_id}")
    print(f"[DEBUG] Creditor ID extraído (resto): {creditor_id}")
    
    # Validar formato UUID
    import re
    uuid_pattern = r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    
    if not re.match(uuid_pattern, debtor_id) or not re.match(uuid_pattern, creditor_id):
        print(f"[DEBUG] Erro: UUIDs inválidos")
        return jsonify({'error': 'Formato de UUID inválido'}), 400
    
    print(f"[DEBUG] Debtor ID extraído: {debtor_id}")
    print(f"[DEBUG] Creditor ID extraído: {creditor_id}")
    print(f"[DEBUG] User ID atual: {user_id}")
    
    if debtor_id != user_id:
        print(f"[DEBUG] Erro: debtor_id ({debtor_id}) != user_id ({user_id})")
        return jsonify({'error': 'Esta não é sua dívida'}), 403
    
    # Calcular o valor da dívida virtual usando a lógica dos grupos
    from app.models.user import GroupMember
    from app.routes.groups import _calculate_group_balances
    
    # Encontrar grupos em comum entre devedor e credor
    debtor_groups = GroupMember.query.filter_by(user_id=debtor_id).all()
    creditor_groups = GroupMember.query.filter_by(user_id=creditor_id).all()
    
    print(f"[DEBUG] Grupos do devedor: {[g.group_id for g in debtor_groups]}")
    print(f"[DEBUG] Grupos do credor: {[g.group_id for g in creditor_groups]}")
    
    common_groups = []
    for dg in debtor_groups:
        for cg in creditor_groups:
            if dg.group_id == cg.group_id:
                common_groups.append(dg.group_id)
    
    print(f"[DEBUG] Grupos em comum: {common_groups}")
    
    if not common_groups:
        print(f"[DEBUG] Erro: usuários não compartilham grupos")
        return jsonify({'error': 'Usuários não compartilham grupos'}), 400
    
    # Calcular o valor total devido entre os usuários
    total_amount_owed = 0.0
    
    for group_id in common_groups:
        print(f"[DEBUG] Calculando balances para grupo: {group_id}")
        group_balances = _calculate_group_balances(group_id)
        debtor_balance = group_balances.get(debtor_id, 0.0)
        creditor_balance = group_balances.get(creditor_id, 0.0)
        
        print(f"[DEBUG] Saldo do devedor no grupo {group_id}: {debtor_balance}")
        print(f"[DEBUG] Saldo do credor no grupo {group_id}: {creditor_balance}")
        
        # Se o devedor tem saldo negativo e o credor positivo
        if debtor_balance < 0 and creditor_balance > 0:
            # Calcular proporção que o devedor deve ao credor
            total_negative = sum(abs(balance) for balance in group_balances.values() if balance < 0)
            print(f"[DEBUG] Total negativo no grupo: {total_negative}")
            
            if total_negative > 0:
                proportion = abs(debtor_balance) / total_negative
                amount_owed = creditor_balance * proportion
                print(f"[DEBUG] Proporção: {proportion}, Valor devido: {amount_owed}")
                total_amount_owed += amount_owed
    
    print(f"[DEBUG] Total amount owed calculado: {total_amount_owed}")
    
    if total_amount_owed <= 0.01:
        print(f"[DEBUG] Erro: não há dívida para pagar")
        return jsonify({'error': 'Não há dívida para pagar'}), 400
    
    amount = round(total_amount_owed, 2)
    print(f"[DEBUG] Valor calculado a pagar: {amount}")
    
    # Verificar saldo da carteira
    wallet = Wallet.query.filter_by(user_id=user_id).first()
    if not wallet or wallet.balance < amount:
        return jsonify({'error': 'Saldo insuficiente na carteira'}), 400
    
    # Obter nome do credor
    creditor = User.query.get(creditor_id)
    if not creditor:
        return jsonify({'error': 'Credor não encontrado'}), 404
    
    # Processar pagamento virtual
    # 1. Reduzir saldo da wallet
    wallet.balance -= amount
    
    # 2. Criar transação
    transaction = Transaction(
        wallet_id=wallet.id,
        type='debit',
        amount=amount,
        description=f'Pagamento virtual - R${amount:.2f} para {creditor.name}'
    )
    db.session.add(transaction)
    
    # 3. Criar uma dívida virtual paga para registrar no banco
    # Buscar qualquer despesa do grupo para referenciar (workaround)
    from app.models.expense import Expense
    sample_expense = None
    
    print(f"[DEBUG] Procurando despesa nos grupos: {common_groups}")
    
    for group_id in common_groups:
        sample_expense = Expense.query.filter_by(group_id=group_id).first()
        print(f"[DEBUG] Grupo {group_id}: despesa encontrada = {sample_expense.id if sample_expense else 'None'}")
        if sample_expense:
            break
    
    if sample_expense:
        print(f"[DEBUG] Criando dívida virtual com expense_id: {sample_expense.id}")
        paid_debt = Debt(
            debtor_id=user_id,
            creditor_id=creditor_id,
            amount=amount,
            status='paid',
            source='virtual_payment',
            paid_at=datetime.utcnow(),
            expense_id=sample_expense.id  # Usar uma despesa existente como referência
        )
        db.session.add(paid_debt)
        print(f"[DEBUG] Dívida virtual adicionada à sessão")
    else:
        print(f"[DEBUG] Nenhuma despesa encontrada nos grupos, não criando dívida física")
    
    # 4. Adicionar log
    from app.models.log import Log
    debtor = User.query.get(user_id)
    
    log_entry = Log(
        type='payment',
        description=f'{debtor.name} pagou R${amount:.2f} via carteira para {creditor.name} (pagamento virtual)',
        user_id=user_id,
        amount=amount
    )
    db.session.add(log_entry)
    
    try:
        db.session.commit()
        print(f"[DEBUG] Commit realizado com sucesso!")
        
        # Verificar se a dívida foi salva
        if sample_expense:
            saved_debt = Debt.query.filter_by(
                debtor_id=user_id,
                creditor_id=creditor_id,
                source='virtual_payment',
                status='paid'
            ).order_by(Debt.created_at.desc()).first()
            print(f"[DEBUG] Dívida virtual salva no banco: {saved_debt.id if saved_debt else 'NÃO ENCONTRADA'}")
        
    except Exception as commit_error:
        print(f"[DEBUG] Erro no commit: {commit_error}")
        db.session.rollback()
        raise commit_error
    
    print(f"[DEBUG] Pagamento virtual processado com sucesso!")
    
    return jsonify({
        'success': True,
        'message': f'Dívida de R${amount:.2f} paga com sucesso!',
        'new_balance': wallet.balance,
        'payment_details': {
            'amount': amount,
            'creditor_name': creditor.name,
            'payment_method': 'wallet_virtual'
        }
    })

@user_bp.route('/pay-debt/<string:debt_id>', methods=['POST'])
@jwt_required()
def pay_debt(debt_id):
    """Pagar uma dívida via wallet"""
    print(f"[DEBUG] Tentando pagar dívida: {debt_id}")
    user_id = get_jwt_identity()
    print(f"[DEBUG] User ID: {user_id}")
    
    try:
        # Verificar se é uma dívida virtual
        if debt_id.startswith('virtual_'):
            print(f"[DEBUG] Detectada dívida virtual: {debt_id}")
            return _handle_virtual_debt_payment(debt_id, user_id)
        
        # Buscar dívida real no banco
        debt = Debt.query.get(debt_id)
        if not debt:
            print(f"[DEBUG] Dívida não encontrada: {debt_id}")
            return jsonify({'error': 'Dívida não encontrada'}), 404

        print(f"[DEBUG] Dívida encontrada - Devedor: {debt.debtor_id}, Credor: {debt.creditor_id}, Valor: {debt.amount}")

        if debt.debtor_id != user_id:
            print(f"[DEBUG] Usuário não é o devedor")
            return jsonify({'error': 'Esta não é sua dívida'}), 403

        if debt.status != 'pending':
            print(f"[DEBUG] Dívida não está pendente")
            return jsonify({'error': 'Dívida já foi paga ou cancelada'}), 400

        # Verificar wallet
        wallet = Wallet.query.filter_by(user_id=user_id).first()
        if not wallet or wallet.balance < debt.amount:
            return jsonify({'error': 'Saldo insuficiente na carteira'}), 400

        # Marcar como pago
        debt.status = 'paid'
        debt.paid_at = datetime.utcnow()
        
        # Reduzir saldo da wallet
        wallet.balance -= debt.amount

        # Criar transação de débito
        transaction = Transaction(
            wallet_id=wallet.id,
            type='debit',
            amount=debt.amount,
            description=f'Pagamento de dívida - R${debt.amount:.2f}'
        )
        
        db.session.add(transaction)
        
        # Notificar o grupo sobre o pagamento (para atualização em tempo real)
        group_id = None
        if debt.expense and debt.expense.group_id:
            group_id = debt.expense.group_id
            print(f"[DEBUG] Pagamento afeta o grupo: {group_id}")
            
            # Adicionar log/notificação para o grupo
            from app.models.log import Log
            log_entry = Log(
                group_id=group_id,
                type='payment',
                description=f'{debt.debtor.name} pagou R${debt.amount:.2f} via carteira para {debt.creditor.name}',
                user_id=user_id,
                amount=debt.amount
            )
            db.session.add(log_entry)
        
        db.session.commit()
        print(f"[DEBUG] Pagamento processado com sucesso!")

        return jsonify({
            'success': True,
            'message': f'Dívida de R${debt.amount:.2f} paga com sucesso!',
            'new_balance': wallet.balance,
            'group_id': group_id,  # Para o frontend saber qual grupo foi afetado
            'payment_details': {
                'debt_id': debt.id,
                'amount': debt.amount,
                'creditor_name': debt.creditor.name,
                'payment_method': 'wallet'
            }
        })

    except Exception as e:
        print(f"[ERROR] Erro: {str(e)}")
        db.session.rollback()
        return jsonify({'error': f'Erro: {str(e)}'}), 500

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
    
    # A pagar: soma real das dívidas pendentes (excluindo vendidas como títulos)
    total_to_pay = db.session.query(db.func.sum(Debt.amount))\
        .filter(Debt.debtor_id == user_id, Debt.status == 'pending').scalar() or 0
    
    # A receber: soma real dos créditos pendentes (excluindo vendidas como títulos)
    total_to_receive = db.session.query(db.func.sum(Debt.amount))\
        .filter(Debt.creditor_id == user_id, Debt.status == 'pending').scalar() or 0
    
    # Total gasto: soma da parte do usuário nas despesas (tanto como pagador quanto devedor)
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
    wallet = Wallet.query.filter_by(user_id=user_id).first()
    wallet_balance = wallet.balance if wallet else 0
    
    # Títulos de recebíveis comprados
    bought_receivables = Receivable.query.filter_by(buyer_id=user_id, status='sold').all()
    potential_profit = sum([r.nominal_amount - r.selling_price for r in bought_receivables])
    
    return jsonify({
        'wallet_balance': wallet_balance,
        'total_to_pay': total_to_pay,
        'total_to_receive': total_to_receive,
        'total_spent': total_spent,
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