import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/api_service.dart';
import '../../utils/theme.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;

  const GroupDetailScreen({
    super.key,
    required this.groupId,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic>? _groupData;
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _walletPayments = [];
  Map<String, dynamic>? _lastOptimizationResult;


  @override
  void initState() {
    super.initState();
    print('[GroupDetailScreen] 🎯 initState chamado para groupId: ${widget.groupId}');
    print('[GroupDetailScreen] 🎯 Tipo do groupId: ${widget.groupId.runtimeType}');
    
    _tabController = TabController(length: 4, vsync: this);
    _loadGroupData();
    
    // Configurar observador do ciclo de vida da app
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App voltou ao primeiro plano - recarregar dados apenas uma vez
      print('[GroupDetailScreen] 📱 App resumed - recarregando dados');
      _loadGroupData();
    }
  }
  


  Future<void> _loadGroupData() async {
    print('[GroupDetailScreen] 🚀 Iniciando carregamento para groupId: ${widget.groupId}');
    setState(() => _isLoading = true);

    try {
      // Carregar dados do grupo
      print('[GroupDetailScreen] 📡 Fazendo requisição para: /groups/${widget.groupId}');
      final groupResult = await ApiService.get('/groups/${widget.groupId}');
      setState(() {
        _groupData = groupResult;
        _expenses = List<Map<String, dynamic>>.from(groupResult['expenses'] ?? []);
        _members = List<Map<String, dynamic>>.from(groupResult['members'] ?? []);
        _walletPayments = List<Map<String, dynamic>>.from(groupResult['wallet_payments'] ?? []);
        
        print('[GroupDetailScreen] 💳 Pagamentos via wallet carregados: ${_walletPayments.length}');
      });
    } catch (e, stackTrace) {
      print('[GroupDetailScreen] ❌ ERRO ao carregar dados: $e');
      print('[GroupDetailScreen] ❌ StackTrace: $stackTrace');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar dados: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _showAddExpenseDialog() async {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Despesa'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  hintText: 'Ex: Jantar no restaurante',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Descrição é obrigatória';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  hintText: '0.00',
                  prefixText: 'R\$ ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Valor é obrigatório';
                  }
                  final amount = double.tryParse(value.replaceAll(',', '.'));
                  if (amount == null || amount <= 0) {
                    return 'Valor deve ser maior que zero';
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
                final amount = double.parse(
                  amountController.text.replaceAll(',', '.')
                );
                Navigator.of(context).pop({
                  'description': descriptionController.text.trim(),
                  'amount': amount,
                });
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _addExpense(result);
    }
  }

  Future<void> _addExpense(Map<String, dynamic> expenseData) async {
    try {
      await ApiService.post('/groups/${widget.groupId}/expenses', {
        'description': expenseData['description'],
        'amount': expenseData['amount'],
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Despesa adicionada com sucesso!'),
          backgroundColor: AppColors.success,
        ),
      );

      _loadGroupData(); // Recarregar dados
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao adicionar despesa: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _optimizeDebts() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final result = await ApiService.post('/groups/${widget.groupId}/optimize', {});
      
      if (!mounted) return;
      Navigator.of(context).pop(); // Fechar loading
      
      final optimizedCount = result['optimized_count'] ?? 0;
      final message = result['message'] ?? 'Otimização concluída!';
      final balanceSummary = result['balance_summary'] as List<dynamic>? ?? [];
      
      // Atualizar os resultados da otimização no estado
      setState(() {
        _lastOptimizationResult = {
          'message': message,
          'balance_summary': balanceSummary,
          'timestamp': DateTime.now(),
        };
      });
      
      // Mostrar SnackBar com resultado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: optimizedCount > 0 ? AppColors.success : AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );

      // Recarregar dados do grupo se houve otimização
      if (optimizedCount > 0) {
        await _loadGroupData();
      }
      
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Fechar loading
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao otimizar dívidas: ${e.toString()}'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }



  Widget _buildContributionCard(double totalExpenses) {
    // Calcular contribuição de cada membro
    Map<String, double> contributions = {};
    
    for (final expense in _expenses) {
      final payerId = expense['payer_id'] as String;
      final amount = (expense['amount'] as num?)?.toDouble() ?? 0.0;
      contributions[payerId] = (contributions[payerId] ?? 0.0) + amount;
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contribuições por Membro',
              style: AppTextStyles.headline.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 16),
            
            ...contributions.entries.map((entry) {
              final userId = entry.key;
              final contributed = entry.value;
              final percentage = totalExpenses > 0 ? (contributed / totalExpenses * 100) : 0.0;
              
              // Encontrar o nome do usuário
              final member = _members.firstWhere(
                (member) => member['id'] == userId,
                orElse: () => {'name': 'Usuário desconhecido'},
              );
              final userName = member['name'] as String;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            userName,
                            style: AppTextStyles.body,
                          ),
                        ),
                        Text(
                          '${percentage.toStringAsFixed(1)}% (R\$${contributed.toStringAsFixed(2)})',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: AppColors.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ],
                ),
              );
            }).toList(),
            
            if (contributions.isEmpty)
              const Text(
                'Nenhuma despesa registrada ainda.',
                style: AppTextStyles.body,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizationResultCard() {
    if (_lastOptimizationResult == null) return const SizedBox.shrink();
    
    final balanceSummary = _lastOptimizationResult!['balance_summary'] as List<dynamic>? ?? [];
    final timestamp = _lastOptimizationResult!['timestamp'] as DateTime;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Última Otimização',
                  style: AppTextStyles.headline.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
                  style: AppTextStyles.caption1.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            if (balanceSummary.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: AppColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Todos os saldos estão zerados! 🎉',
                        style: AppTextStyles.body,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              Text(
                'Saldos finais:',
                style: AppTextStyles.subheadline.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 8),
              
              ...balanceSummary.map((balance) {
                final user = balance['user'] as String;
                final type = balance['type'] as String;
                final amount = balance['amount'] as num;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: type == 'paga' 
                        ? AppColors.error.withOpacity(0.1) 
                        : AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        type == 'paga' ? Icons.arrow_upward : Icons.arrow_downward,
                        color: type == 'paga' ? AppColors.error : AppColors.success,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          type == 'paga' 
                            ? '$user paga R\$${amount.toStringAsFixed(2)}'
                            : '$user recebe R\$${amount.toStringAsFixed(2)}',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Grupos está no índice 1
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            label: 'Grupos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store_outlined),
            label: 'Marketplace',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_outlined),
            label: 'Insights',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_groupData == null) {
      return const Center(child: Text('Grupo não encontrado'));
    }

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            expandedHeight: 240,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            centerTitle: false,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () {
                // Voltar para a lista de grupos
                context.go('/groups');
              },
            ),
            flexibleSpace: Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
              ),
              child: Stack(
                children: [
                  // Background com conteúdo do grupo
                  Container(
                    color: AppColors.primary,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Informações do grupo (membros e despesas)
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.people, size: 14, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_members.length} membros',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.receipt, size: 14, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_expenses.length} despesas',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          // Descrição do grupo
                          if (_groupData?['description'] != null && 
                              _groupData!['description'].isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              _groupData!['description'],
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  // Título centralizado no topo
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 35,
                    child: Center(
                      child: Text(
                        _groupData?['name'] ?? 'Grupo',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: PopupMenuButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'refresh',
                      child: Row(
                        children: [
                          Icon(Icons.refresh),
                          SizedBox(width: 8),
                          Text('Atualizar dados'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'add_member',
                      child: Row(
                        children: [
                          Icon(Icons.person_add),
                          SizedBox(width: 8),
                          Text('Adicionar membro'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'leave_group',
                      child: Row(
                        children: [
                          Icon(Icons.exit_to_app),
                          SizedBox(width: 8),
                          Text('Sair do grupo'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'refresh':
                        _loadGroupData();
                        break;
                      case 'add_member':
                        // TODO: Implementar adicionar membro
                        break;
                      case 'leave_group':
                        // TODO: Implementar sair do grupo
                        break;
                    }
                  },
                ),
              ),
            ],
          ),
          
          SliverPersistentHeader(
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.onSurfaceVariant,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'Despesas'),
                  Tab(text: 'Membros'),
                  Tab(text: 'Transações'),
                  Tab(text: 'Resumo'),
                ],
              ),
            ),
            pinned: true,
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExpensesTab(),
          _buildMembersTab(),
          _buildTransactionsTab(),
          _buildSummaryTab(),
        ],
      ),
    );
  }

  Widget _buildExpensesTab() {
    return Column(
      children: [
        // Botão de adicionar despesa 
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _showAddExpenseDialog,
            icon: const Icon(Icons.add),
            label: const Text('Nova Despesa'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
        
        // Lista de despesas
        Expanded(
          child: _expenses.isEmpty 
              ? _buildEmptyExpenses()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _expenses.length,
                  itemBuilder: (context, index) {
                    final expense = _expenses[index];
                    return _buildExpenseItem(expense);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyExpenses() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: AppColors.onSurfaceVariant.withOpacity(0.5),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Nenhuma despesa ainda',
              style: AppTextStyles.headline.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Adicione a primeira despesa para começar a dividir custos',
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

  Widget _buildExpenseItem(Map<String, dynamic> expense) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
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
        
        title: Text(
          expense['description'] ?? 'Despesa sem descrição',
          style: AppTextStyles.subheadline.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        
        subtitle: Text(
          'Pago por ${expense['payer_name'] ?? 'Desconhecido'}',
          style: AppTextStyles.caption1.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        
        trailing: Text(
          'R\$ ${(expense['amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
          style: AppTextStyles.subheadline.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMembersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final member = _members[index];
        return _buildMemberItem(member);
      },
    );
  }

  Widget _buildMemberItem(Map<String, dynamic> member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight.withOpacity(0.1),
          child: Text(
            (member['name'] as String?)?.substring(0, 1).toUpperCase() ?? '?',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        title: Text(
          member['name'] ?? 'Nome não disponível',
          style: AppTextStyles.subheadline.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        
        subtitle: Text(
          member['email'] ?? 'Email não disponível',
          style: AppTextStyles.caption1.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Score: ${member['score']?.toStringAsFixed(1) ?? '0.0'}',
              style: AppTextStyles.caption1.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsTab() {
    // Obter pagamentos via wallet dos dados do grupo
    final walletPayments = _groupData?['wallet_payments'] as List<dynamic>? ?? [];
    
    if (walletPayments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: AppColors.onSurfaceVariant,
            ),
            SizedBox(height: 16),
            Text(
              'Nenhuma transação via carteira',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Os pagamentos via carteira aparecerão aqui',
              style: AppTextStyles.caption1,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    // Ordenar por data de pagamento (mais recente primeiro)
    final sortedPayments = List<Map<String, dynamic>>.from(
      walletPayments.map((payment) => Map<String, dynamic>.from(payment as Map))
    );
    sortedPayments.sort((a, b) {
      final dateA = DateTime.tryParse(a['paid_at'] ?? '') ?? DateTime.now();
      final dateB = DateTime.tryParse(b['paid_at'] ?? '') ?? DateTime.now();
      return dateB.compareTo(dateA);
    });
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedPayments.length,
      itemBuilder: (context, index) {
        final payment = sortedPayments[index];
        return _buildWalletPaymentCard(payment);
      },
    );
  }

  Widget _buildWalletPaymentCard(Map<String, dynamic> payment) {
    final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
    final payerName = payment['payer_name']?.toString() ?? 'Desconhecido';
    final creditorName = payment['creditor_name']?.toString() ?? 'Desconhecido';
    final paidAtStr = payment['paid_at']?.toString();
    final originalExpense = payment['original_expense_description']?.toString();
    
    DateTime? paidAt;
    if (paidAtStr != null) {
      paidAt = DateTime.tryParse(paidAtStr);
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho com ícone e tipo
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
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
                        'Pagamento via Carteira',
                        style: AppTextStyles.caption1.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (paidAt != null)
                        Text(
                          '${paidAt.day}/${paidAt.month}/${paidAt.year} às ${paidAt.hour.toString().padLeft(2, '0')}:${paidAt.minute.toString().padLeft(2, '0')}',
                          style: AppTextStyles.caption2.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  'R\$ ${amount.toStringAsFixed(2)}',
                  style: AppTextStyles.bodyEmphasized.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Descrição do pagamento
            Text(
              '$payerName pagou $creditorName',
              style: AppTextStyles.body,
            ),
            
            if (originalExpense != null && originalExpense.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Referente: $originalExpense',
                  style: AppTextStyles.caption1.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTab() {
    // Calcular resumo das dívidas
    final totalExpenses = _expenses.fold<double>(
      0.0,
      (sum, expense) => sum + ((expense['amount'] as num?)?.toDouble() ?? 0.0),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card de resumo geral
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumo Geral',
                    style: AppTextStyles.headline.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total de despesas:',
                        style: AppTextStyles.subheadline,
                      ),
                      Text(
                        'R\$ ${totalExpenses.toStringAsFixed(2)}',
                        style: AppTextStyles.subheadline.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Valor por pessoa:',
                        style: AppTextStyles.subheadline,
                      ),
                      Text(
                        'R\$ ${_members.isNotEmpty ? (totalExpenses / _members.length).toStringAsFixed(2) : '0.00'}',
                        style: AppTextStyles.subheadline.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Card de contribuições por membro
          _buildContributionCard(totalExpenses),
          
          const SizedBox(height: 16),
          
          // Card de resultados da otimização (se houver)
          if (_lastOptimizationResult != null)
            _buildOptimizationResultCard(),
          
          if (_lastOptimizationResult != null)
            const SizedBox(height: 16),
          
          // Ações rápidas
          Text(
            'Ações Rápidas',
            style: AppTextStyles.headline.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Botão de otimizar dívidas com design glassmorphism
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.success, Color(0xFF4CAF50)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withOpacity(0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () async {
                await _optimizeDebts();
              },
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_fix_high, size: 20, color: Colors.white),
              ),
              label: const Text(
                'Otimizar Dívidas',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return false;
  }
}