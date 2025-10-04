import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../../models/user.dart';
import 'marketplace_screen.dart';
import 'insights_screen.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _currentIndex = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> _recentExpenses = [];
  List<Map<String, dynamic>> _debts = [];
  double _walletBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      print('[DEBUG] Carregando dados do dashboard...');
      
      final authProvider = context.read<AuthProvider>();
      
      if (!authProvider.isAuthenticated) {
        print('[DEBUG] Usuário não autenticado!');
        setState(() => _isLoading = false);
        return;
      }

      // Carregar dados em paralelo das APIs reais
      final futures = await Future.wait([
        _loadGroups(),
        _loadRecentExpenses(),
        _loadDebts(),
      ]);

      setState(() {
        _groups = futures[0];
        _recentExpenses = futures[1];
        _debts = futures[2];
        
        // Calcular saldo da carteira baseado nas dívidas
        _walletBalance = _calculateWalletBalance();
      });
      
      print('[DEBUG] Dados carregados com sucesso!');
      print('[DEBUG] Grupos: ${_groups.length}, Despesas: ${_recentExpenses.length}, Dívidas: ${_debts.length}');
    } catch (e) {
      print('Erro ao carregar dados do dashboard: $e');
      
      // Em caso de erro, usar dados vazios ao invés de mockados
      setState(() {
        _groups = [];
        _recentExpenses = [];
        _debts = [];
        _walletBalance = 0.0;
      });
    }

    setState(() => _isLoading = false);
  }

  Future<List<Map<String, dynamic>>> _loadGroups() async {
    try {
      print('[DEBUG] Carregando grupos...');
      
      // Por enquanto, usar dados mockados até corrigir as APIs
      await Future.delayed(const Duration(milliseconds: 300));
      
      return [
        {
          'id': '1',
          'name': 'Amigos',
          'members_count': 3,
          'total_expenses': 285.0,
        }
      ];
      
      // TODO: Descomentar quando as APIs estiverem funcionando
      /*
      final response = await ApiService.get('/groups/');
      print('[DEBUG] Resposta grupos: $response');
      
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      } else if (response.containsKey('groups')) {
        final List<dynamic> groups = response['groups'];
        return List<Map<String, dynamic>>.from(groups);
      }
      */
    } catch (e) {
      print('[DEBUG] Erro ao carregar grupos: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> _loadRecentExpenses() async {
    try {
      print('[DEBUG] Carregando despesas recentes...');
      
      // Por enquanto, usar dados mockados
      await Future.delayed(const Duration(milliseconds: 300));
      
      return [
        {
          'id': '1',
          'description': 'Jantar no restaurante',
          'amount': 150.0,
          'payer_name': 'Pablo',
        },
        {
          'id': '2',
          'description': 'Uber para casa',
          'amount': 45.0,
          'payer_name': 'Cecília',
        }
      ];
    } catch (e) {
      print('[DEBUG] Erro ao carregar despesas: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> _loadDebts() async {
    try {
      print('[DEBUG] Carregando dívidas...');
      
      // Por enquanto, usar dados mockados
      await Future.delayed(const Duration(milliseconds: 300));
      
      return [
        {
          'id': '1',
          'amount': 50.0,
          'status': 'pending',
          'debtor_id': '96b93d1e-b336-4f74-94e2-b6cba259f1a2', // Pablo como devedor
          'creditor_id': 'other-user-uuid', // Outro usuário como credor
          'debtor_name': 'Pablo',
          'creditor_name': 'Cecília',
          'expense_description': 'Jantar',
        }
      ];
    } catch (e) {
      print('[DEBUG] Erro ao carregar dívidas: $e');
    }
    return [];
  }

  double _calculateWalletBalance() {
    double balance = 0.0;
    
    try {
      final currentUser = context.read<AuthProvider>().user;
      if (currentUser == null) {
        print('[DEBUG] Usuário não disponível para calcular saldo');
        return 0.0;
      }
      
      for (final debt in _debts) {
        final amount = (debt['amount'] as num?)?.toDouble() ?? 0.0;
        final status = debt['status'] as String? ?? '';
        
        if (status == 'pending') {
          // Verificar se os campos existem antes de comparar
          final creditorId = debt['creditor_id'];
          if (creditorId != null) {
            final isCreditor = creditorId.toString() == currentUser.id;
            balance += isCreditor ? amount : -amount;
          }
        }
      }
    } catch (e) {
      print('[DEBUG] Erro ao calcular saldo da carteira: $e');
      return 0.0;
    }
    
    return balance;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _buildDashboard(user),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildDashboard(User? user) {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab(user);
      case 1:
        return _buildGroupsTab();
      case 2:
        return _buildMarketplaceTab();
      case 3:
        return _buildInsightsTab();
      case 4:
        return _buildProfileTab(user);
      default:
        return _buildHomeTab(user);
    }
  }

  Widget _buildHomeTab(User? user) {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Olá, ${user?.name.split(' ').first ?? 'Usuário'}!',
                style: AppTextStyles.title2.copyWith(color: Colors.white),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () {
                  // TODO: Implementar notificações
                },
              ),
            ],
          ),
          
          // Conteúdo
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Card de saldo
                _buildBalanceCard(),
                
                const SizedBox(height: 16),
                
                // Ações rápidas
                _buildQuickActions(),
                
                const SizedBox(height: 24),
                
                // Grupos recentes
                _buildRecentGroups(),
                
                const SizedBox(height: 24),
                
                // Despesas recentes
                _buildRecentExpenses(),
                
                const SizedBox(height: 24),
                
                // Dívidas pendentes
                _buildPendingDebts(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    final isPositive = _walletBalance >= 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive 
              ? [AppColors.success, AppColors.success.withOpacity(0.8)]
              : [AppColors.error, AppColors.error.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isPositive ? AppColors.success : AppColors.error).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saldo Geral',
                style: AppTextStyles.subheadline.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: Colors.white,
                size: 24,
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'R\$ ${_walletBalance.abs().toStringAsFixed(2)}',
            style: AppTextStyles.title1.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 32,
            ),
          ),
          
          const SizedBox(height: 4),
          
          Text(
            isPositive ? 'Você tem a receber' : 'Você deve',
            style: AppTextStyles.caption1.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.group_add,
            title: 'Criar Grupo',
            onTap: () => context.go('/groups'),
          ),
        ),
        
        const SizedBox(width: 12),
        
        Expanded(
          child: _buildActionButton(
            icon: Icons.receipt_long,
            title: 'Nova Despesa',
            onTap: () => context.go('/groups'), // Vai para grupos para selecionar
          ),
        ),
        
        const SizedBox(width: 12),
        
        Expanded(
          child: _buildActionButton(
            icon: Icons.storefront,
            title: 'Marketplace',
            onTap: () => setState(() => _currentIndex = 2),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                title,
                style: AppTextStyles.caption1.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentGroups() {
    if (_groups.isEmpty) {
      return _buildEmptyState(
        icon: Icons.group,
        title: 'Nenhum grupo ainda',
        subtitle: 'Crie seu primeiro grupo para começar',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Meus Grupos', style: AppTextStyles.headline),
            TextButton(
              onPressed: () => context.go('/groups'),
              child: const Text('Ver todos'),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _groups.length,
            itemBuilder: (context, index) {
              final group = _groups[index];
              return _buildGroupCard(group);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group['name'] ?? 'Grupo sem nome',
            style: AppTextStyles.subheadline.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            '${group['members_count'] ?? 0} membros',
            style: AppTextStyles.caption1.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          
          const Spacer(),
          
          Text(
            'R\$ ${(group['total_expenses'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
            style: AppTextStyles.subheadline.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentExpenses() {
    if (_recentExpenses.isEmpty) {
      return _buildEmptyState(
        icon: Icons.receipt,
        title: 'Nenhuma despesa ainda',
        subtitle: 'Adicione despesas aos seus grupos',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Despesas Recentes', style: AppTextStyles.headline),
        const SizedBox(height: 12),
        
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _recentExpenses.take(3).length,
          itemBuilder: (context, index) {
            final expense = _recentExpenses[index];
            return _buildExpenseItem(expense);
          },
        ),
      ],
    );
  }

  Widget _buildExpenseItem(Map<String, dynamic> expense) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.receipt_outlined,
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
                  expense['description'] ?? 'Despesa sem descrição',
                  style: AppTextStyles.subheadline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                Text(
                  'Pago por ${expense['payer_name'] ?? 'Desconhecido'}',
                  style: AppTextStyles.caption1.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          
          Text(
            'R\$ ${(expense['amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
            style: AppTextStyles.subheadline.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingDebts() {
    final pendingDebts = _debts.where((debt) => debt['status'] == 'pending').toList();
    
    if (pendingDebts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle,
        title: 'Todas as contas em dia!',
        subtitle: 'Não há dívidas pendentes',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Dívidas Pendentes', style: AppTextStyles.headline),
        const SizedBox(height: 12),
        
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: pendingDebts.take(3).length,
          itemBuilder: (context, index) {
            final debt = pendingDebts[index];
            return _buildDebtItem(debt);
          },
        ),
      ],
    );
  }

  Widget _buildDebtItem(Map<String, dynamic> debt) {
    final currentUserId = context.read<AuthProvider>().user?.id;
    final debtorId = debt['debtor_id'];
    final isDebtor = currentUserId != null && debtorId != null && debtorId.toString() == currentUserId;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isDebtor ? AppColors.error : AppColors.success).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isDebtor ? AppColors.error : AppColors.success).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isDebtor ? Icons.arrow_upward : Icons.arrow_downward,
              color: isDebtor ? AppColors.error : AppColors.success,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDebtor 
                      ? 'Você deve para ${debt['creditor_name'] ?? 'Alguém'}'
                      : '${debt['debtor_name'] ?? 'Alguém'} deve para você',
                  style: AppTextStyles.subheadline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                Text(
                  debt['expense_description'] ?? 'Despesa',
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
                'R\$ ${(debt['amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                style: AppTextStyles.subheadline.copyWith(
                  color: isDebtor ? AppColors.error : AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              if (isDebtor)
                TextButton(
                  onPressed: () {
                    // TODO: Implementar pagamento
                  },
                  style: TextButton.styleFrom(
                    minimumSize: const Size(60, 30),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  child: const Text('Pagar', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: AppColors.onSurfaceVariant,
          ),
          
          const SizedBox(height: 16),
          
          Text(
            title,
            style: AppTextStyles.subheadline.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
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

  Widget _buildGroupsTab() {
    return const Center(child: Text('Grupos - Em construção'));
  }

  Widget _buildMarketplaceTab() {
    return const MarketplaceScreen();
  }

  Widget _buildInsightsTab() {
    return const InsightsScreen();
  }

  Widget _buildProfileTab(User? user) {
    return const Center(child: Text('Perfil - Em construção'));
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
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
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    );
  }
}