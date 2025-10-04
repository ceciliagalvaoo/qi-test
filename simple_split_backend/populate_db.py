"""
Script para popular o banco de dados com dados iniciais de teste
"""
from app import create_app, db
from app.models import User, Group, Expense, Receivable
from werkzeug.security import generate_password_hash
from datetime import datetime, timedelta
import uuid

def populate_database():
    app = create_app()
    
    with app.app_context():
        # Limpar dados existentes
        db.drop_all()
        db.create_all()
        
        print("🔄 Criando usuários...")
        
        # Criar usuários Pablo, Cecília e Mariana
        pablo = User(
            id=str(uuid.uuid4()),
            name="Pablo",
            email="pablo@exemplo.com",
            phone="(11) 99999-0001",
            password_hash=generate_password_hash("senha123")
        )
        
        cecilia = User(
            id=str(uuid.uuid4()),
            name="Cecília",
            email="cecilia@exemplo.com",
            phone="(11) 99999-0002",
            password_hash=generate_password_hash("senha123")
        )
        
        mariana = User(
            id=str(uuid.uuid4()),
            name="Mariana",
            email="mariana@exemplo.com",
            phone="(11) 99999-0003",
            password_hash=generate_password_hash("senha123")
        )
        
        db.session.add_all([pablo, cecilia, mariana])
        
        print("👥 Criando grupo...")
        
        # Criar grupo com os três usuários
        grupo_amigos = Group(
            id=str(uuid.uuid4()),
            name="Amigos",
            description="Grupo de amigos para dividir gastos",
            created_by=pablo.id
        )
        
        db.session.add(grupo_amigos)
        db.session.commit()
        
        # Adicionar membros ao grupo  
        from app.models.user import GroupMember
        
        membro1 = GroupMember(user_id=pablo.id, group_id=grupo_amigos.id)
        membro2 = GroupMember(user_id=cecilia.id, group_id=grupo_amigos.id)
        membro3 = GroupMember(user_id=mariana.id, group_id=grupo_amigos.id)
        
        db.session.add_all([membro1, membro2, membro3])
        
        print("💰 Criando despesas...")
        
        # Criar algumas despesas de exemplo
        despesa1 = Expense(
            id=str(uuid.uuid4()),
            description="Jantar no restaurante",
            amount=150.00,
            payer_id=pablo.id,
            group_id=grupo_amigos.id,
            created_at=datetime.now() - timedelta(days=2)
        )
        
        despesa2 = Expense(
            id=str(uuid.uuid4()),
            description="Uber para casa",
            amount=45.00,
            payer_id=cecilia.id,
            group_id=grupo_amigos.id,
            created_at=datetime.now() - timedelta(days=1)
        )
        
        despesa3 = Expense(
            id=str(uuid.uuid4()),
            description="Cinema",
            amount=90.00,
            payer_id=mariana.id,
            group_id=grupo_amigos.id,
            created_at=datetime.now()
        )
        
        db.session.add_all([despesa1, despesa2, despesa3])
        
        print("🎯 Dividindo despesas automaticamente...")
        
        # Dividir as despesas automaticamente entre os membros
        despesa1.split_expense()
        despesa2.split_expense()  
        despesa3.split_expense()
        
        db.session.commit()
        
        print("✅ Banco de dados populado com sucesso!")
        print(f"👤 Usuários criados: {User.query.count()}")
        print(f"👥 Grupos criados: {Group.query.count()}")
        print(f"💰 Despesas criadas: {Expense.query.count()}")
        print(f"🎯 Recebíveis criados: {Receivable.query.count()}")
        
        print("\n📋 Credenciais de acesso:")
        print("Pablo: pablo@exemplo.com | senha123")
        print("Cecília: cecilia@exemplo.com | senha123")
        print("Mariana: mariana@exemplo.com | senha123")

if __name__ == '__main__':
    populate_database()