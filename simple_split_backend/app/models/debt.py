from app import db
from datetime import datetime
import uuid

class Debt(db.Model):
    __tablename__ = 'debts'
    
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    expense_id = db.Column(db.String(36), db.ForeignKey('expenses.id'), nullable=False)
    debtor_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    creditor_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    amount = db.Column(db.Float, nullable=False)
    status = db.Column(db.String(20), default='pending')  # pending, paid, cancelled, sold_as_title
    source = db.Column(db.String(20), default='group_debt')  # group_debt, purchased_title, virtual_payment
    due_date = db.Column(db.Date, nullable=True)
    paid_at = db.Column(db.DateTime, nullable=True)
    sold_at = db.Column(db.DateTime, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'expense_id': self.expense_id,
            'debtor_id': self.debtor_id,
            'debtor_name': self.debtor.name if self.debtor else None,
            'creditor_id': self.creditor_id,
            'creditor_name': self.creditor.name if self.creditor else None,
            'amount': self.amount,
            'status': self.status,
            'source': self.source,
            'due_date': self.due_date.isoformat() if self.due_date else None,
            'paid_at': self.paid_at.isoformat() if self.paid_at else None,
            'sold_at': self.sold_at.isoformat() if self.sold_at else None,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'expense_description': self.expense.description if self.expense else None
        }
    
    def mark_as_paid(self):
        """Marca a dívida como paga e atualiza scores"""
        self.status = 'paid'
        self.paid_at = datetime.utcnow()
        
        # Atualizar scores
        self.debtor.update_score(payment_on_time=True)
        
        db.session.commit()
        return True
    
    def cancel(self):
        """Cancela a dívida"""
        self.status = 'cancelled'
        db.session.commit()
    
    @classmethod
    def get_pending_debts(cls, **kwargs):
        """Buscar apenas dívidas verdadeiramente pendentes (excluindo vendidas como títulos)"""
        return cls.query.filter_by(status='pending', **kwargs)
    
    @classmethod 
    def get_available_for_sale_debts(cls, creditor_id):
        """Buscar dívidas que podem ser vendidas no marketplace (apenas pending)"""
        return cls.query.filter_by(creditor_id=creditor_id, status='pending')