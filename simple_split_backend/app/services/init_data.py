from app import db
from app.models.user import User
from app.models.group import Group
from app.models.wallet import Wallet
from app.models.expense import Expense
from datetime import datetime
import uuid

def initialize_data():
    """Inicializa o banco com dados básicos (Pablo, Cecília e Mariana)"""
    
    # Verificar se já existem usuários
    if User.query.first():
        print("Dados já existem no banco!")
        return
    
    # Criar usuários
    users_data = [
        {
            'name': 'Pablo',
            'email': 'pablo@example.com',
            'password': 'password123',
            'phone': '(11) 99999-1111',
            'score': 9.5
        },
        {
            'name': 'Cecília',
            'email': 'cecilia@example.com',
            'password': 'password123',
            'phone': '(11) 99999-2222',
            'score': 8.7
        },
        {
            'name': 'Mariana',
            'email': 'mariana@example.com',
            'password': 'password123',
            'phone': '(11) 99999-3333',
            'score': 9.2
        }
    ]
    
    created_users = []
    for user_data in users_data:
        user = User(
            id=str(uuid.uuid4()),
            name=user_data['name'],
            email=user_data['email'],
            phone=user_data['phone'],
            score=user_data['score']
        )
        user.set_password(user_data['password'])
        db.session.add(user)
        created_users.append(user)
    
    db.session.commit()
    
    # Criar carteiras para cada usuário
    for user in created_users:
        wallet = Wallet(user_id=user.id, balance=1000.0)  # R$ 1000 inicial
        db.session.add(wallet)
    
    db.session.commit()
    
    # Criar um grupo de exemplo "Viagem RJ-2025"
    pablo = User.query.filter_by(email='pablo@example.com').first()
    if pablo:
        group = Group(
            name='Viagem RJ-2025',
            description='Gastos da viagem ao Rio de Janeiro',
            created_by=pablo.id
        )
        db.session.add(group)
        db.session.commit()
        
        # Adicionar todos os usuários ao grupo
        group.add_member(pablo.id)
        for user in created_users:
            if user.id != pablo.id:
                group.add_member(user.id)
        
        # Criar uma despesa de exemplo
        expense = Expense(
            group_id=group.id,
            payer_id=pablo.id,
            description='Uber para o aeroporto',
            amount=30.0,
            date=datetime.utcnow().date()
        )
        db.session.add(expense)
        db.session.commit()
        
        # Dividir a despesa automaticamente
        expense.split_expense()
    
    print("Dados iniciais criados com sucesso!")
    print("Usuários: Pablo, Cecília, Mariana")
    print("Grupo: Viagem RJ-2025 com despesa de exemplo")