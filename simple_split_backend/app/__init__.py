from flask import Flask, jsonify, request
from flask_sqlalchemy import SQLAlchemy
from flask_jwt_extended import JWTManager
import os
from datetime import timedelta

db = SQLAlchemy()
jwt = JWTManager()

def create_app():
    app = Flask(__name__)
    
    # Configurações
    app.config['SECRET_KEY'] = 'simple-split-secret-key-2025'
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///simple_split.db'
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    app.config['JWT_SECRET_KEY'] = 'jwt-simple-split-secret-2025'
    app.config['JWT_ACCESS_TOKEN_EXPIRES'] = timedelta(hours=24)
    
    # Evitar redirecionamentos automáticos que quebram CORS
    app.url_map.strict_slashes = False
    
    # Inicializar extensões
    db.init_app(app)
    jwt.init_app(app)
    # CORS será configurado manualmente nos handlers abaixo
    
    # Registrar blueprints
    from app.routes.auth import auth_bp
    from app.routes.groups import groups_bp
    from app.routes.expenses import expenses_bp
    from app.routes.debts import debts_bp
    from app.routes.contacts import contacts_bp
    from app.routes.insights import insights_bp
    from app.routes.marketplace import marketplace_bp
    from app.routes.user import user_bp
    
    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(groups_bp, url_prefix='/api/groups')
    app.register_blueprint(expenses_bp, url_prefix='/api/expenses')
    app.register_blueprint(debts_bp, url_prefix='/api/debts')
    app.register_blueprint(contacts_bp, url_prefix='/api/contacts')
    app.register_blueprint(insights_bp, url_prefix='/api/insights')
    app.register_blueprint(marketplace_bp, url_prefix='/api/marketplace')
    app.register_blueprint(user_bp, url_prefix='/api/user')
    
    # Rota de compatibilidade para /api/users/profile
    from app.routes.user import get_user_profile
    app.add_url_rule('/api/users/profile', 'users_profile', get_user_profile, methods=['GET'])
    
    # Handler global para CORS
    @app.before_request
    def handle_preflight():
        if request.method == "OPTIONS":
            response = jsonify()
            response.headers["Access-Control-Allow-Origin"] = "http://localhost:8081"
            response.headers["Access-Control-Allow-Headers"] = "Content-Type,Authorization"
            response.headers["Access-Control-Allow-Methods"] = "GET,PUT,POST,DELETE,OPTIONS"
            response.headers["Access-Control-Allow-Credentials"] = "true"
            return response
    
    @app.after_request
    def after_request(response):
        response.headers["Access-Control-Allow-Origin"] = "http://localhost:8081"
        response.headers["Access-Control-Allow-Headers"] = "Content-Type,Authorization"
        response.headers["Access-Control-Allow-Methods"] = "GET,PUT,POST,DELETE,OPTIONS"
        response.headers["Access-Control-Allow-Credentials"] = "true"
        return response
    
    # Endpoint raiz de teste
    @app.route('/')
    def index():
        return jsonify({'message': 'Simple Split API - Backend funcionando!', 'version': '1.0.0'})
    
    @app.route('/api/health')
    def health():
        return jsonify({'status': 'OK', 'message': 'API funcionando!', 'timestamp': 'now'})
    
    return app