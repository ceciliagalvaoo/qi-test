#!/bin/bash

# Script de criação da estrutura de documentação
# The Simple Split - Hackathon QI Tech 2025
# Estrutura otimizada: 5 pastas | 14 arquivos

echo "🚀 Criando estrutura de documentação do The Simple Split..."

# ============================================
# 01_Visao_Produto
# ============================================
mkdir -p 01_Visao_Produto

cat > 01_Visao_Produto/_category_.json << 'EOF'
{
  "label": "Visão do Produto",
  "position": 1,
  "link": {
    "type": "generated-index",
    "description": "Contextualização do problema, proposta de solução e diferenciais inovadores do The Simple Split."
  }
}
EOF

cat > 01_Visao_Produto/Problema_Solucao.md << 'EOF'
---
sidebar_position: 1
slug: /visao-produto/problema-solucao
description: "Contexto do problema de gestão de dívidas sociais e proposta de solução The Simple Split"
---

# Problema e Solução

## O Problema Real

### Cenário Comum

### Estatística Serasa (61%)

### Dor Identificada

### Impacto Social e Financeiro

## Nossa Solução

### O que é o The Simple Split

### Como Funciona

### Proposta de Valor

### Público-Alvo
EOF

cat > 01_Visao_Produto/Diferenciais.md << 'EOF'
---
sidebar_position: 2
slug: /visao-produto/diferenciais
description: "Diferenciais competitivos e inovações que tornam o The Simple Split único"
---

# Diferenciais e Inovação

## Por Que Somos Únicos

### Inovação 1: Sistema de Logs Automáticos

### Inovação 2: Marketplace de Recebíveis Sociais

### Inovação 3: Score Dinâmico

## Vantagens Competitivas

### Vs. Apps de Divisão de Contas Tradicionais

### Vs. Plataformas de Empréstimo P2P

## Novo Nicho para a QI Tech

### Expansão B2C

### Democratização de Recebíveis
EOF

# ============================================
# 02_Funcionalidades_Core
# ============================================
mkdir -p 02_Funcionalidades_Core

cat > 02_Funcionalidades_Core/_category_.json << 'EOF'
{
  "label": "Funcionalidades Core",
  "position": 2,
  "link": {
    "type": "generated-index",
    "description": "Detalhamento das funcionalidades principais, experiência do usuário e interface do aplicativo."
  }
}
EOF

cat > 02_Funcionalidades_Core/Sistema_Logs_Automaticos.md << 'EOF'
---
sidebar_position: 1
slug: /funcionalidades/logs-automaticos
description: "Sistema inteligente de logs para anulação automática de dívidas entre usuários e grupos"
---

# Sistema de Logs Automáticos

## Conceito

### O que são os Logs Automáticos

### Objetivo da Funcionalidade

## Como Funciona

### Exemplo Prático: Uber do Pablo

### Compensação Entre Grupos

### Compensação Circular (A→B→C→A)

## Algoritmo de Anulação

### Lógica de Cruzamento

### Processamento

### Notificações ao Usuário

## Benefícios

### Para o Usuário

### Para o Ecossistema

## Casos de Uso

### Caso 1: Dívidas no Mesmo Grupo

### Caso 2: Dívidas Entre Grupos Diferentes

### Caso 3: Circularidade Complexa
EOF

cat > 02_Funcionalidades_Core/Marketplace_Recebiveis.md << 'EOF'
---
sidebar_position: 2
slug: /funcionalidades/marketplace-recebiveis
description: "Marketplace de micro-recebíveis sociais peer-to-peer com anonimização"
---

# Marketplace de Recebíveis Sociais

## Conceito do Marketplace

### O que são Micro-Recebíveis Sociais

### Novo Nicho de Mercado

### Por que é Inovador

## Como Funciona

### Fluxo de Venda de Recebível

### Fluxo de Compra de Recebível

### Exemplo Prático: Cecília (R$40 → R$35)

## Mecânica de Negociação

### Precificação

### Anonimização

### Uso do Score na Decisão

### Formalização pela QI Tech

## Limites de Valores

### Micro-Recebíveis (R$10 - R$500)

### Justificativa dos Limites

### Viabilidade Econômica

## Segurança e Custódia

### Papel da QI Tech

### Garantias ao Comprador

### Garantias ao Vendedor

## Casos de Uso

### Caso 1: Urgência Financeira

### Caso 2: Diversificação de Recebíveis

### Caso 3: Lucro com Score Alto
EOF

cat > 02_Funcionalidades_Core/Score_Dinamico.md << 'EOF'
---
sidebar_position: 3
slug: /funcionalidades/score-dinamico
description: "Sistema de score dinâmico para avaliação de risco e reputação no marketplace"
---

# Score Dinâmico

## O que é o Score

### Definição (0 a 10)

### Objetivo

### Importância no Marketplace

## Como é Calculado

### Fatores Positivos

### Fatores Negativos

### Peso dos Critérios

### Fórmula Simplificada

## Dinâmica do Score

### Como o Score Sobe

### Como o Score Cai

### Exemplos de Movimentação

## Uso no Marketplace

### Confiança na Negociação

### Precificação Baseada em Risco

### Anonimato + Score

## Incentivos e Penalidades

### Recompensas para Bons Pagadores

### Consequências da Inadimplência

### Recuperação de Score

## Mitigação de Risco

### Para a QI Tech

### Para os Usuários

### Para o Ecossistema
EOF

cat > 02_Funcionalidades_Core/Carteira_Digital.md << 'EOF'
---
sidebar_position: 4
slug: /funcionalidades/carteira-digital
description: "Carteira digital integrada para pagamentos e recebimentos dentro do app"
---

# Carteira Digital

## Visão Geral

### Funcionalidades da Carteira

### Integração com Sistema de Dívidas

## Operações

### Inserção de Saldo

### Pagamentos

### Recebimentos

### Transferências

## Integração com QI Tech

### BaaS (Banking as a Service)

### Processamento de Transações

### Segurança das Operações

## Gestão Financeira

### A Receber (Dívidas + Títulos Comprados)

### A Pagar

### Histórico de Movimentações

## Fluxos de Pagamento

### Pagamento de Dívida via Carteira

### Recebimento de Título do Marketplace

### Quitação Automática
EOF

cat > 02_Funcionalidades_Core/Jornada_Interface.md << 'EOF'
---
sidebar_position: 5
slug: /funcionalidades/jornada-interface
description: "Jornada completa do usuário e wireframes das principais telas do aplicativo"
---

# Jornada do Usuário e Interface

## Design System

### Estilo Minimalista Apple

### Paleta de Cores

### Tipografia

### Componentes

## Fluxo de Onboarding

### Tela 1: Autenticação

### Criação de Conta

### Verificação 2FA

### Primeiro Acesso

## Dashboard Principal

### Visão Geral

### Menu Inferior (5 abas)

### Navegação

## Telas Principais

### Aba: Grupos

#### Criação de Grupo

#### Visualização de Grupo

#### Registro de Despesas

#### Visualização de Dívidas

#### Logs Automáticos

### Aba: Contatos

#### Lista de Contatos

#### Score Visível

#### Anúncios de Recebíveis

### Aba: Insights

#### Notificações Inteligentes

#### Alertas de Pagamento

#### Logs Recentes

### Aba: Marketplace

#### Listagem de Títulos

#### Detalhes do Título

#### Compra de Recebível

#### Anonimização

### Aba: Usuário (Perfil)

#### Nome e Score

#### Carteira Digital

#### A Receber

#### A Pagar

#### Histórico

## Fluxos de Interação

### Fluxo 1: Criar Grupo e Registrar Despesa

### Fluxo 2: Visualizar Log Automático

### Fluxo 3: Vender Recebível no Marketplace

### Fluxo 4: Comprar Título no Marketplace

### Fluxo 5: Pagamento via Carteira

### Fluxo 6: Acompanhar Score

## Wireframes

### Autenticação

### Dashboard

### Grupos

### Marketplace

### Perfil

## Princípios de UX

### Clareza

### Simplicidade

### Transparência

### Feedback Visual
EOF

# ============================================
# 03_Arquitetura_Tecnica
# ============================================
mkdir -p 03_Arquitetura_Tecnica

cat > 03_Arquitetura_Tecnica/_category_.json << 'EOF'
{
  "label": "Arquitetura Técnica",
  "position": 3,
  "link": {
    "type": "generated-index",
    "description": "Stack tecnológico, integração com APIs da QI Tech, banco de dados e diagramas de arquitetura."
  }
}
EOF

cat > 03_Arquitetura_Tecnica/Stack_Integracao_QITech.md << 'EOF'
---
sidebar_position: 1
slug: /arquitetura/stack-integracao
description: "Stack tecnológico e integração com infraestrutura da QI Tech"
---

# Stack e Integração com QI Tech

## Stack Tecnológico

### Frontend: Flutter

### Backend: Python

### Banco de Dados: SQLite

### Justificativas das Escolhas

## Integração com QI Tech

### APIs Utilizadas

### KYC (Know Your Customer)

### Processamento de Pagamentos (BaaS)

### Custódia de Recebíveis

### Autenticação 2FA

## Fluxo de Integração

### Onboarding do Usuário

### Criação de Títulos

### Transações Financeiras

### Marketplace

## Arquitetura de Comunicação

### REST API

### Formato de Dados (JSON)

### Segurança (HTTPS/TLS)

### Rate Limiting

## Benefícios da Integração

### Redução de Complexidade

### Compliance Garantido

### Escalabilidade Nativa

### Time-to-Market Acelerado
EOF

cat > 03_Arquitetura_Tecnica/Banco_Dados_API.md << 'EOF'
---
sidebar_position: 2
slug: /arquitetura/banco-api
description: "Modelagem do banco de dados SQLite e documentação dos endpoints da API"
---

# Banco de Dados e API

## Modelagem do Banco de Dados

### Diagrama Entidade-Relacionamento

### Tabelas Principais

#### Usuários

#### Grupos

#### Despesas

#### Dívidas

#### Títulos (Recebíveis)

#### Transações

#### Logs

### Relacionamentos

### Índices e Performance

### Dados de Seed (Pablo, Cecília, Mariana)

## Endpoints da API Backend

### Autenticação

#### POST /auth/register

#### POST /auth/login

#### POST /auth/2fa/verify

### Usuários

#### GET /users/me

#### GET /users/{id}/score

#### PATCH /users/me

### Grupos

#### GET /groups

#### POST /groups

#### GET /groups/{id}

#### POST /groups/{id}/members

#### POST /groups/{id}/expenses

### Despesas e Dívidas

#### GET /debts

#### GET /debts/receivable

#### GET /debts/payable

#### POST /debts/{id}/pay

### Marketplace

#### GET /marketplace/listings

#### POST /marketplace/list

#### POST /marketplace/buy/{id}

### Carteira

#### GET /wallet/balance

#### POST /wallet/deposit

#### POST /wallet/transfer

### Logs

#### GET /logs

#### GET /logs/auto-cancelled

## Fluxo de Dados

### Ciclo de Vida de uma Dívida

### Processamento de Logs Automáticos

### Negociação no Marketplace
EOF

cat > 03_Arquitetura_Tecnica/Diagrama_Arquitetura.md << 'EOF'
---
sidebar_position: 3
slug: /arquitetura/diagrama
description: "Visão macro da arquitetura do sistema The Simple Split"
---

# Diagrama de Arquitetura

## Visão Geral

### Componentes do Sistema

### Camadas da Aplicação

## Diagrama de Alto Nível

### Frontend (Flutter)

### Backend (Python)

### Banco de Dados (SQLite)

### Integração QI Tech

## Fluxo de Comunicação

### Cliente → Backend

### Backend → QI Tech APIs

### Backend → Banco de Dados

## Segurança

### Autenticação e Autorização

### Criptografia de Dados

### Tokens JWT

## Performance

### Cache

### Otimização de Consultas

### Processamento Assíncrono
EOF

# ============================================
# 04_Escalabilidade_Integracao
# ============================================
mkdir -p 04_Escalabilidade_Integracao

cat > 04_Escalabilidade_Integracao/_category_.json << 'EOF'
{
  "label": "Escalabilidade e Integração",
  "position": 4,
  "link": {
    "type": "generated-index",
    "description": "Estratégias de escalabilidade e integração profunda com o ecossistema da QI Tech."
  }
}
EOF

cat > 04_Escalabilidade_Integracao/Escalabilidade_Infraestrutura.md << 'EOF'
---
sidebar_position: 1
slug: /escalabilidade/infraestrutura
description: "Estratégias de escalabilidade técnica aproveitando a infraestrutura da QI Tech"
---

# Escalabilidade da Infraestrutura

## Aproveitamento da Infraestrutura QI Tech

### Cloud Infrastructure

### Serviços Gerenciados

### CDN e Edge Computing

### Redundância e Alta Disponibilidade

## Arquitetura Escalável

### Microsserviços

### Separação de Concerns

### Event-Driven Architecture

### Message Queues

## Processamento Assíncrono

### Cálculo de Logs em Background

### Atualização de Score

### Notificações Push

### Jobs Agendados

## Performance e Otimização

### Cache Distribuído

### Database Indexing

### Query Optimization

### Load Balancing

## Crescimento de Usuários

### Onboarding em Escala

### Gestão de Milhões de Transações

### Marketplace com Alto Volume

### Monitoramento e Métricas

## Custos Operacionais

### Modelo de Pricing

### Otimização de Recursos

### Auto-scaling

### Pay-as-you-grow

## Projeção de Crescimento

### Fase 1: MVP (1k usuários)

### Fase 2: Early Adoption (10k usuários)

### Fase 3: Growth (100k usuários)

### Fase 4: Scale (1M+ usuários)
EOF

cat > 04_Escalabilidade_Integracao/Integracao_Ecossistema_QITech.md << 'EOF'
---
sidebar_position: 2
slug: /escalabilidade/integracao-ecossistema
description: "Como o The Simple Split se integra e expande o ecossistema de produtos da QI Tech"
---

# Integração com Ecossistema QI Tech

## Visão de Produto no Ecossistema

### The Simple Split como Novo Produto B2C

### Complementaridade com Portfólio Existente

### Sinergia com Clientes B2B da QI Tech

## Módulos Reutilizáveis

### KYC e Onboarding

### Processamento de Pagamentos

### Custódia de Recebíveis

### Score de Crédito

### Antifraude

## APIs e Integrações

### Consumo de APIs QI Tech

### Potencial de Exposição via API

### Webhooks e Callbacks

### SDKs e Libraries

## Roadmap de Integração

### Fase 1: MVP Standalone

#### Integração básica (KYC, Pagamentos)

#### Operação independente

#### Prova de conceito

### Fase 2: Integração Profunda

#### Custódia completa pela QI Tech

#### Score integrado ao sistema QI Tech

#### Compartilhamento de dados (consentido)

#### White-label para parceiros

### Fase 3: API para Clientes B2B

#### The Simple Split como API

#### Fintechs e Bancos Digitais

#### Embedded Finance

#### Marketplace as a Service

## Oportunidades de Expansão

### White-Label para Bancos

### Parcerias com Fintechs

### Integração com ERPs

### Plataformas de E-commerce

## Valor para o Ecossistema QI Tech

### Novo Segmento de Mercado (B2C)

### Captação de Novos Usuários

### Dados de Comportamento Financeiro

### Cross-sell de Produtos QI Tech

### Fortalecimento da Marca

## Diferenciais da Integração

### Compliance Nativo

### Time-to-Market Reduzido

### Segurança Garantida

### Escalabilidade Automática

### Suporte Técnico QI Tech
EOF

# ============================================
# 05_Modelo_Negocio
# ============================================
mkdir -p 05_Modelo_Negocio

cat > 05_Modelo_Negocio/_category_.json << 'EOF'
{
  "label": "Modelo de Negócio",
  "position": 5,
  "link": {
    "type": "generated-index",
    "description": "Proposta de valor para a QI Tech, enquadramento regulatório e análise de viabilidade."
  }
}
EOF

cat > 05_Modelo_Negocio/Proposta_Valor_QITech.md << 'EOF'
---
sidebar_position: 1
slug: /modelo-negocio/proposta-valor
description: "Proposta de valor do The Simple Split como novo produto B2C da QI Tech"
---

# Proposta de Valor para QI Tech

## Por Que The Simple Split

### Novo Nicho de Mercado

### Expansão B2C

### Democratização de Recebíveis

## Valor Agregado

### Para a QI Tech

### Para os Usuários Finais

### Para o Ecossistema Fintech

## Canvas de Proposta de Valor

### Segmento de Clientes

### Proposta de Valor

### Canais

### Relacionamento com Clientes

### Fontes de Receita

### Recursos Principais

### Atividades-Chave

### Parcerias Principais

### Estrutura de Custos

## Diferenciais Competitivos

### Vs. Soluções Existentes

### Barreiras de Entrada

## Oportunidades de Crescimento

### Roadmap de Expansão

### Potencial de Mercado

### API para Clientes (Fase 3)

## Impacto Estratégico

### Posicionamento de Marca

### Captação de Novos Segmentos

### Dados e Insights

### Receitas Recorrentes
EOF

cat > 05_Modelo_Negocio/Regulamentacao_Viabilidade.md << 'EOF'
---
sidebar_position: 2
slug: /modelo-negocio/regulamentacao-viabilidade
description: "Enquadramento regulatório sob licença SCD e análise de viabilidade técnica/econômica"
---

# Regulamentação e Viabilidade

## Enquadramento Regulatório

### Licença SCD da QI Tech

### Papel da QI Tech

### Formalização de Títulos

### Custódia de Recebíveis

### Compliance BACEN

## Marketplace de Recebíveis

### Legalidade da Operação

### Cessão de Crédito

### Anonimização e Privacidade

### LGPD

## KYC e Antifraude

### Know Your Customer

### Prevenção à Lavagem de Dinheiro

### Infraestrutura QI Tech

## Viabilidade Técnica

### Escalabilidade da Infraestrutura

### Processamento de Micro-Transações

### Aproveitamento da Stack QI Tech

### Custos Operacionais

## Viabilidade Econômica

### Limites de Valores (R$10 - R$500)

### Justificativa dos Micro-Recebíveis

### Modelo de Receita

### Sustentabilidade Financeira

## Riscos e Mitigações

### Risco de Crédito

### Risco Operacional

### Risco Regulatório

### Estratégias de Mitigação

## Projeção de Crescimento

### Adoção Inicial

### Crescimento Orgânico

### Expansão de Funcionalidades

### Break-even Point
EOF

echo ""
echo "✅ Estrutura criada com sucesso!"
echo ""
echo "📂 Estrutura de pastas:"
echo ""
echo "   01_Visao_Produto/ (2 arquivos)"
echo "      ├─ Problema_Solucao.md"
echo "      └─ Diferenciais.md"
echo ""
echo "   02_Funcionalidades_Core/ (5 arquivos)"
echo "      ├─ Sistema_Logs_Automaticos.md"
echo "      ├─ Marketplace_Recebiveis.md"
echo "      ├─ Score_Dinamico.md"
echo "      ├─ Carteira_Digital.md"
echo "      └─ Jornada_Interface.md"
echo ""
echo "   03_Arquitetura_Tecnica/ (3 arquivos)"
echo "      ├─ Stack_Integracao_QITech.md"
echo "      ├─ Banco_Dados_API.md"
echo "      └─ Diagrama_Arquitetura.md"
echo ""
echo "   04_Escalabilidade_Integracao/ (2 arquivos)"
echo "      ├─ Escalabilidade_Infraestrutura.md"
echo "      └─ Integracao_Ecossistema_QITech.md"
echo ""
echo "   05_Modelo_Negocio/ (2 arquivos)"
echo "      ├─ Proposta_Valor_QITech.md"
echo "      └─ Regulamentacao_Viabilidade.md"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Total: 5 pastas | 14 arquivos"
echo "📋 Estrutura alinhada ao pitch do hackathon"
echo "🎯 Pronto para documentar no Docusaurus!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"