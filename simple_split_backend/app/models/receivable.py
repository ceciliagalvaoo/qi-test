from app import db
from datetime import datetime
import uuid

class Receivable(db.Model):
    __tablename__ = 'receivables'
    
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    owner_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    buyer_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=True)
    debt_id = db.Column(db.String(36), db.ForeignKey('debts.id'), nullable=True)
    nominal_amount = db.Column(db.Float, nullable=False)  # Valor original da dívida
    selling_price = db.Column(db.Float, nullable=False)   # Valor que quer receber agora
    consolidated_group_id = db.Column(db.String(36), nullable=True)  # ID do devedor se faz parte de um grupo consolidado
    status = db.Column(db.String(20), default='for_sale')  # for_sale, sold, cancelled
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    sold_at = db.Column(db.DateTime, nullable=True)
    
    # Relacionamentos
    debt = db.relationship('Debt', backref='receivable')
    # Relacionamentos são definidos no modelo User com backref
    
    def to_dict(self, anonymous=False):
        if anonymous:
            return {
                'id': self.id,
                'nominal_amount': self.nominal_amount,
                'selling_price': self.selling_price,
                'profit_estimated': self.nominal_amount - self.selling_price,
                'owner_score': self.owner.score if self.owner else 0.0,
                'status': self.status,
                'created_at': self.created_at.isoformat() if self.created_at else None
            }
        else:
            data = {
                'id': self.id,
                'owner_id': self.owner_id,
                'owner_name': self.owner.name if self.owner else None,
                'buyer_id': self.buyer_id,
                'buyer_name': self.buyer.name if self.buyer else None,
                'debt_id': self.debt_id,
                'consolidated_group_id': self.consolidated_group_id,
                'nominal_amount': self.nominal_amount,
                'selling_price': self.selling_price,
                'profit_estimated': self.nominal_amount - self.selling_price,
                'status': self.status,
                'created_at': self.created_at.isoformat() if self.created_at else None,
                'sold_at': self.sold_at.isoformat() if self.sold_at else None
            }
            
            # Adicionar informações do devedor
            if self.consolidated_group_id:
                # Título consolidado: buscar devedor pelo consolidated_group_id
                from app.models.user import User
                debtor = User.query.get(self.consolidated_group_id)
                if debtor:
                    data['debtor_id'] = debtor.id
                    data['debtor_name'] = debtor.name
                    data['debtor_type'] = 'consolidated'
            elif self.debt:
                # Título individual: buscar devedor pela dívida
                data['debtor_id'] = self.debt.debtor_id
                data['debtor_name'] = self.debt.debtor.name if self.debt.debtor else None
                data['debtor_type'] = 'individual'
                
            return data
    
    def sell_to_buyer(self, buyer_id):
        """Vende o título para um comprador"""
        from app.models.debt import Debt
        
        try:
            # Atualizar status
            self.buyer_id = buyer_id
            self.status = 'sold'
            self.sold_at = datetime.utcnow()
            
            if self.consolidated_group_id:
                # Título consolidado: transferir todas as dívidas deste devedor
                print(f"[DEBUG] Looking for debts to transfer: creditor={self.owner_id}, debtor={self.consolidated_group_id}")
                
                debts_to_transfer = Debt.query.filter_by(
                    creditor_id=self.owner_id,
                    debtor_id=self.consolidated_group_id,
                    status='pending'
                ).all()
                
                print(f"[DEBUG] Found {len(debts_to_transfer)} debts to transfer")
                for i, debt in enumerate(debts_to_transfer):
                    print(f"[DEBUG] Transferring debt {i+1}: {debt.id} (R$ {debt.amount})")
                    # Criar uma nova dívida para o comprador
                    new_debt = Debt(
                        expense_id=debt.expense_id,
                        debtor_id=debt.debtor_id,
                        creditor_id=buyer_id,
                        amount=debt.amount,
                        status='pending',
                        source='purchased_title',
                        due_date=debt.due_date
                    )
                    db.session.add(new_debt)
                    
                    # Marcar a dívida original como vendida
                    debt.status = 'sold_as_title'
                    debt.sold_at = datetime.utcnow()
                    
                print(f"[DEBUG] Transferred {len(debts_to_transfer)} debts from {self.consolidated_group_id} to {buyer_id}")
            elif self.debt:
                # Título individual: criar nova dívida para o comprador
                print(f"[DEBUG] Transferring individual debt {self.debt.id} to buyer {buyer_id}")
                
                # Criar nova dívida para o comprador
                new_debt = Debt(
                    expense_id=self.debt.expense_id,
                    debtor_id=self.debt.debtor_id,
                    creditor_id=buyer_id,
                    amount=self.debt.amount,
                    status='pending',
                    source='purchased_title',
                    due_date=self.debt.due_date
                )
                db.session.add(new_debt)
                
                # Marcar a dívida original como vendida
                self.debt.status = 'sold_as_title'
                self.debt.sold_at = datetime.utcnow()
            else:
                print(f"[DEBUG] No consolidated_group_id or individual debt found, nothing to transfer")
            
            # Não commitamos aqui, deixamos o marketplace.py gerenciar a transação
            return True
        except Exception as e:
            print(f"[ERROR] Error in sell_to_buyer: {str(e)}")
            return False