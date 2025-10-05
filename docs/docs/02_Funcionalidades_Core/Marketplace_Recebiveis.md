---
sidebar_position: 2
slug: /funcionalidades/marketplace-recebiveis
description: "Marketplace de micro-recebíveis sociais peer-to-peer com anonimização"
---

# Marketplace de Recebíveis Sociais

## Conceito do Marketplace

O **Marketplace de Recebíveis Sociais** é um ambiente digital integrado ao *The Simple Split* que permite a negociação peer-to-peer de micro-recebíveis entre usuários.  
A proposta é transformar dívidas sociais — como pequenas despesas entre amigos, colegas ou grupos — em ativos financeiros líquidos e negociáveis.

### O que são Micro-Recebíveis Sociais

Micro-recebíveis sociais são pequenos créditos originados de interações cotidianas, geralmente entre pessoas físicas, como:
- Divisão de contas de viagem.  
- Reembolso de um jantar ou transporte.  
- Pagamentos adiantados feitos por um membro do grupo.  

Esses valores, tradicionalmente informais, passam a ser formalizados como **títulos de crédito eletrônicos**, custodiados e liquidados pela Qi Tech.

### Novo Nicho de Mercado

O marketplace inaugura um nicho inexplorado no mercado financeiro brasileiro: a **tokenização de dívidas de pequeno valor entre pessoas físicas**.  
A operação é viabilizada pela infraestrutura de **Banking as a Service (BaaS)** e **Sociedade de Crédito Direto (SCD)** da Qi Tech, que reduz custos operacionais e torna viável a negociação de valores baixos de forma regulamentada.

### Por que é Inovador

- Transforma obrigações pessoais em ativos financeiros.  
- Democratiza o acesso à liquidez e à antecipação de recebíveis.  
- Cria um novo modelo de crédito baseado em comportamento e reputação.  
- Utiliza o **score dinâmico** como métrica de risco, substituindo intermediários tradicionais.  

---

## Como Funciona

### Fluxo de Venda de Recebível

<p style={{textAlign: 'center'}}>Figura 1 - Fluxo de Venda de Recebível</p>

~~~mermaid
flowchart TD
    A[Usuário seleciona dívida a receber] --> B[Define valor de venda com desconto]
    B --> C[Título é formalizado e custodiado pela Qi Tech]
    C --> D[Título é publicado anonimamente no marketplace]
~~~

<p style={{textAlign: 'center'}}>Fonte: Os autores (2025)</p>

### Fluxo de Compra de Recebível

<p style={{textAlign: 'center'}}>Figura 2 - Fluxo de Compra de Recebível</p>

~~~mermaid
flowchart TD
    A[Usuário navega no marketplace] --> B[Seleciona título desejado]
    B --> C[Confirma compra com saldo da carteira]
    C --> D[Qi Tech transfere a titularidade do recebível]
    D --> E[Comprador passa a ter direito ao valor integral]
~~~

<p style={{textAlign: 'center'}}>Fonte: Os autores (2025)</p>

### Exemplo Prático: Cecília (R$40 → R$35)

Cecília possui um crédito de **R$40,00** referente a uma despesa compartilhada.  
Precisa do dinheiro imediatamente, então decide **vender o título por R$35,00**.  
O comprador paga R$35,00 agora e recebe os R$40,00 quando o devedor original quitar a dívida.  
Essa diferença representa o ganho proporcional ao risco assumido na transação.

---

## Mecânica de Negociação

### Precificação

A precificação é livre e orientada pelo mercado.  
O vendedor define o valor de venda (deságio), e os compradores decidem com base no score do vendedor e no valor nominal do título.

| Elemento | Descrição |
|-----------|------------|
| Valor Nominal | Montante total da dívida registrada. |
| Valor de Venda | Quantia solicitada pelo vendedor para liquidez imediata. |
| Deságio | Diferença entre o valor nominal e o valor de venda. |
| Retorno Esperado | Percentual obtido pelo comprador após o pagamento integral. |

<p style={{textAlign: 'center'}}>Fonte: Os autores (2025)</p>

### Anonimização

As identidades dos participantes são ocultadas durante a negociação.  
O comprador visualiza apenas:
- Score do vendedor.  
- Valor nominal e valor de venda.  
- Prazo estimado de liquidação.  

A Qi Tech atua como intermediária, garantindo a confidencialidade e a validade da transação.

### Uso do Score na Decisão

O **Score Dinâmico** influencia diretamente o preço de mercado dos títulos.  
Usuários com score alto podem vender recebíveis com menor deságio, enquanto scores baixos exigem descontos maiores para atrair compradores.

### Formalização pela QI Tech

Cada transação é formalizada pela Qi Tech como **título de crédito eletrônico**, custodiado em sua infraestrutura SCD.  
A empresa garante:
- Registro do crédito e do comprador.  
- Controle de liquidação financeira.  
- Transferência segura da titularidade.

---

## Limites de Valores

### Micro-Recebíveis (R$10 - R$500)

O marketplace opera com títulos entre **R$10,00 e R$500,00**, faixa que representa o universo de microtransações sociais.

### Justificativa dos Limites

- Evita a complexidade operacional de grandes transações.  
- Mantém o foco no uso social e cotidiano da aplicação.  
- Reduz o risco de inadimplência generalizada.  
- Favorece a liquidez e o giro constante de títulos.  

### Viabilidade Econômica

A estrutura da Qi Tech permite o processamento eficiente de microvalores, reduzindo o custo marginal por transação.  
A operação é viável devido à automação completa de registro, custódia e liquidação, tornando possível a negociação de títulos de pequeno porte.

---

## Segurança e Custódia

### Papel da QI Tech

A Qi Tech é responsável pela **formalização, custódia e liquidação** de todos os títulos transacionados.  
Sua infraestrutura garante conformidade com as normas do Banco Central e da CVM.

### Garantias ao Comprador

- Recebimento assegurado do valor integral após a quitação do devedor.  
- Validação do título por uma instituição regulada.  
- Anonimato preservado sem comprometer a autenticidade.  

### Garantias ao Vendedor

- Liquidez imediata mediante venda.  
- Transparência sobre taxas e prazos.  
- Registro auditável da operação e do valor recebido.  

---

## Casos de Uso

### Caso 1: Urgência Financeira

Um usuário com dívida a receber pode vender o título para obter liquidez imediata, sem precisar recorrer a crédito formal.  
O marketplace oferece uma alternativa acessível para situações emergenciais.

### Caso 2: Diversificação de Recebíveis

Compradores podem adquirir diferentes títulos de pequeno valor para diversificar riscos e construir uma carteira de micro-recebíveis com retorno agregado.

### Caso 3: Lucro com Score Alto

Usuários com histórico de pagamento sólido podem negociar seus recebíveis com baixo deságio, gerando demanda alta e fortalecendo seu score dentro do ecossistema.

---
