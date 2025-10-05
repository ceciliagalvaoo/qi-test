---
sidebar_position: 1
slug: /escalabilidade/infraestrutura
description: "Estratégias de escalabilidade técnica aproveitando a infraestrutura da QI Tech"
---

# Escalabilidade da Infraestrutura

## Aproveitamento da Infraestrutura QI Tech

A escalabilidade do *The Simple Split* está diretamente associada à robustez da infraestrutura oferecida pela Qi Tech.  
Ao integrar-se com os serviços de **Banking as a Service (BaaS)**, **SCD** e **custódia digital**, o sistema herda capacidade de processamento, segurança e disponibilidade de nível bancário.

### Cloud Infrastructure

A Qi Tech opera sobre uma infraestrutura em nuvem com arquitetura distribuída, o que permite:
- Processamento em múltiplas zonas de disponibilidade.  
- Escalabilidade horizontal automática conforme a demanda.  
- Resiliência a falhas regionais e continuidade de serviço.  

O *The Simple Split* se beneficia dessa base, com seus componentes hospedados em containers otimizados para execução em ambientes compatíveis (AWS, GCP ou Azure).

### Serviços Gerenciados

A utilização de **serviços gerenciados** elimina a necessidade de manutenção manual de servidores.  
A Qi Tech provê:
- Banco de dados transacional de alta performance.  
- Filas e barramentos de mensagens para processamento assíncrono.  
- Sistemas de monitoramento e logs centralizados.  

### CDN e Edge Computing

Conteúdos estáticos do aplicativo (imagens, assets e documentos) podem ser distribuídos via **CDN**, reduzindo latência global.  
A adoção de **Edge Computing** garante que atualizações de dados críticos, como scores ou logs automáticos, sejam processadas o mais próximo possível do usuário final.

### Redundância e Alta Disponibilidade

- Replicação de dados entre múltiplos datacenters.  
- Failover automático em caso de indisponibilidade.  
- Backups contínuos e testados periodicamente.  
Essas práticas asseguram uma disponibilidade superior a 99,9%.

---

## Arquitetura Escalável

### Microsserviços

O backend do *The Simple Split* é modularizado em **microsserviços**, cada um responsável por um domínio específico:
- Serviço de Usuários  
- Serviço de Grupos e Despesas  
- Serviço de Logs Automáticos  
- Serviço de Marketplace e Títulos  
- Serviço de Score Dinâmico  

Isso permite escalar individualmente os módulos que exigirem maior capacidade.

### Separação de Concerns

A separação clara de responsabilidades entre frontend, backend e integração Qi Tech facilita manutenção e evolução do sistema sem impactos cruzados.

### Event-Driven Architecture

O sistema adota uma **arquitetura orientada a eventos**, onde ações do usuário (ex: pagamento, registro de despesa) disparam eventos tratados de forma assíncrona, garantindo responsividade mesmo sob alta carga.

### Message Queues

O uso de **filas de mensagens** (RabbitMQ, Kafka ou serviços equivalentes da Qi Tech) permite o processamento paralelo de grandes volumes de transações sem perda de dados.

<p style={{textAlign: 'center'}}>Figura 1 - Fluxo de Processamento Assíncrono com Fila de Mensagens</p>

~~~mermaid
flowchart TD
    A[Evento do Usuário] --> B[Publicação na Fila]
    B --> C[Consumidor de Logs e Transações]
    C --> D[Atualiza Banco e Notifica Usuário]
~~~

<p style={{textAlign: 'center'}}>Fonte: Os autores (2025)</p>

---

## Processamento Assíncrono

### Cálculo de Logs em Background

O algoritmo de compensação de dívidas é executado em tarefas assíncronas, processando múltiplos grupos simultaneamente e reduzindo o tempo de resposta do aplicativo.

### Atualização de Score

O **Score Dinâmico** é recalculado periodicamente com base nas transações recentes.  
Esses cálculos são feitos em segundo plano, evitando bloqueios no fluxo principal.

### Notificações Push

As notificações de pagamento, quitação e movimentações são enviadas por workers assíncronos, garantindo entrega em tempo real sem sobrecarregar o backend principal.

### Jobs Agendados

Jobs programados controlam rotinas de:
- Atualização de status de títulos.  
- Limpeza de logs antigos.  
- Geração de relatórios de desempenho.  

---

## Performance e Otimização

### Cache Distribuído

O cache é aplicado para reduzir consultas repetitivas e acelerar respostas.  
Pode utilizar **Redis** ou **Elasticache**, dependendo do ambiente de implantação.

### Database Indexing

Índices otimizados nas colunas mais acessadas (`usuario_id`, `grupo_id`, `status`) garantem consultas rápidas, mesmo com bases de dados extensas.

### Query Optimization

Consultas SQL são otimizadas por meio de:
- Paginação controlada.  
- Seleção de colunas específicas.  
- Eliminação de *joins* desnecessários.  

### Load Balancing

O balanceamento de carga é realizado entre múltiplas instâncias do backend Python.  
Cada instância compartilha sessão via tokens JWT, garantindo autenticação consistente e escalabilidade horizontal.

---

## Crescimento de Usuários

### Onboarding em Escala

O processo de cadastro e verificação KYC é totalmente automatizado pela Qi Tech, permitindo o onboarding simultâneo de milhares de usuários.

### Gestão de Milhões de Transações

A infraestrutura BaaS da Qi Tech é projetada para lidar com milhões de transações diárias, o que permite ao *The Simple Split* crescer sem impacto na performance.

### Marketplace com Alto Volume

A arquitetura do marketplace é orientada a eventos e cache, garantindo alta taxa de atualização de ofertas sem sobrecarregar o banco principal.

### Monitoramento e Métricas

- Coleta contínua de métricas via Prometheus e Grafana.  
- Alertas automáticos para anomalias de performance.  
- Logs estruturados para auditoria e análise de falhas.  

---

## Custos Operacionais

### Modelo de Pricing

O custo de operação é proporcional ao uso da infraestrutura Qi Tech e ao volume de transações liquidadas.  
O modelo de negócios adota o conceito **pay-per-use**, cobrando apenas pelo processamento efetivo.

### Otimização de Recursos

- Escalonamento automático de containers.  
- Desligamento de instâncias ociosas.  
- Compactação de dados históricos para reduzir consumo de armazenamento.

### Auto-scaling

Instâncias de backend e workers sobem e descem automaticamente conforme a demanda.  
Isso assegura economia em períodos de baixa utilização e capacidade máxima durante picos de tráfego.

### Pay-as-you-grow

A estrutura “**pay-as-you-grow**” da Qi Tech permite expandir o sistema de forma previsível, ajustando custos à taxa real de crescimento de usuários e transações.

---

## Projeção de Crescimento

| Fase | Usuários | Estratégia de Escalabilidade | Observações |
|------|-----------|------------------------------|--------------|
| **Fase 1: MVP** | 1.000 | Deploy monolítico simples com SQLite e cache local | Ideal para validação de produto. |
| **Fase 2: Early Adoption** | 10.000 | Separação em microsserviços e uso de Redis | Aumento de concorrência e volume. |
| **Fase 3: Growth** | 100.000 | Migração para PostgreSQL e filas de mensagens | Introdução de processamento distribuído. |
| **Fase 4: Scale** | 1.000.000+ | Infraestrutura completa em nuvem Qi Tech + Auto-scaling | Escala corporativa e alta disponibilidade. |

<p style={{textAlign: 'center'}}>Fonte: Os autores (2025)</p>


