---
sidebar_position: 2
slug: /arquitetura/diagrama
description: "Visão macro da arquitetura do sistema The Simple Split"
---

# Diagrama de Arquitetura

## Visão Geral

A arquitetura do *The Simple Split* foi projetada para ser modular, escalável e integrada ao ecossistema financeiro da Qi Tech.  
Cada componente é responsável por uma camada específica — interface, lógica de negócio, persistência e integração — garantindo separação de responsabilidades e manutenibilidade do sistema.

### Componentes do Sistema

| Camada | Tecnologia | Função Principal |
|---------|-------------|------------------|
| Frontend | Flutter | Interface do usuário e lógica de interação. |
| Backend | Python (FastAPI) | Processamento de regras de negócio, autenticação e comunicação com a Qi Tech. |
| Banco de Dados | SQLite | Armazenamento local estruturado de usuários, grupos, dívidas e logs. |
| Integração Externa | APIs Qi Tech | Execução de operações financeiras reais (pagamentos, liquidações e KYC). |

<p style={{textAlign: 'center'}}>Fonte: Os autores (2025)</p>

### Camadas da Aplicação

O sistema adota uma **arquitetura em camadas**:

1. **Apresentação (Frontend)**: responsável pela interação com o usuário e visualização dos dados.  
2. **Serviços (Backend)**: executa regras de negócio e orquestra transações.  
3. **Persistência (Banco de Dados)**: gerencia dados locais e sincronizações.  
4. **Integração (APIs Qi Tech)**: garante a execução segura das operações financeiras.

---

## Diagrama de Alto Nível

<p style={{textAlign: 'center'}}>Figura 1 - Diagrama de Arquitetura de Alto Nível</p>

~~~mermaid
flowchart TD
    subgraph Cliente
        A[Aplicativo Flutter]
    end

    subgraph Servidor
        B[API Backend Python]
        C[SQLite Database]
    end

    subgraph Infraestrutura Qi Tech
        D[APIs Qi Tech - BaaS / SCD / DTVM]
    end

    A -->|Requisições HTTPS| B
    B -->|Consultas SQL| C
    B -->|Requisições REST| D
~~~

<p style={{textAlign: 'center'}}>Fonte: Os autores (2025)</p>

---

### Frontend (Flutter)

- Desenvolvido em **Flutter**, permitindo portabilidade para Android, iOS e Web.  
- Estruturado em componentes modulares com rotas independentes (Grupos, Marketplace, Carteira, Perfil).  
- Comunicação com o backend via **REST API** em HTTPS.  
- Armazena dados temporários com `SharedPreferences` para persistência leve e cache local.

### Backend (Python)

- Implementado em **FastAPI**, framework moderno e assíncrono em Python.  
- Gerencia autenticação, controle de usuários, grupos, logs e marketplace.  
- Processa requisições financeiras enviadas à Qi Tech e registra todas as transações no banco local.  
- Estrutura em microserviços para modularidade e escalabilidade.

### Banco de Dados (SQLite)

- Utilizado para armazenamento leve e de fácil integração.  
- Contém tabelas principais: `usuarios`, `grupos`, `despesas`, `dividas`, `logs`, `transacoes` e `titulos`.  
- Mantém sincronização com a Qi Tech para dados de liquidação e status de títulos.

### Integração QI Tech

- Comunicação via APIs REST autenticadas com **chaves privadas** fornecidas pela Qi Tech.  
- Uso de endpoints de **KYC**, **pagamentos**, **custódia** e **crédito**.  
- Cada operação gera um registro de auditoria e validação antes da confirmação de liquidação.  

---

## Fluxo de Comunicação

### Cliente → Backend

<p style={{textAlign: 'center'}}>Figura 2 - Fluxo Cliente → Backend</p>

~~~mermaid
flowchart TD
    A[Usuário realiza ação no app] --> B[Requisição HTTPS enviada ao Backend]
    B --> C[API valida autenticação JWT]
    C --> D[Executa regra de negócio e atualiza base local]
    D --> E[Retorna resposta JSON ao aplicativo]
~~~

<p style={{textAlign: 'center'}}>Fonte: Os autores (2025)</p>

### Backend → QI Tech APIs

<p style={{textAlign: 'center'}}>Figura 3 - Fluxo Backend → Qi Tech</p>

~~~mermaid
flowchart TD
    A[Backend Python] --> B[Envio de requisição via API Qi Tech]
    B --> C[Validação de credenciais e autenticação]
    C --> D[Processamento da operação financeira]
    D --> E[Resposta JSON com status e ID de transação]
~~~

<p style={{textAlign: 'center'}}>Fonte: Os autores (2025)</p>

### Backend → Banco de Dados

<p style={{textAlign: 'center'}}>Figura 4 - Fluxo Backend → Banco de Dados</p>

~~~mermaid
flowchart TD
    A[Serviço Backend] --> B[Consulta/Atualiza dados via ORM]
    B --> C[Persistência em tabelas SQLite]
    C --> D[Retorno de status de operação]
~~~

<p style={{textAlign: 'center'}}>Fonte: Os autores (2025)</p>

---

## Segurança

### Autenticação e Autorização

- Baseada em **JWT (JSON Web Tokens)** para autenticação sem estado.  
- Cada token contém informações de sessão e expira automaticamente após período definido.  
- Autorização por escopo de permissões: usuário, administrador e sistema.

### Criptografia de Dados

- Comunicação entre camadas via HTTPS (TLS 1.3).  
- Dados sensíveis (senhas e chaves) armazenados com **bcrypt** e **AES-256**.  
- Banco de dados encriptado localmente utilizando camada de segurança do SQLite.

### Tokens JWT

- Gerados no login e renovados periodicamente.  
- Incluem *claims* para identificação de usuário e tempo de expiração.  
- Assinatura com chave privada RSA mantida no servidor.

---

## Performance

### Cache

- Respostas de APIs frequentes são armazenadas em cache no lado do cliente.  
- Dados estáticos (ex: score, perfil) são atualizados apenas quando há mudanças.  
- O backend pode utilizar Redis em ambientes futuros para cache distribuído.

### Otimização de Consultas

- Índices aplicados às colunas mais consultadas (`usuario_id`, `grupo_id`, `status`).  
- Utilização de consultas parametrizadas e ORM assíncrono.  
- Compactação e otimização periódica do banco SQLite para manter desempenho.

### Processamento Assíncrono

- Operações de logs e cálculo de score executadas em tarefas assíncronas.  
- Uso de filas internas para processar eventos sem bloquear requisições de usuários.  
- Permite escalabilidade linear com aumento do volume de usuários e transações.

