import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/receivable.dart';
import '../../utils/theme.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  List<MarketplaceItem> _receivables = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReceivables();
  }

  Future<void> _loadReceivables() async {
    try {
      final receivablesData = await ApiService.getMarketplaceReceivables();
      final receivables = receivablesData.map((data) => MarketplaceItem.fromJson(data)).toList();
      setState(() {
        _receivables = receivables;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar recebíveis: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _buyReceivable(MarketplaceItem receivable) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await ApiService.buyReceivable(
        authProvider.user!.id,
        receivable.id,
      );
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recebível comprado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadReceivables(); // Refresh the list
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao comprar recebível: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _receivables.isEmpty
              ? const EmptyState(
                  title: 'Nenhum recebível disponível',
                  subtitle: 'Não há recebíveis disponíveis para compra no momento.',
                  icon: Icons.store_outlined,
                )
              : RefreshIndicator(
                  onRefresh: _loadReceivables,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _receivables.length,
                    itemBuilder: (context, index) {
                      final receivable = _receivables[index];
                      return _ReceivableCard(
                        receivable: receivable,
                        onBuy: () => _buyReceivable(receivable),
                      );
                    },
                  ),
                ),
    );
  }
}

class _ReceivableCard extends StatelessWidget {
  final MarketplaceItem receivable;
  final VoidCallback onBuy;

  const _ReceivableCard({
    super.key,
    required this.receivable,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final discountPercentage = receivable.discountPercentage;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vendedor: ${receivable.sellerAnonymousId}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Score: ${receivable.ownerScore.toStringAsFixed(1)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(receivable.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(receivable.status),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getStatusText(receivable.status),
                    style: TextStyle(
                      color: _getStatusColor(receivable.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _InfoItem(
                    label: 'Valor Nominal',
                    value: 'R\$ ${receivable.nominalAmount.toStringAsFixed(2)}',
                    color: Colors.grey[600]!,
                  ),
                ),
                Expanded(
                  child: _InfoItem(
                    label: 'Preço de Venda',
                    value: 'R\$ ${receivable.sellingPrice.toStringAsFixed(2)}',
                    color: AppColors.primary,
                    isBold: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InfoItem(
                    label: 'Desconto',
                    value: '${discountPercentage.toStringAsFixed(1)}%',
                    color: Colors.green,
                    isBold: true,
                  ),
                ),
                Expanded(
                  child: _InfoItem(
                    label: 'Lucro Estimado',
                    value: 'R\$ ${receivable.profitEstimated.toStringAsFixed(2)}',
                    color: Colors.green,
                    isBold: true,
                  ),
                ),
              ],
            ),
            if (receivable.createdAt != null) ...[
              const SizedBox(height: 12),
              _InfoItem(
                label: 'Disponível desde',
                value: '${receivable.createdAt!.day.toString().padLeft(2, '0')}/${receivable.createdAt!.month.toString().padLeft(2, '0')}/${receivable.createdAt!.year}',
                color: Colors.grey[600]!,
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: receivable.status == 'for_sale' ? onBuy : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  receivable.status == 'for_sale' 
                      ? 'Comprar Recebível'
                      : 'Não Disponível',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'for_sale':
        return Colors.green;
      case 'sold':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'for_sale':
        return 'À Venda';
      case 'sold':
        return 'Vendido';
      case 'cancelled':
        return 'Cancelado';
      default:
        return 'Desconhecido';
    }
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isBold;

  const _InfoItem({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}