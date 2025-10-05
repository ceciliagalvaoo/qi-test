---
sidebar_position: 5
slug: /funcionalidades/jornada-interface
description: "Jornada completa do usuário e wireframes das principais telas do aplicativo"
---

# Jornada do Usuário e Interface

## Design System

O design do *The Simple Split* segue a filosofia **minimalista e funcional**, priorizando clareza e consistência visual.  
O objetivo é oferecer uma experiência fluida e intuitiva, sem sobrecarregar o usuário com informações desnecessárias.

### Estilo Minimalista Apple

A interface adota um **design inspirado no ecossistema Apple**, com predominância de superfícies claras, espaçamento amplo, tipografia refinada e hierarquia visual bem definida.  
As transições são suaves e os elementos possuem cantos arredondados com sombras sutis, reforçando a sensação de leveza.

### Paleta de Cores

A paleta principal é composta por tons neutros, com **brancos e cinzas claros** como base, contrastados por **tons de azul** para elementos de ação e realce.  
A escolha das cores reforça a legibilidade e o foco nas informações financeiras.

| Tipo de Elemento | Cor | Uso |
|------------------|------|-----|
| Fundo principal | #FFFFFF | Base das telas |
| Fundo secundário | #F6F6F6 | Cartões e blocos de conteúdo |
| Cor primária | #007AFF | Botões e destaques |
| Texto padrão | #1C1C1E | Legibilidade e contraste |
| Texto secundário | #8E8E93 | Informações complementares |

<p style={{textAlign: 'center'}}>Fonte: Os autores (2025)</p>

### Tipografia

A fonte principal é **SF Pro Display**, garantindo coerência com o estilo iOS.  
Tamanhos variam conforme hierarquia:  
- Títulos: 20–24 px  
- Subtítulos: 16–18 px  
- Texto padrão: 14 px  
- Notas e rótulos: 12 px  

### Componentes

O sistema utiliza componentes reutilizáveis e consistentes, incluindo:  
- **Cards** para agrupamento de informações financeiras.  
- **Botões primários e secundários** com diferenciação visual clara.  
- **Pop-ups informativos** para explicações rápidas (ex: origem da dívida).  
- **Ícones sutis** para reforçar o significado sem poluir a tela.  

---

## Fluxo de Onboarding

### Tela 1: Autenticação

Tela de entrada com campos de e-mail e senha.  
Inclui botão “Entrar” e link para “Criar Conta”.  
A interface é centrada e utiliza fundo branco e tipografia fina.  
*(Placeholder para imagem da tela de autenticação)*

### Criação de Conta

Ao selecionar “Criar Conta”, o usuário informa nome, e-mail e senha.  
O sistema envia um código de verificação para o e-mail cadastrado.  
*(Placeholder para imagem da tela de criação de conta)*

### Verificação 2FA

O código enviado é inserido pelo usuário para validação em duas etapas.  
Após confirmação, a conta é ativada.  
*(Placeholder para imagem da tela de verificação 2FA)*

### Primeiro Acesso

Após login, o usuário é conduzido a uma introdução curta sobre as principais funcionalidades da aplicação.  
O objetivo é orientar o novo usuário sobre grupos, carteira e marketplace.  
*(Placeholder para imagem da tela de introdução)*

---

## Dashboard Principal

### Visão Geral

O Dashboard é o ponto central da navegação.  
Apresenta as principais informações financeiras de forma resumida e permite acesso rápido às cinco abas principais.  
*(Placeholder para imagem do dashboard principal)*

### Menu Inferior (5 abas)

As abas fixas na parte inferior da tela são:
1. **Grupos**  
2. **Contatos**  
3. **Insights**  
4. **Marketplace**  
5. **Usuário (Perfil)**  

Essas abas estão sempre disponíveis e utilizam ícones minimalistas com rótulos curtos.

### Navegação

A navegação é fluida, com transições suaves entre abas e persistência de contexto.  
Não há recarregamento completo da tela, o que melhora a experiência do usuário.

---

## Telas Principais

### Aba: Grupos

#### Criação de Grupo

O usuário cria um grupo atribuindo nome e descrição.  
Pode convidar contatos da lista para participar.  
*(Placeholder para imagem da tela de criação de grupo)*

#### Visualização de Grupo

Cada grupo é exibido em um card com informações resumidas: nome, participantes e saldo total.  
*(Placeholder para imagem da visualização do grupo)*

#### Registro de Despesas

Dentro de um grupo, o usuário registra despesas, informando valor, descrição e quem pagou.  
O sistema calcula automaticamente quanto cada participante deve.  
*(Placeholder para imagem da tela de registro de despesas)*

#### Visualização de Dívidas

A tela apresenta uma lista clara de quem deve a quem e quanto.  
Valores positivos e negativos são destacados com cores distintas.  
*(Placeholder para imagem da tela de visualização de dívidas)*

#### Logs Automáticos

Quando o sistema identifica compensações possíveis, exibe logs automáticos de quitação.  
Esses registros são mostrados em cartões cinza com informações detalhadas.  
*(Placeholder para imagem da tela de logs automáticos)*

---

### Aba: Contatos

#### Lista de Contatos

Exibe todos os contatos registrados no aplicativo, organizados alfabeticamente.  
Cada contato mostra nome e score.  
*(Placeholder para imagem da lista de contatos)*

#### Score Visível

O score (0 a 10) aparece ao lado do nome do contato.  
Um botão de informação explica o cálculo do score.  
*(Placeholder para imagem do score visível)*

#### Anúncios de Recebíveis

Abaixo de cada contato, aparecem anúncios de recebíveis disponíveis para compra.  
*(Placeholder para imagem de anúncios de recebíveis)*

---

### Aba: Insights

#### Notificações Inteligentes

Exibe alertas de movimentações importantes, como quitação de dívidas e novas oportunidades no marketplace.  
*(Placeholder para imagem de notificações inteligentes)*

#### Alertas de Pagamento

Mostra lembretes de pagamentos próximos do vencimento.  
*(Placeholder para imagem de alertas de pagamento)*

#### Logs Recentes

Lista as últimas operações automáticas de compensação de dívidas.  
*(Placeholder para imagem dos logs recentes)*

---

### Aba: Marketplace

#### Listagem de Títulos

Apresenta todos os títulos disponíveis com informações de valor nominal, preço de venda e score do vendedor.  
*(Placeholder para imagem da listagem de títulos)*

#### Detalhes do Título

Ao selecionar um título, o usuário visualiza detalhes sobre o valor, prazo e condições de compra.  
*(Placeholder para imagem dos detalhes do título)*

#### Compra de Recebível

O usuário pode comprar um título diretamente, utilizando o saldo da carteira digital.  
*(Placeholder para imagem da compra de recebível)*

#### Anonimização

As identidades dos compradores e vendedores permanecem ocultas; apenas o score é visível.  
*(Placeholder para imagem de anonimização no marketplace)*

---

### Aba: Usuário (Perfil)

#### Nome e Score

Mostra o nome do usuário e seu score de reputação.  
*(Placeholder para imagem da tela de perfil com score)*

#### Carteira Digital

Apresenta o saldo atual e atalhos para adicionar fundos, pagar ou transferir.  
*(Placeholder para imagem da carteira digital)*

#### A Receber

Lista todas as dívidas e títulos comprados pendentes de recebimento.  
*(Placeholder para imagem da seção “A Receber”)*

#### A Pagar

Exibe as dívidas e obrigações pendentes do usuário.  
*(Placeholder para imagem da seção “A Pagar”)*

#### Histórico

Mostra todas as movimentações e logs financeiros do usuário.  
*(Placeholder para imagem da tela de histórico)*

---

## Fluxos de Interação

### Fluxo 1: Criar Grupo e Registrar Despesa

<p style={{textAlign: 'center'}}>Figura 1 - Fluxo de Criação de Grupo e Registro de Despesa</p>

```mermaid
flowchart TD
    A[Usuário acessa aba Grupos] --> B[Clica em "Criar Grupo"]
    B --> C[Adiciona participantes]
    C --> D[Registra despesa com valor e descrição]
    D --> E[Sistema calcula e distribui valores]
```

### Fluxo 2: Visualizar Log Automático

<p style={{textAlign: 'center'}}>Figura 2 - Fluxo de Visualização de Log Automático</p>

~~~mermaid
flowchart TD
    A[Sistema identifica dívidas compensáveis] --> B[Cria log automático]
    B --> C[Exibe notificação em Insights]
    C --> D[Usuário visualiza log detalhado]
~~~

<p style={{textAlign: 'center'}}>Fonte: Os autores (2025)</p>

---

### Fluxo 3: Vender Recebível no Marketplace

<p style={{textAlign: 'center'}}>Figura 3 - Fluxo de Venda de Recebível</p>

~~~mermaid
flowchart TD
    A[Usuário acessa aba Marketplace] --> B[Seleciona dívida a receber]
    B --> C[Define valor de venda e confirma]
    C --> D[Título é publicado anonimamente no marketplace]
~~~

<p style={{textAlign: 'center')}}">Fonte: Os autores (2025)</p>

---

### Fluxo 4: Comprar Título no Marketplace

<p style={{textAlign: 'center'}}>Figura 4 - Fluxo de Compra de Título</p>

~~~mermaid
flowchart TD
    A[Usuário navega no marketplace] --> B[Seleciona título desejado]
    B --> C[Confirma compra com saldo da carteira]
    C --> D[Qi Tech processa a transferência do título]
    D --> E[Carteira e histórico do comprador atualizados]
~~~

<p style={{textAlign: 'center'}}>Fonte: Os autores (2025)</p>

---

### Fluxo 5: Pagamento via Carteira

<p style={{textAlign: 'center'}}>Figura 5 - Fluxo de Pagamento via Carteira</p>

~~~mermaid
flowchart TD
    A[Usuário acessa aba A Pagar] --> B[Seleciona dívida]
    B --> C[Clica em "Pagar com Carteira"]
    C --> D[Qi Tech realiza a liquidação]
    D --> E[Saldo e histórico atualizados]
~~~

<p style={{textAlign: 'center'}}>Fonte: Os autores (2025)</p>

---

### Fluxo 6: Acompanhar Score

<p style={{textAlign: 'center'}}>Figura 6 - Fluxo de Acompanhamento de Score</p>

~~~mermaid
flowchart TD
    A[Usuário acessa perfil] --> B[Visualiza score atual]
    B --> C[Clica em "Entenda seu score"]
    C --> D[Consulta histórico de comportamento financeiro]
~~~

<p style={{textAlign: 'center'}}>Fonte: Os autores (2025)</p>

---

## Princípios de UX

### Clareza

A interface comunica ações e estados de forma objetiva. Rótulos e hierarquia visual são utilizados para reduzir ambiguidade sobre o que cada botão e informação representam.

### Simplicidade

Cada tela apresenta apenas o conteúdo necessário para a tarefa em questão. Fluxos de ação são curtos e priorizam passos essenciais, reduzindo carga cognitiva.

### Transparência

Valores, origens e destinos das transações são exibidos de forma explícita. Logs e históricos detalhados ficam acessíveis para auditoria do usuário.

### Feedback Visual

A aplicação oferece confirmações visuais imediatas para ações relevantes (pagamentos, quitações, compras). Estados de carregamento, sucesso e falha são apresentados de modo consistente.


