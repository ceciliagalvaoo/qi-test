# The Simple Split - MVP

Um aplicativo completo para divisão de despesas e marketplace de recebíveis, desenvolvido com **Flutter** (frontend) e **Python Flask** (backend), usando **SQLite** como banco de dados.

## 🚀 Características Principais

### ✨ Interface Minimalista
- Design inspirado no Apple iOS
- Interface limpa e intuitiva
- Navegação fluida entre telas

### 👥 Gestão de Grupos
- Criação de grupos para diferentes ocasiões (ex: "Viagem RJ-2025")
- Adição de contatos aos grupos
- Registro e divisão automática de despesas
- Sistema de logs automáticos para otimização de dívidas

### 💰 Carteira Digital
- Saldo interno para pagamentos
- Histórico completo de transações
- Transferências entre usuários

### 📊 Marketplace de Recebíveis
- Venda de títulos de recebíveis com desconto
- Compra anônima de títulos
- Sistema de score para confiabilidade

### 🎯 Sistema de Score Dinâmico
- Score de 0 a 10 baseado no histórico de pagamentos
- Pagamentos em dia aumentam o score
- Atrasos reduzem o score

### 📈 Insights Automáticos
- Alertas de pagamentos pendentes
- Resumos financeiros
- Notificações de otimizações automáticas

## 🛠️ Tecnologias Utilizadas

### Backend
- **Flask** - Framework web Python
- **SQLAlchemy** - ORM para banco de dados
- **Flask-JWT-Extended** - Autenticação JWT
- **SQLite** - Banco de dados
- **Flask-CORS** - CORS para frontend

### Frontend
- **Flutter** - Framework UI multiplataforma
- **Provider** - Gerenciamento de estado
- **Go Router** - Navegação
- **HTTP** - Comunicação com API
- **Shared Preferences** - Armazenamento local

## 🚀 Como Executar

### 1. Backend (API Python)

```powershell
# Navegue para o diretório do backend
cd simple_split_backend

# Instale as dependências
pip install -r requirements.txt

# Execute o servidor
python run.py
```

O backend estará disponível em `http://localhost:5000`

### 2. Frontend (Flutter)

```powershell
# Navegue para o diretório do frontend
cd simple_split_frontend

# Instale as dependências
flutter pub get

# Execute o aplicativo
flutter run
```

### 3. Testar o Backend

Para verificar se o backend está funcionando corretamente:

```powershell
cd simple_split_backend
python test_backend.py
```

## 👤 Usuários Pré-cadastrados

O sistema já vem com 3 usuários para teste:

| Nome     | Email                | Senha       | Score |
|----------|---------------------|-------------|-------|
| Pablo    | pablo@example.com   | password123 | 9.5   |
| Cecília  | cecilia@example.com | password123 | 8.7   |
| Mariana  | mariana@example.com | password123 | 9.2   |

## 📱 Principais Funcionalidades

### Dashboard Principal
Menu inferior com 5 abas:
- **Grupos**: Gestão de grupos e despesas
- **Contatos**: Lista de contatos e recebíveis
- **Insights**: Informações financeiras automáticas
- **Marketplace**: Compra e venda de títulos
- **Usuário**: Perfil e carteira digital

### Sistema de Logs Automáticos
O aplicativo possui um sistema inteligente que:
1. **Detecta dívidas cruzadas** entre usuários
2. **Cancela automaticamente** dívidas equivalentes
3. **Otimiza pagamentos** entre grupos
4. **Gera logs** de todas as operações automáticas

### Sistema de Score
O score do usuário (0-10) é calculado baseado em:
- **+0.1 pontos**: Pagamento em dia
- **-0.5 pontos**: Pagamento atrasado
- **Benefícios**: Maior confiança no marketplace

---

**The Simple Split** - Simplifique suas divisões financeiras! 💰✨