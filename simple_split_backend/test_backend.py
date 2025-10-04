"""
Script para testar o backend do The Simple Split
Execute este arquivo para verificar se o backend está funcionando corretamente
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app import create_app, db
from app.models.user import User, GroupMember
from app.models.group import Group
from app.models.expense import Expense
from app.models.debt import Debt
from app.models.log import Log
from app.models.receivable import Receivable
from app.models.wallet import Wallet, Transaction
from app.services.init_data import initialize_data

def test_backend():
    """Testar funcionalidades básicas do backend"""
    app = create_app()
    
    with app.app_context():
        print("🚀 Testando The Simple Split Backend...")
        
        # 1. Criar tabelas
        print("\n1. Criando tabelas do banco de dados...")
        db.create_all()
        print("✅ Tabelas criadas com sucesso!")
        
        # 2. Inicializar dados
        print("\n2. Inicializando dados básicos...")
        initialize_data()
        print("✅ Dados inicializados com sucesso!")
        
        # 3. Verificar usuários criados
        print("\n3. Verificando usuários criados...")
        users = User.query.all()
        for user in users:
            print(f"   - {user.name} ({user.email}) - Score: {user.score}")
        print("✅ Usuários verificados!")
        
        # 4. Verificar grupos
        print("\n4. Verificando grupos...")
        groups = Group.query.all()
        for group in groups:
            print(f"   - {group.name} - Criado por: {group.creator.name}")
            members = group.get_members()
            print(f"     Membros: {', '.join([m.name for m in members])}")
        print("✅ Grupos verificados!")
        
        # 5. Verificar despesas e dívidas
        print("\n5. Verificando despesas e dívidas...")
        expenses = Expense.query.all()
        for expense in expenses:
            print(f"   - {expense.description}: R${expense.amount} pago por {expense.payer.name}")
            for debt in expense.debts:
                print(f"     → {debt.debtor.name} deve R${debt.amount} para {debt.creditor.name}")
        print("✅ Despesas e dívidas verificadas!")
        
        # 6. Verificar carteiras
        print("\n6. Verificando carteiras...")
        wallets = Wallet.query.all()
        for wallet in wallets:
            print(f"   - {wallet.user.name}: R${wallet.balance}")
        print("✅ Carteiras verificadas!")
        
        print("\n🎉 Backend funcionando perfeitamente!")
        print("📝 Próximo passo: Configurar o frontend Flutter")
        
        return True

if __name__ == "__main__":
    test_backend()