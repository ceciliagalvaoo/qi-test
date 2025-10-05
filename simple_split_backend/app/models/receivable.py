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
    status = db.Column(db.String(20), default='for_sale')  # for_sale, sold, cancelled
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    sold_at = db.Column(db.DateTime, nullable=True)
    
    # Relacionamentos
    debt = db.relationship('Debt', backref='receivable')
    
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
            return {
                'id': self.id,
                'owner_id': self.owner_id,
                'owner_name': self.owner.name if self.owner else None,
                'buyer_id': self.buyer_id,
                'buyer_name': self.buyer.name if self.buyer else None,
                'debt_id': self.debt_id,
                'nominal_amount': self.nominal_amount,
                'selling_price': self.selling_price,
                'profit_estimated': self.nominal_amount - self.selling_price,
                'status': self.status,
                'created_at': self.created_at.isoformat() if self.created_at else None,
                'sold_at': self.sold_at.isoformat() if self.sold_at else None
            }
    
    def sell_to_buyer(self, buyer_id):
        """Vende o título para um comprador"""
        # Atualizar status
        self.buyer_id = buyer_id
        self.status = 'sold'
        self.sold_at = datetime.utcnow()
        
        # Transferir a dívida original para o novo proprietário
        original_debt = self.debt
        original_debt.creditor_id = buyer_id
        
        db.session.commit()
        return True