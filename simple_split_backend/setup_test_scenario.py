#!/usr/bin/env python3
"""
Script para verificar a situação atual completa e resetar se necessário
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app import create_app, db
from app.models.user import User
from app.models.debt import Debt
from app.models.receivable import Receivable
from app.models.expense import Expense
from app.models.group import Group
from app.models.user import GroupMember

app = create_app()

def check_current_situation():
    with app.app_context():
        print("=== SITUAÇÃO ATUAL COMPLETA ===\n")
        
        # Buscar usuários
        cecilia = User.query.filter_by(email='cecilia@exemplo.com').first()
        pablo = User.query.filter_by(email='pablo@exemplo.com').first()
        mariana = User.query.filter_by(email='mariana@exemplo.com').first()
        nataly = User.query.filter_by(email='nataly@exemplo.com').first()
        
        print("👥 USUÁRIOS:")
        for user in [cecilia, pablo, mariana, nataly]:
            if user:
                print(f"   {user.name} ({user.email})")
        
        print(f"\n📊 DÍVIDAS DE CADA UM:")
        
        # Cecília
        print(f"🔸 CECÍLIA (como credora):")
        cecilia_credits = Debt.query.filter_by(creditor_id=cecilia.id, status='pending').all()
        for debt in cecilia_credits:
            debtor = User.query.get(debt.debtor_id)
            print(f"   {debtor.name} deve R$ {debt.amount:.2f}")
            
        print(f"\n🔸 PABLO (como credor):")
        pablo_credits = Debt.query.filter_by(creditor_id=pablo.id, status='pending').all()
        for debt in pablo_credits:
            debtor = User.query.get(debt.debtor_id)
            print(f"   {debtor.name} deve R$ {debt.amount:.2f}")
            
        print(f"\n🔸 NATALY (como credora):")
        nataly_credits = Debt.query.filter_by(creditor_id=nataly.id, status='pending').all()
        for debt in nataly_credits:
            debtor = User.query.get(debt.debtor_id)
            print(f"   {debtor.name} deve R$ {debt.amount:.2f}")
            
        print(f"\n📋 TÍTULOS ATIVOS:")
        receivables = Receivable.query.all()
        for rec in receivables:
            owner = User.query.get(rec.owner_id)
            buyer = User.query.get(rec.buyer_id) if rec.buyer_id else None
            consolidated_debtor = User.query.get(rec.consolidated_group_id) if rec.consolidated_group_id else None
            
            print(f"   {owner.name} → Status: {rec.status}")
            print(f"      Valor: R$ {rec.nominal_value:.2f} | Preço: R$ {rec.sale_price:.2f}")
            if consolidated_debtor:
                print(f"      Devedor consolidado: {consolidated_debtor.name}")
            if buyer:
                print(f"      Comprador: {buyer.name}")
            print()

def reset_for_test():
    """Reset para criar situação ideal para teste"""
    with app.app_context():
        print("=== RESETANDO PARA TESTE IDEAL ===\n")
        
        # Buscar usuários
        cecilia = User.query.filter_by(email='cecilia@exemplo.com').first()
        pablo = User.query.filter_by(email='pablo@exemplo.com').first()
        mariana = User.query.filter_by(email='mariana@exemplo.com').first()
        nataly = User.query.filter_by(email='nataly@exemplo.com').first()
        
        # Limpar todas as dívidas e títulos existentes
        Debt.query.delete()
        Receivable.query.delete()
        db.session.commit()
        
        # CRIAR SITUAÇÃO INICIAL IDEAL:
        # 1. Pablo deve 10 para Cecília
        pablo_debt = Debt(
            debtor_id=pablo.id,
            creditor_id=cecilia.id,
            amount=10.0,
            status='pending'
        )
        db.session.add(pablo_debt)
        
        # 2. Mariana deve 10 para Cecília  
        mariana_debt = Debt(
            debtor_id=mariana.id,
            creditor_id=cecilia.id,
            amount=10.0,
            status='pending'
        )
        db.session.add(mariana_debt)
        
        # 3. Mariana deve 20 para Nataly (que será vendido como título)
        mariana_nataly_debt = Debt(
            debtor_id=mariana.id,
            creditor_id=nataly.id,
            amount=20.0,
            status='pending'
        )
        db.session.add(mariana_nataly_debt)
        
        # 4. Criar título da Nataly para venda
        nataly_title = Receivable(
            owner_id=nataly.id,
            consolidated_group_id=mariana.id,  # Mariana é o devedor consolidado
            nominal_value=20.0,
            sale_price=18.0,  # 10% desconto
            status='for_sale'
        )
        db.session.add(nataly_title)
        
        db.session.commit()
        
        print("✅ Situação resetada!")
        print("   Pablo deve R$ 10 para Cecília")
        print("   Mariana deve R$ 10 para Cecília")
        print("   Mariana deve R$ 20 para Nataly (título disponível)")
        print("   Nataly tem título de R$ 20 à venda por R$ 18")

if __name__ == "__main__":
    print("1. Verificando situação atual...")
    check_current_situation()
    
    print("\n" + "="*50)
    response = input("\nDeseja resetar para situação ideal de teste? (s/n): ")
    
    if response.lower() == 's':
        reset_for_test()
        print("\n2. Verificando após reset...")
        check_current_situation()
    else:
        print("Situação mantida como está.")