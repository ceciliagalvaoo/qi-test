from app import db
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime
import uuid

class User(db.Model):
    __tablename__ = 'users'
    
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    phone = db.Column(db.String(20), nullable=True)
    score = db.Column(db.Float, default=7.0)  # Score de 0 a 10
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relacionamentos
    wallet = db.relationship('Wallet', backref='user', uselist=False, cascade='all, delete-orphan')
    group_memberships = db.relationship('GroupMember', backref='user', cascade='all, delete-orphan')
    expenses = db.relationship('Expense', backref='payer', cascade='all, delete-orphan')
    debts_owed = db.relationship('Debt', foreign_keys='Debt.debtor_id', backref='debtor', cascade='all, delete-orphan')
    debts_to_receive = db.relationship('Debt', foreign_keys='Debt.creditor_id', backref='creditor', cascade='all, delete-orphan')
    receivables_owned = db.relationship('Receivable', foreign_keys='Receivable.owner_id', backref='owner', cascade='all, delete-orphan')
    receivables_bought = db.relationship('Receivable', foreign_keys='Receivable.buyer_id', backref='buyer', cascade='all, delete-orphan')
    
    def set_password(self, password):
        self.password_hash = generate_password_hash(password)
    
    def check_password(self, password):
        return check_password_hash(self.password_hash, password)
    
    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'email': self.email,
            'phone': self.phone,
            'score': round(self.score, 1),
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'wallet_balance': self.wallet.balance if self.wallet else 0.0
        }
    
    def update_score(self, payment_on_time=True):
        """Atualiza o score do usuário baseado no histórico de pagamentos"""
        if payment_on_time:
            self.score = min(10.0, self.score + 0.1)
        else:
            self.score = max(0.0, self.score - 0.5)
        db.session.commit()


class GroupMember(db.Model):
    __tablename__ = 'group_members'
    
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    group_id = db.Column(db.String(36), db.ForeignKey('groups.id'), nullable=False)
    joined_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    __table_args__ = (db.UniqueConstraint('user_id', 'group_id', name='unique_user_group'),)