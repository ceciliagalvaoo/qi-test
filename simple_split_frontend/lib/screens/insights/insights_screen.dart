import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../utils/theme.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

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
      final result = await ApiService.get('/insights');
      setState(() {
        _insightsData = result;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar insights: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Insights'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadInsights,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _insightsData == null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadInsights,
                  child: _buildInsights(),
                ),
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
                    title: 'Gastos este mês',
                    value: 'R\$ ${(summary['monthly_expenses'] as num? ?? 0).toStringAsFixed(2)}',
                    color: AppColors.error,
                    icon: Icons.trending_up,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: _buildSummaryItem(
                    title: 'A receber',
                    value: 'R\$ ${(summary['total_receivables'] as num? ?? 0).toStringAsFixed(2)}',
                    color: AppColors.success,
                    icon: Icons.trending_down,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    title: 'A pagar',
                    value: 'R\$ ${(summary['total_debts'] as num? ?? 0).toStringAsFixed(2)}',
                    color: AppColors.warning,
                    icon: Icons.schedule,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: _buildSummaryItem(
                    title: 'Saldo líquido',
                    value: 'R\$ ${(summary['net_balance'] as num? ?? 0).toStringAsFixed(2)}',
                    color: (summary['net_balance'] as num? ?? 0) >= 0 
                        ? AppColors.success 
                        : AppColors.error,
                    icon: Icons.account_balance,
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