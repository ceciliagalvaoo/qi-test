---
sidebar_position: 2
slug: /modelo-negocio/regulamentacao-viabilidade
description: "Enquadramento regulatório sob licença SCD e análise de viabilidade técnica/econômica"
---

# Regulamentação e Viabilidade

## Enquadramento Regulatório

A operação do *The Simple Split* é viabilizada pela **licença de Sociedade de Crédito Direto (SCD)** da Qi Tech, que permite a originação, custódia e cessão de créditos de forma 100% digital e regulamentada pelo Banco Central do Brasil.

### Licença SCD da QI Tech

A licença SCD autoriza a Qi Tech a:
- Conceder crédito com recursos próprios.  
- Ceder créditos originados a terceiros.  
- Formalizar e custodiar recebíveis eletrônicos.  
- Processar pagamentos via contas de pagamento.  

Essa estrutura legal elimina a necessidade de o *The Simple Split* obter licenças próprias, permitindo sua operação sob o guarda-chuva regulatório da Qi Tech.

### Papel da QI Tech

A Qi Tech atua como **entidade custodiante e liquidante** de todas as transações financeiras.  
O aplicativo funciona como camada de interface e lógica de negócio, enquanto:
- A Qi Tech formaliza os títulos.  
- Registra as cessões de crédito.  
- Garante a liquidação e a custódia dos valores.  

### Formalização de Títulos

Cada dívida registrada no *The Simple Split* é formalizada como um **título de crédito eletrônico** através das APIs da Qi Tech.  
Esse título representa juridicamente o direito de recebimento e pode ser transferido entre usuários no marketplace.

### Custódia de Recebíveis

A custódia é feita de forma automatizada pela Qi Tech, que mantém o controle sobre:
- Origem e histórico da dívida.  
- Transferências e cessões de crédito.  
- Liquidação final entre comprador e vendedor.  

### Compliance BACEN

Todas as operações seguem as **normas do Banco Central**, incluindo:
- Circular nº 3.895/2018 (SCD).  
- Resolução CMN nº 4.656/2018.  
- Regras de PLD/FT (Prevenção à Lavagem de Dinheiro e Financiamento do Terrorismo).  

---

## Marketplace de Recebíveis

### Legalidade da Operação

O marketplace é estruturado sob o modelo de **cessão de crédito regulamentada**, onde um credor (usuário vendedor) transfere seu direito creditório a outro (comprador).  
A Qi Tech atua como intermediadora, garantindo a validade jurídica e operacional da transação.

### Cessão de Crédito

As operações de cessão são registradas digitalmente, conforme o artigo 286 do Código Civil, assegurando a transferência legal do crédito e seu reconhecimento pela Qi Tech como entidade custodiante.

### Anonimização e Privacidade

O marketplace opera de forma **anonimizada**, preservando as identidades dos participantes.  
As informações de perfil são substituídas por identificadores criptografados e pelo **score dinâmico**.

### LGPD

O tratamento de dados segue as diretrizes da **Lei Geral de Proteção de Dados (LGPD)**:
- Coleta mínima e consentida.  
- Finalidade específica e legítima.  
- Direito de exclusão e portabilidade de dados.  
- Armazenamento seguro sob infraestrutura Qi Tech.  

---

## KYC e Antifraude

### Know Your Customer

Durante o onboarding, a Qi Tech executa os procedimentos de **KYC (Know Your Customer)**, validando:
- Identidade e CPF.  
- Endereço e dados bancários.  
- Risco de fraude e histórico financeiro.  

### Prevenção à Lavagem de Dinheiro

As transações são analisadas conforme políticas de **PLD/FT**, utilizando ferramentas de monitoramento e detecção de padrões suspeitos.

### Infraestrutura QI Tech

O *The Simple Split* se integra aos sistemas antifraude da Qi Tech, que contam com:
- Cross-check de identidade em bases públicas e privadas.  
- Monitoramento contínuo de transações.  
- Alertas automáticos para comportamentos fora do padrão.  

---

## Viabilidade Técnica

### Escalabilidade da Infraestrutura

A infraestrutura da Qi Tech é projetada para lidar com milhões de transações simultâneas, garantindo elasticidade e alta disponibilidade para o *The Simple Split* desde o MVP até o crescimento em escala.

### Processamento de Micro-Transações

A infraestrutura de **BaaS da Qi Tech** torna economicamente viável o processamento de microtransações (R$10–R$500), com custos reduzidos por operação e liquidação automática.

### Aproveitamento da Stack QI Tech

O aplicativo utiliza integralmente a **stack de APIs** da Qi Tech para:
- KYC e autenticação 2FA.  
- Liquidação de pagamentos.  
- Formalização e custódia de títulos.  

Essa abordagem reduz drasticamente o tempo de desenvolvimento e os custos de manutenção técnica.

### Custos Operacionais

Como a Qi Tech provê toda a infraestrutura de backend regulado, os custos operacionais do *The Simple Split* são limitados a:
- Hospedagem do frontend e backend de aplicação.  
- Suporte e manutenção de integração.  
- Custos marginais por uso de API.

---

## Viabilidade Econômica

### Limites de Valores (R$10 - R$500)

O marketplace é voltado para **micro-recebíveis** entre R$10,00 e R$500,00, valores que representam a faixa de transações mais comuns em contextos sociais.

### Justificativa dos Micro-Recebíveis

- Esses valores são frequentemente informais e sem registro.  
- A estrutura da Qi Tech permite formalizá-los com custo marginal mínimo.  
- Criam um novo mercado para originação e negociação de crédito social.

### Modelo de Receita

O modelo de receita é baseado em:
- **Taxa de intermediação** sobre cada transação de compra e venda de títulos.  
- **Spread percentual** entre valor nominal e valor de venda.  
- **Licenciamento white-label** para empresas que queiram adotar o produto.

### Sustentabilidade Financeira

A sustentabilidade é garantida pela:
- Baixa estrutura de custos fixos.  
- Alta escalabilidade operacional.  
- Natureza digital das operações (sem intervenção manual).  

---

## Riscos e Mitigações

### Risco de Crédito

**Risco:** Inadimplência do devedor original.  
**Mitigação:** Uso do score dinâmico e histórico de comportamento; precificação ajustada pelo risco percebido.

### Risco Operacional

**Risco:** Falhas em integrações ou processamento.  
**Mitigação:** Redundância de APIs e monitoramento contínuo via Qi Tech; logs de auditoria automatizados.

### Risco Regulatório

**Risco:** Mudanças nas normas do BACEN sobre cessão de crédito.  
**Mitigação:** Operação 100% enquadrada na licença SCD; acompanhamento jurídico constante pela equipe de compliance da Qi Tech.

### Estratégias de Mitigação

| Tipo de Risco | Estratégia |
|----------------|-------------|
| Crédito | Score dinâmico e histórico de adimplência. |
| Operacional | Redundância e automação de processos. |
| Regulatório | Supervisão contínua e adequação normativa. |

<p style={{textAlign: 'center'}}>Fonte: Os autores (2025)</p>

---

## Projeção de Crescimento

### Adoção Inicial

Fase de validação do produto com público restrito, utilizando a infraestrutura Qi Tech para garantir estabilidade e confiabilidade desde o início.

### Crescimento Orgânico

Expansão gradual por recomendação entre usuários e parcerias com fintechs e bancos digitais.

### Expansão de Funcionalidades

- Introdução de novos tipos de títulos (ex: recorrentes).  
- Integração com produtos de crédito da Qi Tech.  
- APIs públicas para parceiros B2B.

### Break-even Point

Previsto para a **Fase 3 (API para Clientes B2B)**, quando o produto atinge volume transacional suficiente para cobrir custos operacionais e gerar receita recorrente.
