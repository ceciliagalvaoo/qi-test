import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../utils/theme.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _contacts = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.get('/users/contacts');
      setState(() {
        _contacts = List<Map<String, dynamic>>.from(result['contacts'] ?? []);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar contatos: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get _filteredContacts {
    if (_searchQuery.isEmpty) {
      return _contacts;
    }

    return _contacts.where((contact) {
      final name = (contact['name'] as String? ?? '').toLowerCase();
      final email = (contact['email'] as String? ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();

      return name.contains(query) || email.contains(query);
    }).toList();
  }

  Future<void> _showAddContactDialog() async {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Contato'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Digite o email do usuário que deseja adicionar:',
                style: AppTextStyles.subheadline,
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'exemplo@email.com',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email é obrigatório';
                  }
                  if (!value.contains('@')) {
                    return 'Email inválido';
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
                Navigator.of(context).pop(emailController.text.trim());
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _addContact(result);
    }
  }

  Future<void> _addContact(String email) async {
    try {
      await ApiService.post('/users/contacts', {'email': email});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contato adicionado com sucesso!'),
          backgroundColor: AppColors.success,
        ),
      );

      _loadContacts(); // Recarregar contatos
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao adicionar contato: ${e.toString()}'),
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
        title: const Text('Contatos'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _showAddContactDialog,
            icon: const Icon(Icons.person_add),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de pesquisa
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              decoration: InputDecoration(
                hintText: 'Pesquisar contatos...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          
          // Lista de contatos
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _filteredContacts.isEmpty 
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredContacts.length,
                        itemBuilder: (context, index) {
                          final contact = _filteredContacts[index];
                          return _buildContactItem(contact);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_searchQuery.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: AppColors.onSurfaceVariant.withOpacity(0.5),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Nenhum resultado',
                style: AppTextStyles.headline.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Não encontramos contatos com "$_searchQuery"',
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

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.onSurfaceVariant.withOpacity(0.5),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Nenhum contato ainda',
              style: AppTextStyles.headline.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Adicione seus primeiros contatos para facilitar a divisão de despesas',
              style: AppTextStyles.subheadline.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            ElevatedButton.icon(
              onPressed: _showAddContactDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('Adicionar Contato'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(Map<String, dynamic> contact) {
    final score = (contact['score'] as num?)?.toDouble() ?? 0.0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight.withOpacity(0.1),
          child: Text(
            (contact['name'] as String?)?.substring(0, 1).toUpperCase() ?? '?',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        title: Text(
          contact['name'] ?? 'Nome não disponível',
          style: AppTextStyles.subheadline.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              contact['email'] ?? 'Email não disponível',
              style: AppTextStyles.caption1.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            
            const SizedBox(height: 4),
            
            Row(
              children: [
                Icon(
                  Icons.star,
                  size: 16,
                  color: _getScoreColor(score),
                ),
                const SizedBox(width: 4),
                Text(
                  'Score: ${score.toStringAsFixed(1)}',
                  style: AppTextStyles.caption2.copyWith(
                    color: _getScoreColor(score),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'invite_group',
              child: Text('Convidar para grupo'),
            ),
            const PopupMenuItem(
              value: 'remove',
              child: Text('Remover contato'),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'invite_group':
                // TODO: Implementar convite para grupo
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Funcionalidade em desenvolvimento'),
                  ),
                );
                break;
              case 'remove':
                _confirmRemoveContact(contact);
                break;
            }
          },
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 8.0) return AppColors.success;
    if (score >= 6.0) return AppColors.warning;
    return AppColors.error;
  }

  Future<void> _confirmRemoveContact(Map<String, dynamic> contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Contato'),
        content: Text(
          'Tem certeza que deseja remover ${contact['name']} dos seus contatos?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.delete('/users/contacts/${contact['id']}');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contato removido com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );

        _loadContacts(); // Recarregar contatos
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao remover contato: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}