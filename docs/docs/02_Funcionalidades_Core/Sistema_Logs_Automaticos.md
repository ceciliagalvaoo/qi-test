---
sidebar_position: 1
slug: /funcionalidades/logs-automaticos
description: "Sistema inteligente de logs para anulação automática de dívidas entre usuários e grupos"
---

# Sistema de Logs Automáticos

## Conceito

O **Sistema de Logs Automáticos** é um módulo do *The Simple Split* responsável por identificar e anular dívidas redundantes entre usuários, dentro ou fora de grupos.  
Seu objetivo é otimizar o fluxo financeiro, reduzindo transações desnecessárias e simplificando a reconciliação de saldos.

### O que são os Logs Automáticos

Logs automáticos são **registros de compensação gerados pelo sistema**, indicando que determinadas dívidas foram total ou parcialmente anuladas por equivalência de valores entre diferentes participantes.

Por exemplo: se *A deve R$10 a B* e *B deve R$10 a A*, o sistema cria um log de anulação, marcando ambas as dívidas como quitadas.

### Objetivo da Funcionalidade

O objetivo principal é reduzir o número de pagamentos individuais, evitando múltiplos Pix e eliminando dívidas duplicadas ou circulares.  
Isso gera uma experiência mais eficiente, além de minimizar erros e fricções entre usuários.

---

## Como Funciona

O sistema monitora continuamente as relações de débito e crédito registradas no banco de dados, cruzando informações entre grupos e usuários para detectar possíveis compensações automáticas.

### Exemplo Prático: Uber do Pablo

No grupo **“Viagem RJ-2025”**, Pablo pagou um Uber de R$30,00.  
O sistema divide automaticamente a despesa entre Cecília e Mariana:

- Cecília deve R$10,00 a Pablo.  
- Mariana deve R$10,00 a Pablo.  

Se, em outro grupo, Pablo tiver uma dívida equivalente com Cecília, o sistema registra um log de anulação, compensando os valores.

### Compensação Entre Grupos

O algoritmo considera todos os grupos onde os mesmos usuários interagem.  
Caso Cecília deva a Pablo em um grupo e Pablo deva a Cecília em outro, o sistema identifica o valor comum e realiza a compensação automática.

### Compensação Circular (A→B→C→A)

Em situações com circularidade, o sistema aplica uma lógica de cadeia:

<p style={{textAlign: 'center'}}>Figura 1 - Exemplo de Compensação Circular</p>

~~~mermaid
flowchart TD
    A[A deve R$10 a B] --> B[B deve R$10 a C]
    B --> C[C deve R$10 a A]
    C --> D[Logs automáticos anulam todas as dívidas]
~~~

<p style={{textAlign: 'center'}}>Fonte: Os autores (2025)</p>

Ao identificar o ciclo completo (A→B→C→A), o sistema entende que os valores se anulam mutuamente e gera um único log de compensação.

---

## Algoritmo de Anulação

### Lógica de Cruzamento

O algoritmo percorre todas as combinações de usuários com dívidas registradas, procurando correspondências opostas ou equivalentes.  
Essas combinações são armazenadas em um mapa de relacionamento, onde cada chave representa um par credor-devedor.

<p style={{textAlign: 'center'}}>Figura 2 - Lógica Simplificada de Cruzamento</p>

~~~mermaid
flowchart TD
    A[Início] --> B[Seleciona todas as dívidas ativas]
    B --> C[Identifica pares com valores equivalentes]
    C --> D[Gera log de compensação]
    D --> E[Atualiza status das dívidas afetadas]
    E --> F[Fim]
~~~

<p style={{textAlign: 'center'}}>Fonte: Os autores (2025)</p>

### Processamento

- Executado de forma assíncrona após cada novo registro de despesa.  
- Utiliza chaves compostas (devedor, credor, grupo) para identificar relações recíprocas.  
- As compensações parciais são permitidas quando os valores não são idênticos.  
- Todos os logs são armazenados em tabela específica no banco de dados para auditoria.

### Notificações ao Usuário

Quando um log automático é gerado:
1. Os usuários envolvidos recebem uma notificação no aplicativo.  
2. O evento é exibido na aba **Insights**.  
3. As carteiras dos usuários são atualizadas conforme a compensação aplicada.  

---

## Benefícios

### Para o Usuário

- Redução de transações manuais.  
- Eliminação de dívidas redundantes.  
- Atualização automática do saldo e do histórico.  
- Maior clareza e controle sobre as finanças pessoais.

### Para o Ecossistema

- Menor volume de liquidações simultâneas.  
- Otimização do fluxo financeiro coletivo.  
- Aumento da confiabilidade dos dados de dívida.  
- Eficiência no uso da infraestrutura da Qi Tech.

---

## Casos de Uso

### Caso 1: Dívidas no Mesmo Grupo

Cecília deve R$20 a Mariana e Mariana deve R$20 a Cecília no mesmo grupo.  
O sistema identifica a equivalência e gera um log de quitação para ambas as partes, marcando as dívidas como anuladas.

### Caso 2: Dívidas Entre Grupos Diferentes

Pablo deve R$15 a Cecília no grupo **“Viagem RJ-2025”**, mas Cecília deve R$15 a Pablo no grupo **“Viagem SP-2025”**.  
A compensação é registrada entre grupos, reduzindo o número de transações financeiras.

### Caso 3: Circularidade Complexa

A deve R$10 a B, B deve R$10 a C, e C deve R$10 a A.  
O sistema reconhece o ciclo e anula todas as três dívidas, registrando o log de quitação circular.