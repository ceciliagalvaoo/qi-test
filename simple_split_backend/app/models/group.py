from app import db
from datetime import datetime
import uuid

class Group(db.Model):
    __tablename__ = 'groups'
    
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text, nullable=True)
    created_by = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relacionamentos
    creator = db.relationship('User', backref='created_groups')
    members = db.relationship('GroupMember', backref='group', cascade='all, delete-orphan')
    expenses = db.relationship('Expense', backref='group', cascade='all, delete-orphan')
    
    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'description': self.description,
            'created_by': self.created_by,
            'creator_name': self.creator.name if self.creator else None,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'members_count': len(self.members),
            'total_expenses': sum([expense.amount for expense in self.expenses])
        }
    
    def get_members(self):
        """Retorna lista de membros do grupo"""
        from app.models.user import User
        return [User.query.get(member.user_id) for member in self.members]
    
    def add_member(self, user_id):
        """Adiciona um membro ao grupo"""
        from app.models.user import GroupMember
        
        # Verificar se já é membro
        existing_member = GroupMember.query.filter_by(
            user_id=user_id, 
            group_id=self.id
        ).first()
        
        if not existing_member:
            new_member = GroupMember(user_id=user_id, group_id=self.id)
            db.session.add(new_member)
            db.session.commit()
            return True
        return False