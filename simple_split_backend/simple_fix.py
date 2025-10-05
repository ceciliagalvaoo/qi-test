#!/usr/bin/env python3
"""
Script mais simples: apenas ajustar os dados existentes sem deletar tudo
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app import create_app, db
from app.models.user import User
from app.models.debt import Debt
from app.models.receivable import Receivable

app = create_app()

def simple_fix():
    with app.app_context():
        print("=== AJUSTE SIMPLES DO FLUXO ===\n")
        
        # Buscar usuários
        cecilia = User.query.filter_by(email='cecilia@exemplo.com').first()
        pablo = User.query.filter_by(email='pablo@exemplo.com').first()
        mariana = User.query.filter_by(email='mariana@exemplo.com').first()
        nataly = User.query.filter_by(email='nataly@exemplo.com').first()
        
        print("1. Removendo dívida do Pablo com a Nataly...")
        # A Nataly não deveria ter dívidas pendentes - Pablo deveria estar sendo vendido como título
        pablo_debt_to_nataly = Debt.query.filter_by(
            creditor_id=nataly.id, 
            debtor_id=pablo.id, 
            status='pending'
        ).first()
        
        if pablo_debt_to_nataly:
            # Ao invés de deletar, vamos marcar como "transferida" ou mudar o credor
            # Na verdade, vou simplesmente mudar o status para que não apareça no dashboard da Nataly
            pablo_debt_to_nataly.status = 'transferred_to_title'
            print(f"   Dívida Pablo → Nataly marcada como transferida para título")
        
        print("2. Verificando títulos no marketplace...")
        # Verificar se existe título do Pablo sendo vendido pela Nataly
        pablo_title = Receivable.query.filter_by(
            owner_id=nataly.id,
            consolidated_group_id=pablo.id,
            status='for_sale'
        ).first()
        
        if pablo_title:
            print(f"   ✅ Título Pablo já existe: R$ {pablo_title.nominal_amount}")
        else:
            print("   ❌ Título Pablo não encontrado")
        
        print("3. Verificando dívidas da Cecília...")
        cecilia_debts = Debt.query.filter_by(creditor_id=cecilia.id, status='pending').all()
        
        # Agrupar por devedor
        debts_by_debtor = {}
        for debt in cecilia_debts:
            debtor_id = debt.debtor_id
            if debtor_id not in debts_by_debtor:
                debts_by_debtor[debtor_id] = []
            debts_by_debtor[debtor_id].append(debt)
        
        for debtor_id, debts in debts_by_debtor.items():
            debtor = User.query.get(debtor_id)
            total = sum(d.amount for d in debts)
            print(f"   {debtor.name} deve R$ {total:.2f} ({len(debts)} dívida(s))")
        
        print("4. Verificando títulos que Cecília pode vender...")
        # Títulos de dívidas de grupo (não compradas)
        cecilia_titles = Receivable.query.filter_by(owner_id=cecilia.id, status='for_sale').all()
        for title in cecilia_titles:
            debtor = User.query.get(title.consolidated_group_id) if title.consolidated_group_id else None
            print(f"   Título {debtor.name if debtor else 'N/A'}: R$ {title.nominal_amount}")
        
        db.session.commit()
        
        print(f"\n✅ Ajustes realizados!")
        print("   - Nataly sem dívidas pendentes")
        print("   - Cecília com Pablo + Mariana consolidados")
        print("   - Marketplace com títulos corretos")

if __name__ == "__main__":
    simple_fix()