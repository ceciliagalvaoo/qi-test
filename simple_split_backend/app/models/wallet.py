from app import db
from datetime import datetime
import uuid

class Wallet(db.Model):
    __tablename__ = 'wallets'
    
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False, unique=True)
    balance = db.Column(db.Float, default=0.0)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relacionamentos
    transactions = db.relationship('Transaction', backref='wallet', cascade='all, delete-orphan')
    
    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'balance': self.balance,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }
    
    def add_funds(self, amount, description="Adicionar saldo", auto_commit=True):
        """Adiciona fundos à carteira"""
        self.balance += amount
        
        transaction = Transaction(
            wallet_id=self.id,
            type='credit',
            amount=amount,
            description=description
        )
        db.session.add(transaction)
        
        if auto_commit:
            db.session.commit()
        return True
    
    def withdraw_funds(self, amount, description="Saque", auto_commit=True):
        """Remove fundos da carteira"""
        if self.balance >= amount:
            self.balance -= amount
            
            transaction = Transaction(
                wallet_id=self.id,
                type='debit',
                amount=amount,
                description=description
            )
            db.session.add(transaction)
            
            if auto_commit:
                db.session.commit()
            return True
        return False


class Transaction(db.Model):
    __tablename__ = 'transactions'
    
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    wallet_id = db.Column(db.String(36), db.ForeignKey('wallets.id'), nullable=False)
    type = db.Column(db.String(10), nullable=False)  # credit, debit
    amount = db.Column(db.Float, nullable=False)
    description = db.Column(db.String(200), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'wallet_id': self.wallet_id,
            'type': self.type,
            'amount': self.amount,
            'description': self.description,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }