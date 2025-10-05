import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../marketplace/marketplace_screen.dart';
import '../insights/insights_screen.dart';
import '../user/user_screen.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> _recentExpenses = [];
  List<Map<String, dynamic>> _debts = [];
  double _walletBalance = 0.0; // Saldo real da carteira
  double _totalOwed = 0.0; // Total que você deve
  double _totalToReceive = 0.0; // Total a receber

  User? _lastUser; // Para detectar mudanças no usuário


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App voltou ao primeiro plano, recarregar dados
      _loadDashboardData();
    }
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);

    try {
      print('[DEBUG] Carregando dados do dashboard...');
      
      final authProvider = context.read<AuthProvider>();
      
      if (!authProvider.isAuthenticated || authProvider.user == null) {
        print('[DEBUG] Usuário não autenticado!');
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      final currentUser = authProvider.user!;
      print('[DEBUG] Usuário logado: ${currentUser.name} (ID: ${currentUser.id})');

      // Carregar dados em paralelo das APIs reais
      final futures = await Future.wait([
        _loadGroups(),
        _loadInsights(), // Usar API de insights que já funciona
        _loadWalletBalance(), // Carregar saldo real da carteira
      ]);

      if (mounted) {
        final insightsData = futures[1] as Map<String, dynamic>;
        
        setState(() {
          _groups = futures[0] as List<Map<String, dynamic>>;
          
          // Usar nova API categorizadas
          final youOweList = insightsData['you_owe'] as List<dynamic>? ?? [];
          final othersOweYouList = insightsData['others_owe_you'] as List<dynamic>? ?? [];
          
          _recentExpenses = []; // Despesas Pendentes (o que EU devo)
          _debts = []; // Dívidas Pendentes (o que devem A MIM)
          
          // Processar dívidas que EU devo
          for (var debt in youOweList) {
            final debtMap = Map<String, dynamic>.from(debt as Map);
            _recentExpenses.add(debtMap);
          }
          
          // Processar dívidas que outros devem A MIM
          for (var debt in othersOweYouList) {
            final debtMap = Map<String, dynamic>.from(debt as Map);
            _debts.add(debtMap);
          }
          
          // Usar totais ajustados da API se disponíveis
          _totalOwed = (insightsData['total_you_owe'] as num?)?.toDouble() ?? 0.0;
          _totalToReceive = (insightsData['total_others_owe'] as num?)?.toDouble() ?? 0.0;
          print('[DEBUG] Totais da API - Você deve: $_totalOwed, A receber: $_totalToReceive');
          
          _walletBalance = futures[2] as double;
          _isLoading = false;
        });
      }
      
      print('[DEBUG] Dados carregados com sucesso!');
      print('[DEBUG] Grupos: ${_groups.length}, Despesas: ${_recentExpenses.length}, Dívidas: ${_debts.length}');
      print('[DEBUG] Saldo calculado: $_walletBalance');
    } catch (e) {
      print('❌ Erro ao carregar dados do dashboard: $e');
      
      // Em caso de erro, usar dados vazios ao invés de mockados
      if (mounted) {
        setState(() {
          _groups = [];
          _recentExpenses = [];
          _debts = [];
          _walletBalance = 0.0;

          _isLoading = false;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _loadGroups() async {
    try {
      print('[DEBUG] Carregando grupos...');
      
      final response = await ApiService.get('/groups/');
      print('[DEBUG] Resposta grupos: $response');
      
      if (response.containsKey('groups')) {
        final List<dynamic> groups = response['groups'];
        print('[DEBUG] Grupos recebidos: ${groups.length}');
        for (int i = 0; i < groups.length; i++) {
          final group = groups[i];
          print('[DEBUG] Grupo $i: ${group['name']} - members_count: ${group['members_count']} - expenses_count: ${group['expenses_count']} - total_expenses: ${group['total_expenses']}');
        }
        // Conversão segura de tipos
        return groups.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      } else {
        print('[DEBUG] Resposta não contém "groups": $response');
        return [];
      }
    } catch (e) {
      print('[DEBUG] Erro ao carregar grupos: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> _loadInsights() async {
    try {
      print('[DEBUG] Carregando insights categorizados...');
      
      // Usar API de insights que mantém os valores otimizados (com timestamp para evitar cache)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await ApiService.get('/insights/debts-categorized?t=$timestamp');
      print('[DEBUG] Resposta insights: $response');
      
      if (response != null) {
        print('[DEBUG] Campos da resposta insights: ${response.keys}');
        print('[DEBUG] total_you_owe: ${response['total_you_owe']}');
        print('[DEBUG] total_others_owe: ${response['total_others_owe']}');
        
        return {
          'you_owe': response['you_owe'] ?? [],
          'others_owe_you': response['others_owe_you'] ?? [],
          'total_you_owe': response['total_you_owe'] ?? 0.0,
          'total_others_owe': response['total_others_owe'] ?? 0.0,
        };
      } else {
        print('[DEBUG] Resposta inesperada da API: $response');
        return {'you_owe': [], 'others_owe_you': []};
      }
    } catch (e) {
      print('[DEBUG] Erro ao carregar insights: $e');
      return {'you_owe': [], 'others_owe_you': []};
    }
  }



  Future<double> _loadWalletBalance() async {
    try {
      print('[DEBUG] Carregando saldo da carteira...');
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await ApiService.get('/user/profile?t=$timestamp');
      print('[DEBUG] Resposta perfil: $response');
      

      
      // Verificar se tem dados de wallet
      if (response is Map<String, dynamic> && 
          response.containsKey('wallet') && 
          response['wallet'] is Map<String, dynamic>) {
        final walletData = response['wallet'] as Map<String, dynamic>;
        final balance = (walletData['balance'] as num?)?.toDouble() ?? 0.0;
        print('[DEBUG] Saldo da carteira carregado: R\$ $balance');
        return balance;
      }
      
      print('[DEBUG] Dados de carteira não encontrados na resposta');
      return 0.0;
      
    } catch (e) {
      print('[DEBUG] Erro ao carregar saldo da carteira: $e');
      return 0.0;
    }
  }



  Future<void> _showNotifications() async {
    try {
      // Buscar dívidas pendentes do usuário atual
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.user;
      
      if (currentUser == null) return;
      
      // Usar as dívidas já carregadas no dashboard
      final userDebts = _debts.where((debt) {
        final creditorId = debt['creditor_id']?.toString();
        final debtorId = debt['debtor_id']?.toString();
        final status = debt['status']?.toString() ?? '';
        
        // Mostrar dívidas pendentes onde o usuário está envolvido
        return status == 'pending' && 
               (creditorId == currentUser.id || debtorId == currentUser.id);
      }).toList();
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => _buildNotificationsDialog(userDebts),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar notificações: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildNotificationsDialog(List<Map<String, dynamic>> debts) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.notifications, color: AppColors.primary),
          const SizedBox(width: 8),
          const Text('Notificações'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: debts.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Nenhuma notificação pendente',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView(
              children: [
                const Text(
                  'Dívidas Pendentes',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                ...debts.map((debt) => _buildDebtNotification(debt)),
              ],
            ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }

  Widget _buildDebtNotification(Map<String, dynamic> debt) {
    final amount = (debt['amount'] as num?)?.toDouble() ?? 0.0;
    final creditorName = debt['creditor_name']?.toString() ?? 'Usuário';
    final debtorName = debt['debtor_name']?.toString() ?? 'Usuário';
    final groupName = debt['group_name']?.toString() ?? 'Grupo';
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.user;
    
    if (currentUser == null) return const SizedBox();
    
    final isCreditor = debt['creditor_id']?.toString() == currentUser.id;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCreditor ? Colors.green : Colors.orange,
          child: Icon(
            isCreditor ? Icons.arrow_downward : Icons.arrow_upward,
            color: Colors.white,
          ),
        ),
        title: Text(
          isCreditor 
            ? '$debtorName deve R\$ ${amount.toStringAsFixed(2)} para você'
            : 'Você deve R\$ ${amount.toStringAsFixed(2)} para $creditorName',
          style: const TextStyle(fontSize: 14),
        ),
        subtitle: Text('Grupo: $groupName'),
        onTap: () {
          Navigator.of(context).pop();
          context.go('/groups'); // Navegar para grupos para resolver
        },
      ),
    );
  }

  void _showCreateExpenseModal() {
    if (_groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você precisa estar em pelo menos um grupo para criar uma despesa'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCreateExpenseModal(),
    );
  }

  Widget _buildCreateExpenseModal() {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    String? selectedGroupId;

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nova Despesa',
                    style: AppTextStyles.headline,
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Seletor de grupo
              const Text('Grupo', style: AppTextStyles.subheadline),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedGroupId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Selecione um grupo',
                ),
                items: _groups.map((group) {
                  return DropdownMenuItem<String>(
                    value: group['id'].toString(),
                    child: Text(group['name'] ?? 'Grupo sem nome'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedGroupId = value;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Descrição
              const Text('Descrição', style: AppTextStyles.subheadline),
              const SizedBox(height: 8),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Jantar no restaurante',
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Valor
              const Text('Valor', style: AppTextStyles.subheadline),
              const SizedBox(height: 8),
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '0,00',
                  prefixText: 'R\$ ',
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Botão criar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (selectedGroupId == null || 
                        descriptionController.text.isEmpty || 
                        amountController.text.isEmpty) {
                      return;
                    }

                    try {
                      final amount = double.parse(amountController.text.replaceAll(',', '.'));
                      
                      await ApiService.post('/groups/$selectedGroupId/expenses', {
                        'description': descriptionController.text,
                        'amount': amount,
                      });

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Despesa criada com sucesso!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        _loadDashboardData(); // Recarregar dados
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erro ao criar despesa: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Criar Despesa'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        
        // Se o usuário mudou (por exemplo, dados atualizados), recarregar dashboard
        if (_lastUser != user && user != null) {
          _lastUser = user;
          // Agendar reload para o próximo frame para evitar build durante build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _loadDashboardData();
          });
        }
        
        // Se ainda está carregando ou não há usuário, mostrar loading
        if (_isLoading || authProvider.isLoading) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Carregando dashboard...'),
                ],
              ),
            ),
          );
        }
        
        // Se não está autenticado, não deveria estar aqui
        if (!authProvider.isAuthenticated || user == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: const Center(
              child: Text('Erro: Usuário não autenticado'),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: _buildDashboard(user),
          bottomNavigationBar: _buildBottomNavigationBar(),
        );
      },
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
            centerTitle: true,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
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
                onPressed: _showNotifications,
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
                
                // Resumo financeiro
                _buildFinancialSummary(),
                
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
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
                'Saldo da Carteira',
                style: AppTextStyles.subheadline.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 24,
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'R\$ ${_walletBalance.toStringAsFixed(2)}',
            style: AppTextStyles.title1.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 32,
            ),
          ),
          
          const SizedBox(height: 4),
          
          Text(
            'Disponível para usar',
            style: AppTextStyles.caption1.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    // Usar dados da API do perfil em vez de calcular manualmente
    // SEMPRE usar valores das APIs de insights (já considera pagamentos individuais)
    double totalReceivable = _totalToReceive;
    double totalPayable = _totalOwed;
    
    print('[DEBUG] Cards usando - A receber: R\$ ${totalReceivable.toStringAsFixed(2)}, A pagar: R\$ ${totalPayable.toStringAsFixed(2)}');
    
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'A Receber',
            value: 'R\$ ${totalReceivable.toStringAsFixed(2)}',
            icon: Icons.trending_up,
            color: AppColors.success,
          ),
        ),
        
        const SizedBox(width: 12),
        
        Expanded(
          child: _buildSummaryCard(
            title: 'A Pagar',
            value: 'R\$ ${totalPayable.toStringAsFixed(2)}',
            icon: Icons.trending_down,
            color: AppColors.error,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            value,
            style: AppTextStyles.subheadline.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 2),
          
          Text(
            title,
            style: AppTextStyles.caption1.copyWith(
              color: AppColors.onSurfaceVariant,
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
            onTap: _showCreateExpenseModal,
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
        icon: Icons.check_circle,
        title: 'Você não deve nada!',
        subtitle: 'Todas as suas contas estão em dia',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text('Despesas Pendentes', style: AppTextStyles.headline),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_recentExpenses.length}',
                    style: AppTextStyles.caption2.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (_recentExpenses.isNotEmpty)
              TextButton(
                onPressed: () => _showAllYouOweDialog(),
                child: const Text('Ver todos'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _recentExpenses.take(3).length,
          itemBuilder: (context, index) {
            final debt = _recentExpenses[index];
            return _buildYouOweItem(debt);
          },
        ),
      ],
    );
  }



  Widget _buildPendingDebts() {
    if (_debts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.money_off,
        title: 'Ninguém te deve nada',
        subtitle: 'Não há dívidas pendentes para receber',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text('Dívidas Pendentes', style: AppTextStyles.headline),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_debts.length}',
                    style: AppTextStyles.caption2.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (_debts.isNotEmpty)
              TextButton(
                onPressed: () => _showAllPendingDebtsDialog(),
                child: const Text('Ver todos'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _debts.take(3).length,
          itemBuilder: (context, index) {
            final debt = _debts[index];
            return _buildPendingDebtItem(debt);
          },
        ),
      ],
    );
  }

  Widget _buildYouOweItem(Map<String, dynamic> debt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        child: InkWell(
          onTap: () => _showPaymentPopup(debt),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.error.withOpacity(0.1),
                  child: Text(
                    debt['creditor_name']?.toString().substring(0, 1).toUpperCase() ?? '?',
                    style: AppTextStyles.caption1.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Debt details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Você deve para ${debt['creditor_name'] ?? 'Desconhecido'}',
                        style: AppTextStyles.subheadline.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        debt['source'] == 'group_debt' 
                          ? 'Gasto em grupo'
                          : 'Título comprado',
                        style: AppTextStyles.caption1.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Amount and wallet icon
                Row(
                  children: [
                    Text(
                      'R\$ ${(debt['amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                      style: AppTextStyles.subheadline.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.account_balance_wallet,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingDebtItem(Map<String, dynamic> debt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.success.withOpacity(0.1),
                child: Text(
                  debt['debtor_name']?.toString().substring(0, 1).toUpperCase() ?? '?',
                  style: AppTextStyles.caption1.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Debt details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${debt['debtor_name'] ?? 'Desconhecido'} te deve',
                      style: AppTextStyles.subheadline.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      debt['source'] == 'group_debt' 
                        ? 'Gasto em grupo'
                        : 'Título vendido',
                      style: AppTextStyles.caption1.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Amount
              Text(
                'R\$ ${(debt['amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                style: AppTextStyles.subheadline.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
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
    // Navegar para a tela de grupos quando a aba for selecionada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go('/groups');
    });
    
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildMarketplaceTab() {
    return const MarketplaceScreen();
  }

  Widget _buildInsightsTab() {
    return const InsightsScreen(
      showAppBar: false,
      showBottomNavigation: false,
    );
  }

  Widget _buildProfileTab(User? user) {
    return const UserScreen();
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            // Já está no dashboard/início
            if (_currentIndex != 0) {
              setState(() => _currentIndex = 0);
            }
            break;
          case 1:
            context.go('/groups');
            break;
          case 2:
            context.go('/marketplace');
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
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    );
  }

  void _showAllYouOweDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Todas as despesas pendentes (${_recentExpenses.length})',
            style: AppTextStyles.headline,
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: _recentExpenses.isEmpty 
                ? const Center(
                    child: Text('Você não deve nada para ninguém!'),
                  )
                : ListView.builder(
                    itemCount: _recentExpenses.length,
                    itemBuilder: (context, index) {
                      final debt = _recentExpenses[index];
                      return _buildYouOweItem(debt);
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  void _showAllPendingDebtsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Todas as dívidas pendentes (${_debts.length})',
            style: AppTextStyles.headline,
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: _debts.isEmpty 
                ? const Center(
                    child: Text('Ninguém te deve nada!'),
                  )
                : ListView.builder(
                    itemCount: _debts.length,
                    itemBuilder: (context, index) {
                      final debt = _debts[index];
                      return _buildPendingDebtItem(debt);
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentPopup(Map<String, dynamic> debt) {
    print('[DEBUG] Dados da dívida no popup: $debt');
    print('[DEBUG] Chaves disponíveis: ${debt.keys.toList()}');
    
    final amount = (debt['amount'] as num?)?.toDouble() ?? 0.0;
    final creditorName = debt['creditor_name']?.toString() ?? 'Desconhecido';
    final groupName = debt['group_name']?.toString() ?? 'Grupo';
    final hasEnoughBalance = _walletBalance >= amount;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: AppColors.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text('Pagar Despesa'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informações da dívida
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detalhes do pagamento',
                      style: AppTextStyles.subheadline.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildPaymentDetailRow('Para:', creditorName),
                    _buildPaymentDetailRow('Grupo:', groupName),
                    _buildPaymentDetailRow('Valor:', 'R\$ ${amount.toStringAsFixed(2)}'),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Informações da carteira
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: hasEnoughBalance 
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasEnoughBalance 
                      ? AppColors.success.withOpacity(0.3)
                      : AppColors.error.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasEnoughBalance ? Icons.check_circle : Icons.error,
                      color: hasEnoughBalance ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saldo da carteira',
                            style: AppTextStyles.caption1,
                          ),
                          Text(
                            'R\$ ${_walletBalance.toStringAsFixed(2)}',
                            style: AppTextStyles.subheadline.copyWith(
                              fontWeight: FontWeight.w600,
                              color: hasEnoughBalance ? AppColors.success : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              if (!hasEnoughBalance) ...[
                const SizedBox(height: 12),
                Text(
                  'Saldo insuficiente para realizar o pagamento.',
                  style: AppTextStyles.caption1.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: hasEnoughBalance 
                ? () => _processWalletPayment(debt, context)
                : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.onSurfaceVariant,
              ),
              child: const Text('Pagar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPaymentDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
            style: AppTextStyles.caption1.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processWalletPayment(Map<String, dynamic> debt, BuildContext dialogContext) async {
    try {
      // Fechar o popup
      Navigator.of(dialogContext).pop();
      
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Processando pagamento...'),
            ],
          ),
        ),
      );

      final debtId = debt['id']?.toString();
      print('[DEBUG] ID da dívida extraído: $debtId');
      print('[DEBUG] Estrutura completa da debt: $debt');

      if (debtId == null) {
        throw Exception('ID da dívida não encontrado');
      }

      // Fazer chamada para a API de pagamento via wallet
      final paymentResponse = await ApiService.post('/user/pay-debt/$debtId', {});

      // Fechar loading
      if (mounted) Navigator.of(context).pop();

      // Mostrar sucesso
      if (mounted) {
        // Verificar se o pagamento afetou algum grupo
        String successMessage = 'Pagamento realizado com sucesso!';
        if (paymentResponse is Map<String, dynamic>) {
          final paymentDetails = paymentResponse['payment_details'];
          final groupId = paymentResponse['group_id'];
          
          if (paymentDetails != null) {
            final creditorName = paymentDetails['creditor_name'] ?? 'desconhecido';
            final amount = paymentDetails['amount']?.toStringAsFixed(2) ?? '0.00';
            successMessage = 'Pagamento de R\$ $amount para $creditorName realizado com sucesso!';
          }
          
          if (groupId != null) {
            print('[DEBUG] Pagamento afetou grupo: $groupId - dados serão atualizados');
            // TODO: Implementar notificação para outros usuários do grupo
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: AppColors.success,
          ),
        );

        // Aguardar um pouco e recarregar dados do dashboard
        await Future.delayed(const Duration(milliseconds: 500));
        await _loadDashboardData();
      }

    } catch (e) {
      // Fechar loading se estiver aberto
      if (mounted) Navigator.of(context).pop();
      
      // Mostrar erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao processar pagamento: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }


}