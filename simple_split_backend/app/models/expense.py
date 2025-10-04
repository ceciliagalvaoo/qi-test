from app import db
from datetime import datetime
import uuid

class Expense(db.Model):
    __tablename__ = 'expenses'
    
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    group_id = db.Column(db.String(36), db.ForeignKey('groups.id'), nullable=False)
    payer_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    description = db.Column(db.String(200), nullable=False)
    amount = db.Column(db.Float, nullable=False)
    date = db.Column(db.Date, default=datetime.utcnow().date())
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relacionamentos
    debts = db.relationship('Debt', backref='expense', cascade='all, delete-orphan')
    
    def to_dict(self):
        return {
            'id': self.id,
            'group_id': self.group_id,
            'payer_id': self.payer_id,
            'payer_name': self.payer.name if self.payer else None,
            'description': self.description,
            'amount': self.amount,
            'date': self.date.isoformat() if self.date else None,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'debts': [debt.to_dict() for debt in self.debts]
        }
    
    def split_expense(self, member_ids=None):
        """Divide a despesa entre os membros do grupo"""
        # Se não especificou membros, divide entre todos do grupo
        if not member_ids:
            from app.models.user import GroupMember
            group_members = GroupMember.query.filter_by(group_id=self.group_id).all()
            member_ids = [member.user_id for member in group_members]
        
        # Remove o pagador da lista se ele estiver incluído
        if self.payer_id in member_ids:
            member_ids.remove(self.payer_id)
        
        if not member_ids:
            return  # Ninguém deve nada
        
        # Calcula o valor que cada um deve
        amount_per_person = self.amount / (len(member_ids) + 1)  # +1 para incluir o pagador
        
        # Criar dívidas
        from app.models.debt import Debt
        for debtor_id in member_ids:
            debt = Debt(
                expense_id=self.id,
                debtor_id=debtor_id,
                creditor_id=self.payer_id,
                amount=amount_per_person,
                status='pending'
            )
            db.session.add(debt)
        
        db.session.commit()