---
sidebar_position: 2
slug: /escalabilidade/integracao-ecossistema
description: "Como o The Simple Split se integra e expande o ecossistema de produtos da QI Tech"
---

# Integração com Ecossistema QI Tech

## Visão de Produto no Ecossistema

### The Simple Split como Novo Produto B2C

O *The Simple Split* introduz uma frente **B2C** dentro do ecossistema da Qi Tech, expandindo sua atuação além das soluções tradicionais de infraestrutura financeira voltadas a empresas.  
O produto atua como uma plataforma de **gestão de micro-recebíveis entre pessoas físicas**, integrando-se de forma nativa às APIs da Qi Tech para KYC, pagamentos e custódia.

Essa abordagem amplia o alcance da Qi Tech, que passa a atender o público final através de um produto de consumo construído sobre sua própria infraestrutura.

### Complementaridade com Portfólio Existente

O *The Simple Split* complementa as soluções já oferecidas pela Qi Tech, agregando valor ao portfólio existente:

| Produto Qi Tech | Complemento pelo The Simple Split |
|------------------|-----------------------------------|
| KYC e Compliance | Utiliza diretamente o módulo de verificação de identidade. |
| BaaS | Processa todas as transações da carteira digital. |
| Custódia e Crédito | Gera micro-recebíveis formalizados dentro da infraestrutura Qi Tech. |
| Score de Crédito | Alimenta o sistema com novos dados comportamentais. |

### Sinergia com Clientes B2B da QI Tech

O sistema pode ser oferecido aos **clientes B2B da Qi Tech** como produto *white-label* ou **módulo de integração via API**, permitindo que empresas parceiras (bancos digitais, fintechs, aplicativos de mobilidade, delivery, etc.) incorporem funcionalidades de divisão de despesas e marketplace de recebíveis diretamente em suas plataformas.

---

## Módulos Reutilizáveis

### KYC e Onboarding

Integra-se com o módulo **KYC** da Qi Tech para verificação automática de identidade e prevenção à fraude.  
O processo de onboarding é totalmente digital e aproveita as políticas de compliance já implementadas pela infraestrutura da Qi Tech.

### Processamento de Pagamentos

Utiliza os serviços **BaaS** para liquidação de dívidas, pagamentos entre carteiras e compras no marketplace.  
As operações são executadas dentro do ambiente regulado da Qi Tech, garantindo rastreabilidade e segurança.

### Custódia de Recebíveis

Os títulos gerados entre usuários são formalizados como **recebíveis eletrônicos** sob custódia da Qi Tech.  
Essa etapa confere validade jurídica às transações peer-to-peer e garante a integridade dos créditos negociados.

### Score de Crédito

O módulo de **Score Dinâmico** do *The Simple Split* pode ser integrado ao sistema de crédito da Qi Tech como uma camada complementar, fornecendo **dados comportamentais alternativos** para enriquecer modelos de risco e análise de crédito.

### Antifraude

Com base na infraestrutura da Qi Tech, o sistema incorpora mecanismos de verificação de identidade, análise de padrões e monitoramento de comportamento atípico durante as transações financeiras.

---

## APIs e Integrações

### Consumo de APIs QI Tech

O *The Simple Split* consome diretamente as APIs REST da Qi Tech para:
- Criação e liquidação de títulos.  
- Execução de pagamentos via BaaS.  
- Autenticação de usuários via 2FA.  
- Validação de identidade com KYC.  

### Potencial de Exposição via API

Além do consumo, o sistema pode evoluir para oferecer suas **próprias APIs**, expondo módulos como:
- Logs automáticos de compensação.  
- Score comportamental de usuários.  
- Marketplace de micro-recebíveis (consultas, ordens e liquidação).  

Essas APIs podem ser disponibilizadas para parceiros do ecossistema da Qi Tech em modelo **Marketplace-as-a-Service**.

### Webhooks e Callbacks

As integrações suportam **webhooks** para atualização em tempo real de eventos críticos:
- Liquidação de dívidas.  
- Compra e venda de títulos.  
- Atualização de score.  
- Criação de logs automáticos.  

### SDKs e Libraries

O backend Python pode fornecer SDKs simplificados em múltiplas linguagens (Python, JavaScript, Kotlin) para que fintechs parceiras integrem rapidamente o *The Simple Split* às suas plataformas.

---

## Roadmap de Integração

### Fase 1: MVP Standalone

#### Integração básica (KYC, Pagamentos)
- Conecta-se apenas às APIs essenciais da Qi Tech para validação de identidade e liquidação de pagamentos.

#### Operação independente
- O produto funciona como aplicação autônoma, com banco de dados próprio e backend dedicado.

#### Prova de conceito
- Valida o modelo de marketplace de micro-recebíveis e a funcionalidade de logs automáticos.

### Fase 2: Integração Profunda

#### Custódia completa pela QI Tech
- Todos os títulos passam a ser formalizados e armazenados sob a infraestrutura regulada da Qi Tech.

#### Score integrado ao sistema QI Tech
- O score dinâmico se conecta ao sistema de crédito da Qi Tech, fornecendo dados comportamentais em tempo real.

#### Compartilhamento de dados (consentido)
- Os dados de uso são compartilhados de forma consentida, agregando valor analítico ao ecossistema Qi Tech.

#### White-label para parceiros
- O produto é disponibilizado como API white-label para fintechs, bancos digitais e plataformas de consumo.

### Fase 3: API para Clientes B2B

#### The Simple Split como API
- O sistema é convertido em um serviço modular, acessível via endpoints padronizados.

#### Fintechs e Bancos Digitais
- Parceiros podem integrar o módulo de marketplace e divisão de despesas em seus próprios aplicativos.

#### Embedded Finance
- O *The Simple Split* se torna um produto de **finanças embutidas**, operando sob a infraestrutura da Qi Tech.

#### Marketplace as a Service
- A Qi Tech passa a oferecer o marketplace como serviço de sua própria linha de produtos.

<p style={{textAlign: 'center'}}>Figura 1 - Roadmap de Integração do The Simple Split</p>

~~~mermaid
flowchart TD
    A[Fase 1: MVP Standalone] --> B[Fase 2: Integração Profunda]
    B --> C[Fase 3: API para Clientes B2B]
    A:::fase1 --> B:::fase2 --> C:::fase3

    classDef fase1 fill:#E3F2FD,stroke:#2196F3,stroke-width:1px;
    classDef fase2 fill:#BBDEFB,stroke:#1976D2,stroke-width:1px;
    classDef fase3 fill:#90CAF9,stroke:#0D47A1,stroke-width:1px;
~~~

<p style={{textAlign: 'center'}}>Fonte: Os autores (2025)</p>

---

## Oportunidades de Expansão

### White-Label para Bancos

Bancos digitais podem utilizar o *The Simple Split* como módulo de compartilhamento de despesas e marketplace de recebíveis, sob sua própria marca, aproveitando a licença e infraestrutura da Qi Tech.

### Parcerias com Fintechs

Fintechs de crédito e pagamentos podem incorporar a funcionalidade para gerar engajamento e novos fluxos de receita baseados em microtransações e antecipações sociais.

### Integração com ERPs

Empresas podem integrar o *The Simple Split* a sistemas de ERP, utilizando o motor de logs automáticos para otimizar compensações internas e gestão de fluxo de caixa.

### Plataformas de E-commerce

Marketplaces digitais podem permitir que consumidores dividam pagamentos e criem micro-recebíveis dentro do ambiente de checkout, adicionando liquidez e flexibilidade às compras coletivas.

---

## Valor para o Ecossistema QI Tech

### Novo Segmento de Mercado (B2C)

A Qi Tech amplia sua atuação ao atingir diretamente o público final, expandindo o uso da sua infraestrutura para consumo pessoal.

### Captação de Novos Usuários

O produto serve como porta de entrada para novos clientes que, futuramente, podem migrar para outras soluções da Qi Tech.

### Dados de Comportamento Financeiro

O *The Simple Split* gera dados de valor inédito — comportamento de pagamento entre pares, frequência de transações e padrões sociais de crédito.

### Cross-sell de Produtos QI Tech

A Qi Tech pode oferecer, a partir da base de usuários do *The Simple Split*, produtos adicionais como crédito pessoal, investimentos e cartões.

### Fortalecimento da Marca

Ao lançar um produto próprio, a Qi Tech reforça sua imagem como **provedora completa de infraestrutura financeira** e inovadora no segmento B2C.

---

## Diferenciais da Integração

### Compliance Nativo

Toda a operação segue os padrões regulatórios do Banco Central e da SCD da Qi Tech, eliminando barreiras jurídicas para operação em escala.

### Time-to-Market Reduzido

Aproveita APIs, processos e infraestrutura já existentes, acelerando o lançamento e reduzindo o tempo de desenvolvimento.

### Segurança Garantida

Transações e dados de usuários são processados sob protocolos da Qi Tech, com auditoria contínua e validação de integridade.

### Escalabilidade Automática

A arquitetura distribuída da Qi Tech garante que o crescimento do *The Simple Split* não exija modificações estruturais.

### Suporte Técnico QI Tech

O suporte técnico especializado da Qi Tech assegura estabilidade, manutenção contínua e evolução do produto com o restante do ecossistema.
