import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.get('/groups');
      setState(() {
        _groups = List<Map<String, dynamic>>.from(result['groups'] ?? []);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar grupos: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _showCreateGroupDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Criar Novo Grupo'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do grupo',
                  hintText: 'Ex: Viagem para a praia',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nome é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  hintText: 'Descreva o propósito do grupo',
                ),
                maxLines: 3,
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
                Navigator.of(context).pop({
                  'name': nameController.text.trim(),
                  'description': descriptionController.text.trim(),
                });
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _createGroup(result);
    }
  }

  Future<void> _createGroup(Map<String, String> groupData) async {
    try {
      await ApiService.post('/groups', {
        'name': groupData['name']!,
        if (groupData['description']!.isNotEmpty) 'description': groupData['description'],
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Grupo criado com sucesso!'),
          backgroundColor: AppColors.success,
        ),
      );

      _loadGroups(); // Recarregar lista
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao criar grupo: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Meus Grupos'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateGroupDialog,
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _buildGroupsList(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Grupos está no índice 1
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/dashboard');
              break;
            case 1:
              // Já está na tela de grupos
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateGroupDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGroupsList() {
    if (_groups.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadGroups,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final group = _groups[index];
          return _buildGroupCard(group);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_add,
              size: 80,
              color: AppColors.onSurfaceVariant.withOpacity(0.5),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Nenhum grupo ainda',
              style: AppTextStyles.title2.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Crie seu primeiro grupo para começar a dividir despesas com seus amigos',
              style: AppTextStyles.subheadline.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            ElevatedButton.icon(
              onPressed: _showCreateGroupDialog,
              icon: const Icon(Icons.add),
              label: const Text('Criar Primeiro Grupo'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: AppColors.surface,
      child: InkWell(
        onTap: () {
          final groupId = group['id']?.toString();
          if (groupId != null && groupId.isNotEmpty) {
            print('[GroupsScreen] Navegando para grupo: $groupId');
            context.go('/groups/$groupId');
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar do grupo
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primaryLight,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.group,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Informações do grupo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group['name'] ?? 'Grupo sem nome',
                          style: AppTextStyles.headline.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        
                        if (group['description'] != null && group['description'].isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              group['description'],
                              style: AppTextStyles.subheadline.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Seta
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.onSurfaceVariant,
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Estatísticas do grupo
              Row(
                children: [
                  _buildStatItem(
                    icon: Icons.people,
                    value: '${group['members_count'] ?? 0}',
                    label: 'Membros',
                  ),
                  
                  const SizedBox(width: 24),
                  
                  _buildStatItem(
                    icon: Icons.receipt,
                    value: '${group['expenses_count'] ?? 0}',
                    label: 'Despesas',
                  ),
                  
                  const Spacer(),
                  
                  // Total gasto
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'R\$ ${(group['total_expenses'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                      style: AppTextStyles.subheadline.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.onSurfaceVariant,
        ),
        
        const SizedBox(width: 4),
        
        Text(
          value,
          style: AppTextStyles.subheadline.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const SizedBox(width: 4),
        
        Text(
          label,
          style: AppTextStyles.caption1.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}