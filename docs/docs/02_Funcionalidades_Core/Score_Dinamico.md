---
sidebar_position: 3
slug: /funcionalidades/score-dinamico
description: "Sistema de score dinâmico para avaliação de risco e reputação no marketplace"
---

# Score Dinâmico

## O que é o Score

O **Score Dinâmico** é o sistema de reputação e avaliação de risco utilizado pelo *The Simple Split*.  
Ele atribui a cada usuário uma nota entre **0 e 10**, atualizada automaticamente conforme o comportamento financeiro dentro da plataforma.

### Definição (0 a 10)

O valor do score representa a probabilidade de um usuário cumprir seus compromissos financeiros.  
- **Score alto (8 a 10)** indica comportamento confiável e pagamentos em dia.  
- **Score médio (5 a 7)** representa histórico misto, com alguns atrasos.  
- **Score baixo (0 a 4)** indica risco elevado de inadimplência.  

### Objetivo

O objetivo do sistema é **promover confiança** nas interações financeiras peer-to-peer, reduzindo riscos e incentivando boas práticas de pagamento.

### Importância no Marketplace

O score é um dos elementos centrais do **Marketplace de Recebíveis Sociais**, pois:
- Influencia o preço de venda dos títulos.  
- Afeta a atratividade de cada recebível para os compradores.  
- Substitui a necessidade de análise manual de crédito.  

---

## Como é Calculado

O cálculo do score é realizado de forma automatizada, combinando indicadores de comportamento, frequência de uso e confiabilidade nas transações.

### Fatores Positivos

| Fator | Descrição | Impacto |
|--------|------------|---------|
| Pagamentos em dia | Cumprimento dos prazos acordados | +0.5 a +1.0 |
| Quitações automáticas por logs | Participação em fluxos equilibrados | +0.3 |
| Volume de transações bem-sucedidas | Alta recorrência de operações sem falhas | +0.2 |
| Tempo de uso da plataforma | Consistência de comportamento ao longo do tempo | +0.1 por mês ativo |

### Fatores Negativos

| Fator | Descrição | Impacto |
|--------|------------|---------|
| Atraso em pagamento | Não quitação dentro do prazo | -0.8 |
| Inadimplência total | Falha em pagar valor devido | -2.0 |
| Disputa ou contestação de título | Conflitos abertos não resolvidos | -1.0 |
| Venda de títulos com recorrentes atrasos | Gera desconfiança no marketplace | -0.5 |

### Peso dos Critérios

Os fatores são ponderados por um sistema de pesos ajustáveis conforme o tipo de operação:

| Categoria | Peso (%) |
|------------|-----------|
| Pagamentos e recebimentos | 50% |
| Regularidade e frequência | 25% |
| Logs automáticos e comportamento coletivo | 15% |
| Tempo de uso | 10% |

<p style={{textAlign: 'center'}}>Fonte: Os autores (2025)</p>

### Fórmula Simplificada

A fórmula abaixo resume a lógica de cálculo:

\[
Score = \min(10, \max(0, Base + \sum(Pesos_i \times Fatores_i)))
\]

onde:
- *Base* = 5 (pontuação inicial de todos os usuários).  
- *Pesos_i* = peso de cada critério.  
- *Fatores_i* = contribuição positiva ou negativa do comportamento.

---

## Dinâmica do Score

O score é **dinâmico e reativo**, ajustando-se em tempo real de acordo com as ações do usuário.

### Como o Score Sobe

- Pagamentos realizados antes ou no prazo.  
- Participação em quitações automáticas.  
- Volume crescente de transações positivas.  
- Reinvestimento no marketplace.  

### Como o Score Cai

- Atrasos em pagamentos de dívidas.  
- Inadimplência em títulos comprados ou vendidos.  
- Contestação de valores sem solução.  
- Redução de atividade prolongada.  

### Exemplos de Movimentação

| Evento | Score Anterior | Variação | Novo Score |
|--------|----------------|-----------|-------------|
| Pagamento no prazo | 7.0 | +0.5 | 7.5 |
| Venda de título atrasado | 8.5 | -0.5 | 8.0 |
| Inadimplência | 6.0 | -2.0 | 4.0 |
| Quitação automática | 5.5 | +0.3 | 5.8 |

<p style={{textAlign: 'center'}}>Fonte: Os autores (2025)</p>

---

## Uso no Marketplace

### Confiança na Negociação

O score funciona como **indicador público de confiabilidade**.  
Os usuários baseiam suas decisões de compra e venda de títulos no valor exibido, reduzindo a necessidade de análise subjetiva.

### Precificação Baseada em Risco

O score impacta diretamente o **deságio aplicado** no marketplace:
- Score 9–10 → deságio baixo (2–5%).  
- Score 6–8 → deságio médio (10–15%).  
- Score abaixo de 5 → deságio alto (20–30%).  

Isso cria um mecanismo de autorregulação econômica e torna o sistema sustentável.

### Anonimato + Score

Mesmo com identidades ocultas, o score mantém a **transparência comportamental**.  
O comprador não precisa saber quem é o vendedor, apenas confiar na nota atribuída ao perfil.

---

## Incentivos e Penalidades

### Recompensas para Bons Pagadores

- Acesso a limites de negociação mais altos.  
- Menor deságio nas vendas.  
- Destaque no marketplace (ordenação por reputação).  
- Liberação antecipada de liquidez em operações futuras.  

### Consequências da Inadimplência

- Redução imediata do score.  
- Bloqueio temporário para novas vendas.  
- Aumento das taxas de deságio aplicadas automaticamente.  
- Possibilidade de suspensão do perfil em casos reincidentes.  

### Recuperação de Score

Usuários podem recuperar sua pontuação por meio de:
- Pagamento de dívidas antigas.  
- Participação em quitações automáticas.  
- Atividade positiva constante no aplicativo por período superior a 30 dias.  

---

## Mitigação de Risco

### Para a QI Tech

O score atua como **mecanismo preventivo de risco**, permitindo que a Qi Tech avalie o comportamento agregado dos usuários e ajuste suas políticas internas de custódia e liquidação.

### Para os Usuários

O sistema oferece visibilidade sobre a reputação dos participantes, reduzindo fraudes e inadimplência em negociações peer-to-peer.

### Para o Ecossistema

A manutenção de um score dinâmico e transparente reforça a confiança coletiva e garante a sustentabilidade do modelo de micro-recebíveis, equilibrando liberdade de negociação e responsabilidade financeira.

---

