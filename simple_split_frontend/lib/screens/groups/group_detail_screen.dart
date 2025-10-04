import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../utils/theme.dart';

class GroupDetailScreen extends StatefulWidget {
  final int groupId;

  const GroupDetailScreen({
    super.key,
    required this.groupId,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic>? _groupData;
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _members = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadGroupData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupData() async {
    setState(() => _isLoading = true);

    try {
      // Carregar dados do grupo
      final groupResult = await ApiService.get('/groups/${widget.groupId}');
      final expensesResult = await ApiService.get('/expenses?group_id=${widget.groupId}');

      setState(() {
        _groupData = groupResult;
        _expenses = List<Map<String, dynamic>>.from(expensesResult['expenses'] ?? []);
        _members = List<Map<String, dynamic>>.from(groupResult['members'] ?? []);
      });
    } catch (e) {
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
      await ApiService.post('/expenses', {
        'group_id': widget.groupId.toString(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
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
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _groupData!['name'] ?? 'Grupo',
                style: const TextStyle(color: Colors.white),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_groupData!['description'] != null && 
                          _groupData!['description'].isNotEmpty)
                        Text(
                          _groupData!['description'],
                          style: AppTextStyles.subheadline.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      
                      const SizedBox(height: 8),
                      
                      Row(
                        children: [
                          _buildStatChip(
                            icon: Icons.people,
                            value: '${_members.length} membros',
                          ),
                          
                          const SizedBox(width: 8),
                          
                          _buildStatChip(
                            icon: Icons.receipt,
                            value: '${_expenses.length} despesas',
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 40), // Espaço para o título
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              PopupMenuButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'add_member',
                    child: Text('Adicionar membro'),
                  ),
                  const PopupMenuItem(
                    value: 'leave_group',
                    child: Text('Sair do grupo'),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'add_member':
                      // TODO: Implementar adicionar membro
                      break;
                    case 'leave_group':
                      // TODO: Implementar sair do grupo
                      break;
                  }
                },
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
          _buildSummaryTab(),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: AppTextStyles.caption1.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesTab() {
    return Column(
      children: [
        // Botão de adicionar despesa
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _showAddExpenseDialog,
            icon: const Icon(Icons.add),
            label: const Text('Nova Despesa'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildSummaryTab() {
    // Calcular resumo das dívidas
    final totalExpenses = _expenses.fold<double>(
      0.0,
      (sum, expense) => sum + ((expense['amount'] as num?)?.toDouble() ?? 0.0),
    );

    return Padding(
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
          
          // Ações rápidas
          Text(
            'Ações Rápidas',
            style: AppTextStyles.headline.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 12),
          
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implementar otimização de dívidas
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Otimização de dívidas em desenvolvimento'),
                ),
              );
            },
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('Otimizar Dívidas'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
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