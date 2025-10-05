from app import create_app, db
from app.models.user import User
from app.models.group import Group
from app.models.expense import Expense
from app.models.debt import Debt
from app.models.log import Log
from app.models.receivable import Receivable
from app.models.wallet import Wallet
from app.services.init_data import initialize_data

app = create_app()

if __name__ == '__main__':
    with app.app_context():
        # Criar tabelas
        db.create_all()
        
        # Inicializar dados (usuários Pablo, Cecília e Mariana)
        initialize_data()
        
        print("Banco de dados inicializado com sucesso!")
    
    # Configuração para produção
    import os
    port = int(os.environ.get('PORT', 5000))
    debug = os.environ.get('FLASK_ENV') != 'production'
    
    app.run(debug=debug, host='0.0.0.0', port=port)