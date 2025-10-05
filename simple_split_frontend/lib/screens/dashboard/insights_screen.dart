import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';
import '../../widgets/common/loading_indicator.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _insights = {};

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      
      if (userId != null) {
        // Carregar dados básicos para calcular insights
        final groups = await ApiService.get('/users/$userId/groups');
        final expenses = await ApiService.get('/users/$userId/expenses');
        final debts = await ApiService.get('/users/$userId/debts');

        // Calcular insights
        final insights = _calculateInsights(groups['groups'] ?? [], expenses['expenses'] ?? [], debts['debts'] ?? []);
        
        setState(() {
          _insights = insights;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar insights: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Map<String, dynamic> _calculateInsights(List<dynamic> groups, List<dynamic> expenses, List<dynamic> debts) {
    double totalSpent = 0.0;
    double totalReceivables = 0.0;
    double totalOwed = 0.0;
    int totalExpenses = expenses.length;
    
    for (var expense in expenses) {
      totalSpent += (expense['amount'] as num).toDouble();
    }
    
    for (var debt in debts) {
      if (debt['type'] == 'receivable') {
        totalReceivables += (debt['amount'] as num).toDouble();
      } else if (debt['type'] == 'payable') {
        totalOwed += (debt['amount'] as num).toDouble();
      }
    }

    double netBalance = totalReceivables - totalOwed;
    double avgExpensePerGroup = groups.isNotEmpty ? totalSpent / groups.length : 0.0;
    
    return {
      'totalSpent': totalSpent,
      'totalReceivables': totalReceivables,
      'totalOwed': totalOwed,
      'netBalance': netBalance,
      'totalGroups': groups.length,
      'totalExpenses': totalExpenses,
      'avgExpensePerGroup': avgExpensePerGroup,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const LoadingIndicator()
          : RefreshIndicator(
              onRefresh: _loadInsights,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'Insights Financeiros',
                      style: AppTextStyles.title1.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildFinancialSummary(),
                    const SizedBox(height: 24),
                    _buildExpenseAnalysis(),
                    const SizedBox(height: 24),
                    _buildDebtAnalysis(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFinancialSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.analytics_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Resumo Financeiro',
                  style: AppTextStyles.headline.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildInsightItem(
                    'Total Gasto',
                    'R\$ ${_insights['totalSpent']?.toStringAsFixed(2) ?? '0,00'}',
                    Icons.money_off,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInsightItem(
                    'Saldo Líquido',
                    'R\$ ${_insights['netBalance']?.toStringAsFixed(2) ?? '0,00'}',
                    Icons.account_balance_wallet,
                    (_insights['netBalance'] ?? 0.0) >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInsightItem(
                    'A Receber',
                    'R\$ ${_insights['totalReceivables']?.toStringAsFixed(2) ?? '0,00'}',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInsightItem(
                    'A Pagar',
                    'R\$ ${_insights['totalOwed']?.toStringAsFixed(2) ?? '0,00'}',
                    Icons.trending_down,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseAnalysis() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.receipt_long,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Análise de Gastos',
                  style: AppTextStyles.headline.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildInsightItem(
                    'Total de Grupos',
                    '${_insights['totalGroups'] ?? 0}',
                    Icons.group,
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInsightItem(
                    'Total de Despesas',
                    '${_insights['totalExpenses'] ?? 0}',
                    Icons.receipt,
                    AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInsightItem(
              'Gasto Médio por Grupo',
              'R\$ ${_insights['avgExpensePerGroup']?.toStringAsFixed(2) ?? '0,00'}',
              Icons.calculate,
              Colors.blue,
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtAnalysis() {
    double totalReceivables = _insights['totalReceivables'] ?? 0.0;
    double totalOwed = _insights['totalOwed'] ?? 0.0;
    double total = totalReceivables + totalOwed;
    
    double receivablePercentage = total > 0 ? (totalReceivables / total) * 100 : 0;
    double owedPercentage = total > 0 ? (totalOwed / total) * 100 : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.pie_chart_outline,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Distribuição de Dívidas',
                  style: AppTextStyles.headline.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (total > 0) ...[
              _buildProgressItem(
                'A Receber',
                receivablePercentage,
                Colors.green,
                'R\$ ${totalReceivables.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 16),
              _buildProgressItem(
                'A Pagar',
                owedPercentage,
                Colors.orange,
                'R\$ ${totalOwed.toStringAsFixed(2)}',
              ),
            ] else ...[
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.hourglass_empty,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Nenhuma dívida encontrada',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(String label, String value, IconData icon, Color color, {bool isFullWidth = false}) {
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.caption1.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.headline.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );

    if (isFullWidth) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: content,
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: content,
    );
  }

  Widget _buildProgressItem(String label, double percentage, Color color, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTextStyles.callout.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: AppTextStyles.callout.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
        ),
        const SizedBox(height: 4),
        Text(
          '${percentage.toStringAsFixed(1)}%',
          style: AppTextStyles.caption2.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}