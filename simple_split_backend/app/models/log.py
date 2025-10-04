from app import db
from datetime import datetime
import uuid

class Log(db.Model):
    __tablename__ = 'logs'
    
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    type = db.Column(db.String(50), nullable=False)  # payment, cancellation, optimization
    description = db.Column(db.Text, nullable=False)
    user_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=True)
    group_id = db.Column(db.String(36), db.ForeignKey('groups.id'), nullable=True)
    amount = db.Column(db.Float, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'type': self.type,
            'description': self.description,
            'user_id': self.user_id,
            'group_id': self.group_id,
            'amount': self.amount,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }