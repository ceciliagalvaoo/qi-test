import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';
import '../../widgets/common/loading_indicator.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _myReceivables = {'selling': [], 'bought': []};
  List<Map<String, dynamic>> _marketplaceItems = [];
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _myDebts = [];
  
  // Filtros
  String _currentFilter = 'todos'; // 'todos', 'maior_valor', 'menor_valor', 'maior_desconto'
  List<Map<String, dynamic>> _filteredMarketplaceItems = [];

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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;

      final futures = await Future.wait([
        ApiService.get('/marketplace/'),          // Itens disponíveis
        ApiService.get('/marketplace/my-receivables'), // Meus recebíveis
        ApiService.get('/marketplace/stats'),     // Estatísticas
        ApiService.get('/debts/consolidated'),    // Minhas dívidas consolidadas (para vender)
      ]);

      setState(() {
        // futures[0] é uma lista diretamente da API marketplace
        _marketplaceItems = futures[0] is List 
            ? List<Map<String, dynamic>>.from(futures[0]) 
            : [];
        _myReceivables = futures[1] ?? {'selling': [], 'bought': []};
        _stats = futures[2] ?? {};
        // futures[3] é da API debts/consolidated que retorna {debts: [...], total_count: N}
        if (futures[3] is Map && futures[3]['debts'] != null) {
          _myDebts = List<Map<String, dynamic>>.from(futures[3]['debts'])
              .where((debt) => 
                  debt['creditor_id'] == userId && 
                  debt['status'] == 'pending')
              .toList();
        } else if (futures[3] is List) {
          _myDebts = List<Map<String, dynamic>>.from(futures[3])
              .where((debt) => 
                  debt['creditor_id'] == userId && 
                  debt['status'] == 'pending')
              .toList();
        } else {
          _myDebts = [];
        }
        
        // Aplicar filtro inicial
        _applyFilter();
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

  void _applyFilter() {
    List<Map<String, dynamic>> items = List.from(_marketplaceItems);
    
    switch (_currentFilter) {
      case 'maior_valor':
        items.sort((a, b) => (b['nominal_amount'] ?? 0.0).compareTo(a['nominal_amount'] ?? 0.0));
        break;
      case 'menor_valor':
        items.sort((a, b) => (a['nominal_amount'] ?? 0.0).compareTo(b['nominal_amount'] ?? 0.0));
        break;
      case 'maior_desconto':
        items.sort((a, b) {
          double discountA = (a['nominal_amount'] ?? 0.0) - (a['selling_price'] ?? 0.0);
          double discountB = (b['nominal_amount'] ?? 0.0) - (b['selling_price'] ?? 0.0);
          return discountB.compareTo(discountA);
        });
        break;
      case 'todos':
      default:
        // Manter ordem original
        break;
    }
    
    _filteredMarketplaceItems = items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Marketplace'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.shopping_cart), text: 'Comprar Títulos'),
            Tab(icon: Icon(Icons.account_balance_wallet), text: 'Meus Títulos'),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      body: _isLoading 
          ? const Center(child: LoadingIndicator())
          : Column(
              children: [
                _buildStatsCard(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMarketplaceTab(),
                      _buildMyTitlesTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsCard() {
    final totalTitles = _stats['total_titles_for_sale'] ?? 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Títulos disponíveis
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Títulos Disponíveis',
                style: AppTextStyles.caption1.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$totalTitles',
                style: AppTextStyles.largeTitle.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          // Filtro
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: _currentFilter,
              underline: Container(),
              dropdownColor: AppColors.primary,
              iconEnabledColor: Colors.white,
              style: AppTextStyles.body.copyWith(color: Colors.white),
              items: const [
                DropdownMenuItem(value: 'todos', child: Text('Todos')),
                DropdownMenuItem(value: 'maior_valor', child: Text('Maior Valor')),
                DropdownMenuItem(value: 'menor_valor', child: Text('Menor Valor')),
                DropdownMenuItem(value: 'maior_desconto', child: Text('Maior Desconto')),
              ],
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _currentFilter = newValue;
                    _applyFilter();
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketplaceTab() {
    return RefreshIndicator(
      onRefresh: _loadMarketplaceData,
      child: _filteredMarketplaceItems.isEmpty 
          ? _buildEmptyMarketplace()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredMarketplaceItems.length,
              itemBuilder: (context, index) {
                final item = _filteredMarketplaceItems[index];
                return _buildMarketplaceItem(item);
              },
            ),
    );
  }

  Widget _buildEmptyMarketplace() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store_outlined,
              size: 80,
              color: AppColors.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum título disponível',
              style: AppTextStyles.headline.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Quando houver títulos de recebíveis à venda, eles aparecerão aqui',
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

  Widget _buildMarketplaceItem(Map<String, dynamic> item) {
    final nominalAmount = (item['nominal_amount'] ?? 0.0).toDouble();
    final sellingPrice = (item['selling_price'] ?? 0.0).toDouble();
    final discount = nominalAmount - sellingPrice;
    final discountPercent = nominalAmount > 0 ? (discount / nominalAmount) * 100 : 0;
    final ownerScore = (item['owner_score'] ?? 0.0).toDouble();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showBuyDialog(item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.monetization_on,
                      color: AppColors.success,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Título de Recebível',
                          style: AppTextStyles.subheadline.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 16,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Score: ${ownerScore.toStringAsFixed(1)}',
                              style: AppTextStyles.caption1.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${discountPercent.toStringAsFixed(1)}% OFF',
                      style: AppTextStyles.caption1.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Valor Original',
                          style: AppTextStyles.caption1.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          'R\$ ${nominalAmount.toStringAsFixed(2)}',
                          style: AppTextStyles.subheadline.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.arrow_forward,
                      color: AppColors.onSurfaceVariant,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Preço de Venda',
                          style: AppTextStyles.caption1.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          'R\$ ${sellingPrice.toStringAsFixed(2)}',
                          style: AppTextStyles.headline.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Lucro potencial: R\$ ${discount.toStringAsFixed(2)}',
                    style: AppTextStyles.caption1.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyTitlesTab() {
    final selling = List<Map<String, dynamic>>.from(_myReceivables['selling'] ?? []);
    final bought = List<Map<String, dynamic>>.from(_myReceivables['bought'] ?? []);
    final sold = List<Map<String, dynamic>>.from(_myReceivables['sold'] ?? []);

    return RefreshIndicator(
      onRefresh: _loadMarketplaceData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSellSection(),
            const SizedBox(height: 24),
            _buildMySellingSection(selling),
            const SizedBox(height: 24),
            _buildMyBoughtSection(bought),
            const SizedBox(height: 24),
            _buildMySoldSection(sold),
          ],
        ),
      ),
    );
  }

  Widget _buildSellSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.sell,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Vender Títulos',
                    style: AppTextStyles.headline.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'Transforme suas dívidas em dinheiro agora',
              style: AppTextStyles.subheadline.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 16),

            _myDebts.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.onSurfaceVariant,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Nenhuma dívida disponível para venda',
                            style: AppTextStyles.caption1.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: _myDebts.map((debt) => _buildDebtToSell(debt)).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtToSell(Map<String, dynamic> debt) {
    final amount = (debt['amount'] ?? 0.0).toDouble();
    final debtorName = debt['debtor_name'] ?? 'Devedor';

    return GestureDetector(
      onTap: () => _showDebtDetailsModal(debt),
      child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.onSurfaceVariant.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  debtorName,
                  style: AppTextStyles.subheadline.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'R\$ ${amount.toStringAsFixed(2)}',
                  style: AppTextStyles.headline.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showSellDialog(debt),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Vender'),
          ),
        ],
      ),
    ));
  }

  Widget _buildMySellingSection(List<Map<String, dynamic>> selling) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.storefront,
                  color: AppColors.warning,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Vendendo (${selling.length})',
                  style: AppTextStyles.headline.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            selling.isEmpty
                ? _buildEmptyState(
                    icon: Icons.storefront_outlined,
                    title: 'Nenhum título à venda',
                    subtitle: 'Seus títulos à venda aparecerão aqui',
                  )
                : Column(
                    children: selling.map((item) => _buildMySellingItem(item)).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyBoughtSection(List<Map<String, dynamic>> bought) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.shopping_bag,
                  color: AppColors.success,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Comprados (${bought.length})',
                  style: AppTextStyles.headline.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            bought.isEmpty
                ? _buildEmptyState(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Nenhum título comprado',
                    subtitle: 'Seus títulos comprados aparecerão aqui',
                  )
                : Column(
                    children: bought.map((item) => _buildMyBoughtItem(item)).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildMySoldSection(List<Map<String, dynamic>> sold) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Títulos Vendidos (${sold.length})',
                  style: AppTextStyles.headline.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            sold.isEmpty
                ? _buildEmptyState(
                    icon: Icons.check_circle_outlined,
                    title: 'Nenhum título vendido',
                    subtitle: 'Seus títulos vendidos aparecerão aqui',
                  )
                : Column(
                    children: sold.map((item) => _buildMySoldItem(item)).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildMySoldItem(Map<String, dynamic> item) {
    final nominalAmount = (item['nominal_amount'] ?? 0.0).toDouble();
    final sellingPrice = (item['selling_price'] ?? 0.0).toDouble();
    final discount = nominalAmount - sellingPrice;

    return GestureDetector(
      onTap: () => _showTitleDetailsModal(item, 'sold'),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.check_circle,
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
                  'Vendido por R\$ ${sellingPrice.toStringAsFixed(2)}',
                  style: AppTextStyles.subheadline.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (item['buyer_name'] != null)
                  Text(
                    'Comprador: ${item['buyer_name']}',
                    style: AppTextStyles.body.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                Text(
                  'Desconto concedido: R\$ ${discount.toStringAsFixed(2)}',
                  style: AppTextStyles.caption1.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Vendido',
              style: AppTextStyles.caption2.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: AppColors.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTextStyles.subheadline.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.caption1.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMySellingItem(Map<String, dynamic> item) {
    final nominalAmount = (item['nominal_amount'] ?? 0.0).toDouble();
    final sellingPrice = (item['selling_price'] ?? 0.0).toDouble();
    final discount = nominalAmount - sellingPrice;

    return GestureDetector(
      onTap: () => _showTitleDetailsModal(item, 'selling'),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.warning.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.sell,
              color: AppColors.warning,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'R\$ ${sellingPrice.toStringAsFixed(2)}',
                  style: AppTextStyles.subheadline.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (item['debtor_name'] != null)
                  Text(
                    item['debtor_name'],
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                Text(
                  'Desconto: R\$ ${discount.toStringAsFixed(2)}',
                  style: AppTextStyles.caption1.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          
          TextButton(
            onPressed: () => _cancelSale(item['id']),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildMyBoughtItem(Map<String, dynamic> item) {
    final nominalAmount = (item['nominal_amount'] ?? 0.0).toDouble();
    final sellingPrice = (item['selling_price'] ?? 0.0).toDouble();
    final profit = nominalAmount - sellingPrice;

    return GestureDetector(
      onTap: () => _showTitleDetailsModal(item, 'bought'),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.success.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.check_circle,
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
                  'Comprado por R\$ ${sellingPrice.toStringAsFixed(2)}',
                  style: AppTextStyles.subheadline.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (item['debtor_name'] != null)
                  Text(
                    'Devedor: ${item['debtor_name']}',
                    style: AppTextStyles.body.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                Text(
                  'Lucro potencial: R\$ ${profit.toStringAsFixed(2)}',
                  style: AppTextStyles.caption1.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Comprado',
              style: AppTextStyles.caption2.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ));
  }

  Future<void> _showBuyDialog(Map<String, dynamic> item) async {
    final nominalAmount = (item['nominal_amount'] ?? 0.0).toDouble();
    final sellingPrice = (item['selling_price'] ?? 0.0).toDouble();
    final profit = nominalAmount - sellingPrice;
    final ownerScore = (item['owner_score'] ?? 0.0).toDouble();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Comprar Título'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDialogRow('Valor Original:', 'R\$ ${nominalAmount.toStringAsFixed(2)}'),
            _buildDialogRow('Preço de Compra:', 'R\$ ${sellingPrice.toStringAsFixed(2)}', highlight: true),
            _buildDialogRow('Lucro Potencial:', 'R\$ ${profit.toStringAsFixed(2)}', success: true),
            _buildDialogRow('Score do Vendedor:', '${ownerScore.toStringAsFixed(1)}/10'),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'O valor será descontado do seu saldo imediatamente',
                      style: AppTextStyles.caption1.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Comprar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _buyReceivable(item['id']);
    }
  }

  Future<void> _showSellDialog(Map<String, dynamic> debt) async {
    final amount = (debt['amount'] ?? 0.0).toDouble();
    final discountController = TextEditingController(text: '5.0');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Vender Título'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dívida de R\$ ${amount.toStringAsFixed(2)}',
                style: AppTextStyles.subheadline.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Defina o desconto para venda rápida:',
                style: AppTextStyles.caption1,
              ),
              
              const SizedBox(height: 8),
              
              TextFormField(
                controller: discountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Desconto (%)',
                  hintText: '5.0',
                  suffixText: '%',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
              
              const SizedBox(height: 12),
              
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: discountController,
                builder: (context, value, _) {
                  final discount = double.tryParse(value.text.replaceAll(',', '.')) ?? 0;
                  final sellingPrice = amount * (1 - discount / 100);
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Você receberá:'),
                            Text(
                              'R\$ ${sellingPrice.toStringAsFixed(2)}',
                              style: AppTextStyles.subheadline.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
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
                final sellingPrice = amount * (1 - discount / 100);
                Navigator.of(context).pop(sellingPrice);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Vender'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _sellReceivable(debt['id'], result);
    }
  }

  Widget _buildDialogRow(String label, String value, {bool highlight = false, bool success = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.caption1.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.subheadline.copyWith(
              fontWeight: highlight || success ? FontWeight.bold : FontWeight.w500,
              color: success ? AppColors.success : 
                     highlight ? AppColors.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _buyReceivable(String receivableId) async {
    try {
      await ApiService.post('/marketplace/buy/$receivableId', {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Título comprado com sucesso!'),
          backgroundColor: AppColors.success,
        ),
      );

      _loadMarketplaceData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao comprar título: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _sellReceivable(String debtId, double sellingPrice) async {
    try {
      await ApiService.post('/marketplace/sell', {
        'debt_id': debtId,
        'selling_price': sellingPrice,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Título colocado à venda com sucesso!'),
          backgroundColor: AppColors.success,
        ),
      );

      _loadMarketplaceData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao vender título: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _cancelSale(String receivableId) async {
    try {
      await ApiService.delete('/marketplace/cancel/$receivableId');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Venda cancelada com sucesso!'),
          backgroundColor: AppColors.success,
        ),
      );

      _loadMarketplaceData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao cancelar venda: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _showTitleDetailsModal(Map<String, dynamic> item, String type) async {
    final nominalAmount = (item['nominal_amount'] ?? 0.0).toDouble();
    final sellingPrice = (item['selling_price'] ?? 0.0).toDouble();
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_getTitleByType(type)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Valor Original:', 'R\$ ${nominalAmount.toStringAsFixed(2)}'),
              _buildDetailRow('Preço de Venda:', 'R\$ ${sellingPrice.toStringAsFixed(2)}'),
              
              if (type == 'selling') ...[
                _buildDetailRow('Desconto:', 'R\$ ${(nominalAmount - sellingPrice).toStringAsFixed(2)}'),
                if (item['debtor_name'] != null)
                  _buildDetailRow('Quem deve:', item['debtor_name']),
              ],
              
              if (type == 'bought') ...[
                _buildDetailRow('Lucro Potencial:', 'R\$ ${(nominalAmount - sellingPrice).toStringAsFixed(2)}'),
                if (item['debtor_name'] != null)
                  _buildDetailRow('Devedor:', item['debtor_name']),
                if (item['owner_name'] != null)
                  _buildDetailRow('Vendedor Original:', item['owner_name']),
              ],
              
              if (type == 'sold') ...[
                _buildDetailRow('Desconto Concedido:', 'R\$ ${(nominalAmount - sellingPrice).toStringAsFixed(2)}'),
                if (item['buyer_name'] != null)
                  _buildDetailRow('Comprador:', item['buyer_name']),
                if (item['debtor_name'] != null)
                  _buildDetailRow('Devedor:', item['debtor_name']),
              ],
              
              const SizedBox(height: 16),
              
              if (item['created_at'] != null)
                _buildDetailRow('Data de Criação:', _formatDate(item['created_at'])),
              
              if (item['sold_at'] != null && type != 'selling')
                _buildDetailRow('Data da Venda:', _formatDate(item['sold_at'])),
              
              _buildDetailRow('Status:', _getStatusText(type, item['status'])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTitleByType(String type) {
    switch (type) {
      case 'selling':
        return 'Título à Venda';
      case 'bought':
        return 'Título Comprado';
      case 'sold':
        return 'Título Vendido';
      default:
        return 'Detalhes do Título';
    }
  }

  String _getStatusText(String type, String? status) {
    switch (type) {
      case 'selling':
        return 'À venda';
      case 'bought':
        return 'Comprado';
      case 'sold':
        return 'Vendido';
      default:
        return status ?? 'N/A';
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Data inválida';
    }
  }

  Future<void> _showDebtDetailsModal(Map<String, dynamic> debt) async {
    final amount = (debt['amount'] ?? 0.0).toDouble();
    final debtorName = debt['other_user'] ?? debt['debtor_name'] ?? 'Devedor';
    final description = debt['expense_description'] ?? 'N/A';
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Detalhes da Dívida'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Quem deve:', debtorName),
              _buildDetailRow('Valor total:', 'R\$ ${amount.toStringAsFixed(2)}'),
              _buildDetailRow('Descrição:', description),
              _buildDetailRow('Status:', 'Pendente'),
              
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sobre vender títulos:',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Você pode transformar essa dívida em dinheiro imediatamente, vendendo por um valor menor. Outros usuários compram esperando lucrar quando o devedor pagar.',
                      style: AppTextStyles.caption1.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showSellDialog(debt);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Vender Título'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: 2, // Marketplace está no índice 2
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/dashboard');
            break;
          case 1:
            context.go('/groups');
            break;
          case 2:
            // Já está no marketplace
            break;
          case 3:
            context.go('/insights');
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
      selectedLabelStyle: AppTextStyles.caption2.copyWith(
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: AppTextStyles.caption2,
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
          icon: Icon(Icons.person_outlined),
          activeIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    );
  }
}