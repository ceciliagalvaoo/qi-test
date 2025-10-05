from app import create_app, db
from app.models import User, Group, Wallet
from app.models.user import GroupMember

app = create_app()
with app.app_context():
    # Limpar dados
    GroupMember.query.delete()
    Group.query.delete()
    Wallet.query.delete()
    User.query.delete()
    db.session.commit()
    
    # Criar usuário
    user = User(id='1', name='Pablo Silva', email='pablo@exemplo.com', password_hash='hash', score=8.5)
    db.session.add(user)
    db.session.flush()
    
    # Criar wallet
    wallet = Wallet(user_id='1', balance=150.0)
    db.session.add(wallet)
    
    # Criar grupos
    for i, nome in enumerate(['Casa da Praia', 'Churrasco', 'Viagem'], 1):
        group = Group(id=str(i), name=nome, description=f'Grupo {nome}', created_by='1')
        db.session.add(group)
        member = GroupMember(group_id=str(i), user_id='1')
        db.session.add(member)
    
    db.session.commit()
    print('✅ Dados atualizados com IDs simples!')
    
    # Verificar
    groups = Group.query.all()
    for g in groups:
        print(f'Grupo: {g.id} - {g.name}')