---
sidebar_position: 1
slug: /arquitetura/stack-integracao
description: "Stack tecnológico e integração com infraestrutura da QI Tech"
---

# Stack e Integração com QI Tech

## Stack Tecnológico

A arquitetura do *The Simple Split* foi projetada para aproveitar tecnologias leves, multiplataforma e de alta compatibilidade com APIs financeiras.  
O objetivo é garantir desempenho, simplicidade de manutenção e integração nativa com a infraestrutura da Qi Tech.

### Frontend: Flutter

- Framework de interface multiplataforma (Android, iOS e Web).  
- Permite consistência visual entre dispositivos, com desempenho nativo.  
- Facilita o desenvolvimento rápido de protótipos e MVPs.  
- Utiliza o padrão de gerenciamento de estado **Provider** e rotas dinâmicas para navegação.

### Backend: Python

- Construído com **FastAPI**, framework leve e assíncrono.  
- Facilita a criação de endpoints REST e integração com APIs externas.  
- Suporte nativo a tipagem estática e documentação automática via OpenAPI.  
- Escalável horizontalmente e compatível com containers Docker para ambientes em nuvem.

### Banco de Dados: SQLite

- Banco de dados local, leve e relacional.  
- Ideal para protótipos e ambientes de demonstração (hackathon/MVP).  
- Estrutura simples e integrável diretamente ao backend Python.  
- Permite migração futura para PostgreSQL ou MySQL sem grandes alterações de schema.

### Justificativas das Escolhas

| Camada | Tecnologia | Justificativa |
|---------|-------------|---------------|
| Frontend | Flutter | Alta produtividade e consistência visual multiplataforma. |
| Backend | Python (FastAPI) | Agilidade no desenvolvimento e integração assíncrona com APIs externas. |
| Banco de Dados | SQLite | Simplicidade e baixo overhead para MVPs, com opção de migração futura. |

<p style={{textAlign: 'center'}}>Fonte: Os autores (2025)</p>

---

## Integração com QI Tech

A Qi Tech fornece a base regulatória e tecnológica para que o *The Simple Split* opere de forma segura e conforme às normas do Banco Central.  
Sua infraestrutura cobre **onboarding de usuários, transações financeiras, custódia e compliance regulatório**.

### APIs Utilizadas

| API Qi Tech | Função |
|--------------|--------|
| KYC | Identificação e verificação de usuários. |
| BaaS | Processamento de pagamentos e liquidações. |
| Custódia | Registro e guarda dos títulos negociados. |
| Autenticação 2FA | Validação segura das operações críticas. |

### KYC (Know Your Customer)

Durante o cadastro, o aplicativo utiliza a API de **KYC** da Qi Tech para validar identidade, CPF, e dados bancários do usuário.  
Essa integração elimina a necessidade de criar sistemas próprios de verificação, garantindo conformidade com normas de prevenção à lavagem de dinheiro (PLD).

### Processamento de Pagamentos (BaaS)

O módulo **Banking as a Service (BaaS)** da Qi Tech processa todas as transações financeiras internas, incluindo:  
- Pagamentos de dívidas entre usuários.  
- Transferências entre carteiras.  
- Liquidação de títulos no marketplace.  
Cada operação gera um ID de transação único, rastreável e auditável.

### Custódia de Recebíveis

Os títulos de crédito gerados dentro do aplicativo são formalizados e custodiados pela Qi Tech.  
Essa etapa garante que cada micro-recebível tenha validade jurídica e possa ser liquidado com segurança, mesmo entre pessoas físicas.

### Autenticação 2FA

A autenticação de duas etapas é implementada utilizando o serviço de 2FA da Qi Tech.  
Usuários recebem um código via e-mail ou SMS para confirmar transações críticas, como:
- Criação de título de crédito.  
- Venda de recebível.  
- Pagamento de valores elevados.  

---

## Fluxo de Integração

### Onboarding do Usuário

<p style={{textAlign: 'center'}}>Figura 1 - Fluxo de Onboarding com Integração Qi Tech</p>

~~~mermaid
flowchart TD
    A[Usuário cria conta no app] --> B[Envio de dados para API KYC da Qi Tech]
    B --> C[Validação de identidade e documentos]
    C --> D[Criação de conta de pagamento Qi Tech]
    D --> E[Usuário pronto para operar na plataforma]
~~~

<p style={{textAlign: 'center'}}>Fonte: Os autores (2025)</p>

### Criação de Títulos

<p style={{textAlign: 'center'}}>Figura 2 - Fluxo de Criação de Título de Crédito</p>

~~~mermaid
flowchart TD
    A[Usuário registra dívida] --> B[Backend formaliza título via API Qi Tech]
    B --> C[Qi Tech gera identificador e registra o crédito]
    C --> D[Título é custodiado e disponível para marketplace]
~~~

<p style={{textAlign: 'center'}}>Fonte: Os autores (2025)</p>

### Transações Financeiras

<p style={{textAlign: 'center'}}>Figura 3 - Fluxo de Transações Financeiras</p>

~~~mermaid
flowchart TD
    A[Usuário realiza pagamento ou compra de título] --> B[Backend envia requisição BaaS]
    B --> C[Qi Tech processa liquidação]
    C --> D[Atualização de carteiras e registros locais]
~~~

<p style={{textAlign: 'center'}}>Fonte: Os autores (2025)</p>

### Marketplace

<p style={{textAlign: 'center'}}>Figura 4 - Fluxo de Operações no Marketplace</p>

~~~mermaid
flowchart TD
    A[Usuário publica título para venda] --> B[Qi Tech valida formalização]
    B --> C[Outro usuário compra título via carteira]
    C --> D[Qi Tech transfere titularidade e liquida valor]
    D --> E[Atualização do histórico de ambos usuários]
~~~

<p style={{textAlign: 'center'}}>Fonte: Os autores (2025)</p>

---

## Arquitetura de Comunicação

### REST API

- Comunicação entre app e backend via **HTTP/HTTPS**.  
- Estrutura baseada em endpoints REST padronizados (`/usuarios`, `/grupos`, `/titulos`, `/pagamentos`).  
- Suporte a métodos **GET**, **POST**, **PUT**, e **DELETE**.

### Formato de Dados (JSON)

- Todas as requisições e respostas seguem formato **JSON**.  
- Chaves padronizadas e documentação gerada automaticamente pela FastAPI.  
- Erros retornados em formato estruturado com códigos HTTP (`400`, `401`, `404`, `500`).

### Segurança (HTTPS/TLS)

- Comunicação criptografada com **TLS 1.3**.  
- Tokens JWT assinados com chave RSA para autenticação de usuários.  
- Restrições de escopo por endpoint, prevenindo acesso indevido.  

### Rate Limiting

- Implementação de **limite de requisições por IP e token**.  
- Evita abuso de endpoints e protege a infraestrutura da Qi Tech contra sobrecarga.  
- Configuração ajustável conforme o ambiente (desenvolvimento ou produção).  

---

## Benefícios da Integração

### Redução de Complexidade

O aplicativo delega à Qi Tech toda a infraestrutura regulatória, permitindo foco total no desenvolvimento da experiência de usuário.

### Compliance Garantido

A operação utiliza diretamente os serviços de uma instituição regulamentada pelo Banco Central, garantindo aderência a normas de KYC, PLD e custódia de ativos.

### Escalabilidade Nativa

A integração com as APIs da Qi Tech permite expansão automática conforme a base de usuários cresce, sem necessidade de alterar a estrutura de backend.

### Time-to-Market Acelerado

Ao reutilizar a infraestrutura existente da Qi Tech, o *The Simple Split* reduz drasticamente o tempo de desenvolvimento, podendo ser implantado rapidamente em produção com segurança e conformidade garantidas.

