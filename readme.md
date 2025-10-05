# The Simple Split - MVP

## 📋 Sobre o Projeto

**The Simple Split** é um aplicativo inovador que resolve dois problemas comuns:

1. **📊 Divisão de Despesas em Grupo**: Como dividir a conta do restaurante, viagem ou aluguel de forma justa e automática?
2. **💰 Liquidez de Recebíveis**: Como transformar dívidas pendentes em dinheiro imediato?

### 🎯 O que o App Faz?

- **Cria grupos** para diferentes ocasiões (viagem, república, projeto)
- **Registra despesas** e divide automaticamente entre os participantes  
- **Calcula quem deve para quem** com otimização automática de pagamentos
- **Permite vender dívidas** no marketplace por um valor com desconto
- **Oferece carteira digital** para pagamentos internos
- **Gera insights financeiros** automáticos e alertas inteligentes

### 🏗️ Arquitetura

- **Frontend**: Flutter (iOS/Android/Web)
- **Backend**: Python Flask com SQLAlchemy
- **Banco**: SQLite (fácil deploy e desenvolvimento)
- **Autenticação**: JWT tokens
- **API**: RESTful com CORS habilitado

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

## 🚀 Como Rodar o Projeto

### ⚡ Pré-requisitos

Certifique-se de ter instalado:

- **Python 3.8+** ([Download](https://www.python.org/downloads/))
- **Flutter SDK 3.10+** ([Guia de instalação](https://docs.flutter.dev/get-started/install))
- **Git** para clonar o repositório

### 📦 1. Clone e Prepare o Projeto

```bash
# Clone o repositório
git clone https://github.com/ceciliagalvaoo/qi-test.git
cd qi-test

# Crie ambiente virtual Python (recomendado)
python -m venv .venv

# Ative o ambiente virtual
# Windows:
.venv\Scripts\activate
# Linux/Mac:
source .venv/bin/activate
```

### 🐍 2. Configure o Backend (API Python)

**Terminal 1 (Backend):**
```powershell
# Navegue para o backend e instale dependências (primeira vez)
cd simple_split_backend
pip install -r requirements.txt

# Execute o servidor Flask
python run.py
```

✅ **Backend rodando em**: `http://localhost:5000`

### 📱 3. Configure o Frontend (Flutter)

**Terminal 2 (Frontend):**
```powershell
# Navegue para o frontend e instale dependências (primeira vez)
cd simple_split_frontend
flutter pub get

# Execute o app Flutter na web (porta 8081)
flutter run -d web-server --web-port=8081
```

✅ **Frontend rodando em**: `http://localhost:8081`

### 🧪 4. Teste se Está Funcionando

**Teste a API:**
```bash
cd simple_split_backend
python test_backend.py
```

**Acesse pelo navegador:**
- API: `http://localhost:5000/api/health`
- App: `http://localhost:8081` (versão web)

### 🔧 Troubleshooting

**Problema comum - Porta ocupada:**
```bash
# Matar processo na porta 5000 (Windows)
netstat -ano | findstr :5000
taskkill /PID <PID_NUMBER> /F

# Linux/Mac
lsof -ti:5000 | xargs kill -9
```

**Flutter não encontrado:**
```bash
flutter doctor
# Siga as instruções para resolver problemas
```

## 👤 Usuários para Teste

O sistema já vem com usuários pré-cadastrados para você testar:

| Nome     | Email                | Senha       | 
|----------|---------------------|-------------|
| **Bia**    | bia@carnaval.com  | senha123 | 
| **Caio**     | caio@carnaval.com   | senha123 | 
| **Lucas**      | lucas@carnaval.com    | senha123 | 

### 🎮 Fluxo de Teste Sugerido

1. **Faça login como Lucas** → Veja títulos à venda no marketplace
2. **Teste o marketplace** → Venda e compre títulos
3. **Mude para Caio** → Veja carteira e histórico
4. **Teste como Bia** → Explore insights e análise de gastos

## 📱 Como Usar o App

### 🏠 Dashboard Principal
Menu inferior com 5 seções:

| Seção | O que faz |
|-------|-----------|
| **🏠 Início** | Resumo geral, grupos e carteira |
| **👥 Grupos** | Crie grupos, adicione despesas, veja dívidas |
| **🛒 Marketplace** | Compre/venda títulos de recebíveis |
| **📊 Insights** | Análise de gastos e alertas automáticos |
| **👤 Perfil** | Carteira, score, dados pessoais |

### 💡 Fluxo Típico de Uso

```
1. 👥 Criar Grupo
   ↓ Ex: "Viagem Bahia 2025"

2. 💰 Adicionar Despesas  
   ↓ Ex: "Hotel R$ 400" → divide entre 4 pessoas

3. 📊 Ver Quem Deve Para Quem
   ↓ Sistema calcula automaticamente

4. 💳 Pagar via Carteira
   ↓ Ou vender no marketplace com desconto

5. 🎯 Otimização Automática
   ↓ Sistema cancela dívidas cruzadas
```

### 🤖 Funcionalidades Inteligentes

**Otimização Automática:**
- Detecta dívidas circulares (A→B→C→A)
- Cancela automaticamente dívidas equivalentes
- Reduz número de transações necessárias

**Sistema de Score (0-10):**
- Pagamentos pontuais = +0.1 pontos
- Atrasos = -0.5 pontos  
- Score alto = mais confiança no marketplace

**Marketplace de Recebíveis:**
- Venda suas dívidas por dinheiro imediato
- Compre títulos com desconto
- Transferência automática de propriedade

## 🎯 Casos de Uso Reais

### 🏠 **República/Apartamento Compartilhado**
- Dividir aluguel, luz, internet, compras do mês
- Cada um paga sua parte automaticamente
- Sem "esqueci de pagar" ou cálculos manuais

### ✈️ **Viagens em Grupo** 
- Hotel, passagem, restaurantes, passeios
- Divisão justa mesmo com pessoas gastando diferentes valores
- Otimização automática: menos transferências bancárias

### 🍕 **Noitadas e Rolês**
- Dividir conta do bar, Uber, ingressos
- Cada um paga o que consumiu ou divide igualmente
- Pagamento via carteira digital na hora

### 💼 **Freelancers/Pequenas Empresas**
- Transformar recebíveis em dinheiro imediato
- Vender títulos com desconto para ter fluxo de caixa
- Sistema de confiabilidade via score


---

**The Simple Split** - Simplifique suas divisões financeiras! 💰✨
