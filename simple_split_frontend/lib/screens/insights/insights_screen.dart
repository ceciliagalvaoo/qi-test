import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/api_service.dart';
import '../../utils/theme.dart';

class InsightsScreen extends StatefulWidget {
  final bool showAppBar;
  final bool showBottomNavigation;
  
  const InsightsScreen({
    super.key,
    this.showAppBar = true,
    this.showBottomNavigation = true,
  });

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _insightsData;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    setState(() => _isLoading = true);

    try {
      // Buscar insights, resumo e transações em paralelo
      final responses = await Future.wait([
        ApiService.get('/insights'),
        ApiService.get('/insights/summary'),
        ApiService.get('/user/wallet/transactions'),
      ]);

      final insightsResponse = responses[0];
      final summaryResponse = responses[1];
      final transactionsResponse = responses[2];

      // A API /insights retorna diretamente uma lista de insights
      List<dynamic> insightsList = [];
      if (insightsResponse is List<dynamic>) {
        insightsList = insightsResponse;
      } else {
        // Se por algum motivo retornar um mapa, tentar extrair a lista
        insightsList = [];
      }

      // Garantir que summaryResponse é um Map
      Map<String, dynamic> summary = {};
      if (summaryResponse is Map<String, dynamic>) {
        summary = summaryResponse;
      }

      // Processar transações
      List<dynamic> transactionsList = [];
      if (transactionsResponse is List<dynamic>) {
        transactionsList = transactionsResponse;
      } else if (transactionsResponse is Map<String, dynamic> && 
                 transactionsResponse.containsKey('transactions')) {
        transactionsList = transactionsResponse['transactions'] ?? [];
      }

      setState(() {
        _insightsData = {
          'insights': insightsList,
          'financial_summary': {
            'total_spent': summary['total_spent'] ?? 0.0,          // Total gasto (da API)
            'wallet_balance': summary['wallet_balance'] ?? 0.0,    // Saldo da carteira  
            'total_to_receive': summary['total_to_receive'] ?? 0.0, // A receber
            'total_to_pay': summary['total_to_pay'] ?? 0.0,        // A pagar
          },
          'spending_insights': {
            'top_categories': _calculateSpendingCategories(transactionsList),
          },
          'social_insights': {
            'active_groups': summary['active_groups'] ?? 0,
            'total_contacts': 20, // Número padrão de contatos com conta no app
            'user_score': summary['score'] ?? 0.0,
            'total_transactions': transactionsList.length,
          },
          'recommendations': _transformInsightsToRecommendations(insightsList),
        };
      });
    } catch (e) {
      print('Erro ao carregar insights: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar insights: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }

    setState(() => _isLoading = false);
  }



  List<Map<String, dynamic>> _calculateSpendingCategories(List<dynamic> transactions) {
    Map<String, double> categoryTotals = {};
    double totalSpent = 0.0;
    
    // Agrupar gastos por descrição/categoria
    for (final transaction in transactions) {
      try {
        final type = transaction['type']?.toString() ?? '';
        final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
        final description = transaction['description']?.toString() ?? 'Outros';
        
        if (type == 'debit' && amount > 0) {
          // Categorizar baseado na descrição
          String category = _categorizeTransaction(description);
          categoryTotals[category] = (categoryTotals[category] ?? 0.0) + amount;
          totalSpent += amount;
        }
      } catch (e) {
        // Ignorar transações com formato inválido
        continue;
      }
    }
    
    // Converter para lista e calcular percentuais
    List<Map<String, dynamic>> categories = [];
    
    categoryTotals.entries.forEach((entry) {
      final percentage = totalSpent > 0 ? (entry.value / totalSpent) * 100 : 0.0;
      categories.add({
        'name': entry.key,
        'amount': entry.value,
        'percentage': percentage,
      });
    });
    
    // Ordenar por valor (maior para menor)
    categories.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
    
    // Retornar apenas os top 5
    return categories.take(5).toList();
  }

  String _categorizeTransaction(String description) {
    final desc = description.toLowerCase();
    
    if (desc.contains('pagamento') || desc.contains('dívida')) {
      return 'Pagamentos';
    } else if (desc.contains('transferência') || desc.contains('enviada')) {
      return 'Transferências';
    } else if (desc.contains('taxa') || desc.contains('serviço')) {
      return 'Taxas';
    } else if (desc.contains('marketplace') || desc.contains('compra')) {
      return 'Compras';
    } else if (desc.contains('saque')) {
      return 'Saques';
    } else {
      return 'Outros';
    }
  }

  List<Map<String, dynamic>> _transformInsightsToRecommendations(List<dynamic> insights) {
    return insights.where((insight) => 
      insight['type'] == 'payment_reminder' || 
      insight['type'] == 'score_warning' ||
      insight['type'] == 'spending_summary'
    ).map<Map<String, dynamic>>((insight) {
      String type = 'info';
      if (insight['priority'] == 'high') {
        type = 'warning';
      } else if (insight['type'] == 'score_good') {
        type = 'savings';
      }
      
      return {
        'type': type,
        'message': insight['description'] ?? insight['title'] ?? '',
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final body = _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _insightsData == null
            ? _buildErrorState()
            : RefreshIndicator(
                onRefresh: _loadInsights,
                child: _buildInsights(),
              );
    
    // Se não deve mostrar AppBar nem BottomNavigation, retorna apenas o body
    if (!widget.showAppBar && !widget.showBottomNavigation) {
      return body;
    }
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.showAppBar ? AppBar(
        title: const Text('Insights'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadInsights,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ) : null,
      body: body,
      bottomNavigationBar: widget.showBottomNavigation ? BottomNavigationBar(
        currentIndex: 3, // Insights está no índice 3
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/dashboard');
              break;
            case 1:
              context.go('/groups');
              break;
            case 2:
              context.go('/marketplace');
              break;
            case 3:
              // Já está na tela de insights
              break;
            case 4:
              context.go('/user');
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.onSurfaceVariant,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            activeIcon: Icon(Icons.group),
            label: 'Grupos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront),
            label: 'Marketplace',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_outlined),
            activeIcon: Icon(Icons.insights),
            label: 'Insights',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ) : null,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error.withOpacity(0.5),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Erro ao carregar insights',
              style: AppTextStyles.headline.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            
            const SizedBox(height: 32),
            
            ElevatedButton.icon(
              onPressed: _loadInsights,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsights() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFinancialSummary(),
          
          const SizedBox(height: 24),
          
          _buildSpendingInsights(),
          
          const SizedBox(height: 24),
          
          _buildSocialInsights(),
          
          const SizedBox(height: 24),
          
          _buildRecommendations(),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    final summary = _insightsData?['financial_summary'] ?? {};
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet,
                  color: AppColors.primary,
                  size: 24,
                ),
                
                const SizedBox(width: 12),
                
                Text(
                  'Resumo Financeiro',
                  style: AppTextStyles.headline.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    title: 'Total Gasto',
                    value: 'R\$ ${(summary['total_spent'] as num? ?? 0).toStringAsFixed(2)}',
                    color: AppColors.error,
                    icon: Icons.trending_down,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: _buildSummaryItem(
                    title: 'Saldo Líquido',
                    value: 'R\$ ${(summary['wallet_balance'] as num? ?? 0).toStringAsFixed(2)}',
                    color: AppColors.primary,
                    icon: Icons.account_balance_wallet,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    title: 'A Receber',
                    value: 'R\$ ${(summary['total_to_receive'] as num? ?? 0).toStringAsFixed(2)}',
                    color: AppColors.success,
                    icon: Icons.trending_up,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: _buildSummaryItem(
                    title: 'A Pagar',
                    value: 'R\$ ${(summary['total_to_pay'] as num? ?? 0).toStringAsFixed(2)}',
                    color: AppColors.error,
                    icon: Icons.trending_down,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 16,
              ),
              
              const SizedBox(width: 4),
              
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.caption1.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 4),
          
          Text(
            value,
            style: AppTextStyles.subheadline.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingInsights() {
    final spending = _insightsData?['spending_insights'] ?? {};
    final categories = List<Map<String, dynamic>>.from(
      spending['top_categories'] ?? []
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.pie_chart,
                  color: AppColors.primary,
                  size: 24,
                ),
                
                const SizedBox(width: 12),
                
                Text(
                  'Análise de Gastos',
                  style: AppTextStyles.headline.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (categories.isEmpty)
              Text(
                'Sem dados de gastos ainda',
                style: AppTextStyles.subheadline.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              )
            else
              Column(
                children: categories.map((category) {
                  final name = category['name'] as String? ?? 'Categoria';
                  final amount = (category['amount'] as num? ?? 0).toDouble();
                  final percentage = (category['percentage'] as num? ?? 0).toDouble();
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildCategoryItem(name, amount, percentage),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String name, double amount, double percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: AppTextStyles.subheadline.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            
            Text(
              'R\$ ${amount.toStringAsFixed(2)}',
              style: AppTextStyles.subheadline.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 4),
        
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: AppColors.primary.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            
            const SizedBox(width: 8),
            
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: AppTextStyles.caption1.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialInsights() {
    final social = _insightsData?['social_insights'] ?? {};
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.people,
                  color: AppColors.primary,
                  size: 24,
                ),
                
                const SizedBox(width: 12),
                
                Text(
                  'Insights Sociais',
                  style: AppTextStyles.headline.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildSocialStat(
                    title: 'Grupos ativos',
                    value: '${social['active_groups'] ?? 0}',
                    icon: Icons.group,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: _buildSocialStat(
                    title: 'Contatos',
                    value: '${social['total_contacts'] ?? 0}',
                    icon: Icons.person,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildSocialStat(
                    title: 'Seu score',
                    value: (social['user_score'] as num? ?? 0.0).toStringAsFixed(1),
                    icon: Icons.star,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: _buildSocialStat(
                    title: 'Transações',
                    value: '${social['total_transactions'] ?? 0}',
                    icon: Icons.swap_horiz,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialStat({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            value,
            style: AppTextStyles.headline.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          Text(
            title,
            style: AppTextStyles.caption1.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    final recommendations = List<Map<String, dynamic>>.from(
      _insightsData?['recommendations'] ?? []
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.lightbulb,
                  color: AppColors.primary,
                  size: 24,
                ),
                
                const SizedBox(width: 12),
                
                Text(
                  'Recomendações',
                  style: AppTextStyles.headline.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (recommendations.isEmpty)
              Text(
                'Nenhuma recomendação no momento',
                style: AppTextStyles.subheadline.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              )
            else
              Column(
                children: recommendations.map((recommendation) {
                  return _buildRecommendationItem(recommendation);
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(Map<String, dynamic> recommendation) {
    final type = recommendation['type'] as String? ?? '';
    final message = recommendation['message'] as String? ?? '';
    
    IconData icon;
    Color color;
    
    switch (type) {
      case 'savings':
        icon = Icons.savings;
        color = AppColors.success;
        break;
      case 'warning':
        icon = Icons.warning;
        color = AppColors.warning;
        break;
      case 'social':
        icon = Icons.people;
        color = AppColors.primary;
        break;
      default:
        icon = Icons.info;
        color = AppColors.primary;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.subheadline.copyWith(
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}