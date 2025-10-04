import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../utils/theme.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _myReceivables = [];
  List<Map<String, dynamic>> _availableReceivables = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMarketplaceData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMarketplaceData() async {
    setState(() => _isLoading = true);

    try {
      // Carregar meus recebíveis
      final myReceivablesResult = await ApiService.get('/marketplace/my-receivables');
      // Carregar recebíveis disponíveis
      final availableResult = await ApiService.get('/marketplace/receivables');

      setState(() {
        _myReceivables = List<Map<String, dynamic>>.from(
          myReceivablesResult['receivables'] ?? []
        );
        _availableReceivables = List<Map<String, dynamic>>.from(
          availableResult['receivables'] ?? []
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar marketplace: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _sellReceivable(int receivableId) async {
    final discountController = TextEditingController(text: '5.0');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vender Recebível'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Defina o desconto para venda rápida do seu recebível:',
                style: AppTextStyles.subheadline,
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: discountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Desconto (%)',
                  hintText: '5.0',
                  suffixText: '%',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Desconto é obrigatório';
                  }
                  final discount = double.tryParse(value.replaceAll(',', '.'));
                  if (discount == null || discount < 0 || discount > 50) {
                    return 'Desconto deve estar entre 0% e 50%';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final discount = double.parse(
                  discountController.text.replaceAll(',', '.')
                );
                Navigator.of(context).pop(discount);
              }
            },
            child: const Text('Vender'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await ApiService.post('/marketplace/sell', {
          'receivable_id': receivableId.toString(),
          'discount_percentage': result,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recebível colocado à venda com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );

        _loadMarketplaceData(); // Recarregar dados
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao vender recebível: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _buyReceivable(int receivableId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Comprar Recebível'),
        content: const Text(
          'Confirma a compra deste recebível? O valor será descontado do seu saldo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar Compra'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.post('/marketplace/buy', {
          'receivable_id': receivableId.toString(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recebível comprado com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );

        _loadMarketplaceData(); // Recarregar dados
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao comprar recebível: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Marketplace'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Meus Recebíveis'),
            Tab(text: 'Comprar'),
          ],
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMyReceivablesTab(),
                _buildBuyTab(),
              ],
            ),
    );
  }

  Widget _buildMyReceivablesTab() {
    return RefreshIndicator(
      onRefresh: _loadMarketplaceData,
      child: _myReceivables.isEmpty 
          ? _buildEmptyMyReceivables()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _myReceivables.length,
              itemBuilder: (context, index) {
                final receivable = _myReceivables[index];
                return _buildMyReceivableItem(receivable);
              },
            ),
    );
  }

  Widget _buildEmptyMyReceivables() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: AppColors.onSurfaceVariant.withOpacity(0.5),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Nenhum recebível',
              style: AppTextStyles.headline.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Quando alguém lhe dever dinheiro, você poderá vender o direito de receber aqui',
              style: AppTextStyles.subheadline.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyReceivableItem(Map<String, dynamic> receivable) {
    final amount = (receivable['amount'] as num?)?.toDouble() ?? 0.0;
    final isForSale = receivable['for_sale'] == true;
    final discountPercentage = (receivable['discount_percentage'] as num?)?.toDouble() ?? 0.0;
    final salePrice = amount * (1 - discountPercentage / 100);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${receivable['debtor_name'] ?? 'Devedor'} te deve',
                        style: AppTextStyles.subheadline.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      
                      Text(
                        'Vencimento: ${receivable['due_date'] ?? 'Não definido'}',
                        style: AppTextStyles.caption1.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'R\$ ${amount.toStringAsFixed(2)}',
                      style: AppTextStyles.subheadline.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    if (isForSale)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'À venda',
                          style: AppTextStyles.caption2.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            
            if (isForSale) ...[
              const SizedBox(height: 12),
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preço de venda:',
                      style: AppTextStyles.caption1.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'R\$ ${salePrice.toStringAsFixed(2)}',
                          style: AppTextStyles.subheadline.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        
                        Text(
                          '${discountPercentage.toStringAsFixed(1)}% desconto',
                          style: AppTextStyles.caption1.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _sellReceivable(receivable['id']),
                  icon: const Icon(Icons.sell),
                  label: const Text('Vender Recebível'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBuyTab() {
    return RefreshIndicator(
      onRefresh: _loadMarketplaceData,
      child: _availableReceivables.isEmpty 
          ? _buildEmptyAvailableReceivables()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _availableReceivables.length,
              itemBuilder: (context, index) {
                final receivable = _availableReceivables[index];
                return _buildAvailableReceivableItem(receivable);
              },
            ),
    );
  }

  Widget _buildEmptyAvailableReceivables() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: AppColors.onSurfaceVariant.withOpacity(0.5),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Nenhum recebível disponível',
              style: AppTextStyles.headline.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Quando outros usuários colocarem recebíveis à venda, eles aparecerão aqui',
              style: AppTextStyles.subheadline.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableReceivableItem(Map<String, dynamic> receivable) {
    final originalAmount = (receivable['original_amount'] as num?)?.toDouble() ?? 0.0;
    final salePrice = (receivable['sale_price'] as num?)?.toDouble() ?? 0.0;
    final potentialReturn = ((originalAmount - salePrice) / salePrice * 100);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.monetization_on,
                    color: AppColors.success,
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recebível de ${receivable['debtor_name'] ?? 'Anônimo'}',
                        style: AppTextStyles.subheadline.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      
                      Text(
                        'Score do devedor: ${(receivable['debtor_score'] as num?)?.toStringAsFixed(1) ?? 'N/A'}',
                        style: AppTextStyles.caption1.copyWith(
                          color: AppColors.onSurfaceVariant,
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
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '+${potentialReturn.toStringAsFixed(1)}%',
                    style: AppTextStyles.caption2.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Container(
              width: double.infinity,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Valor original:',
                        style: AppTextStyles.caption1,
                      ),
                      Text(
                        'R\$ ${originalAmount.toStringAsFixed(2)}',
                        style: AppTextStyles.caption1.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Preço com desconto:',
                        style: AppTextStyles.subheadline.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'R\$ ${salePrice.toStringAsFixed(2)}',
                        style: AppTextStyles.subheadline.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Vencimento:',
                        style: AppTextStyles.caption1,
                      ),
                      Text(
                        receivable['due_date'] ?? 'Não definido',
                        style: AppTextStyles.caption1.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _buyReceivable(receivable['id']),
                icon: const Icon(Icons.shopping_cart),
                label: Text('Comprar por R\$ ${salePrice.toStringAsFixed(2)}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}