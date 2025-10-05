import '../models/group.dart';
import '../models/expense.dart';
import '../models/user.dart';
import 'api_service.dart';

class GroupService {
  // Obter grupos do usuário
  static Future<List<Group>> getUserGroups() async {
    try {
      final response = await ApiService.get('/groups/');
      final List<dynamic> groupsData = response as List<dynamic>;
      return groupsData.map((json) => Group.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao carregar grupos: ${e.toString()}');
    }
  }

  // Criar novo grupo
  static Future<Map<String, dynamic>> createGroup({
    required String name,
    String? description,
  }) async {
    try {
      final response = await ApiService.post('/groups/', {
        'name': name,
        if (description != null) 'description': description,
      });

      return {
        'success': true,
        'group': Group.fromJson(response['group']),
        'message': response['message'],
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Obter detalhes de um grupo
  static Future<Map<String, dynamic>> getGroupDetail(String groupId) async {
    try {
      final response = await ApiService.get('/groups/$groupId');

      final List<dynamic> membersData = response['members'] ?? [];
      final List<dynamic> expensesData = response['expenses'] ?? [];
      final List<dynamic> debtsData = response['debts'] ?? [];

      return {
        'success': true,
        'group': Group.fromJson(response['group']),
        'members': membersData.map((json) => User.fromJson(json)).toList(),
        'expenses': expensesData.map((json) => Expense.fromJson(json)).toList(),
        'debts': debtsData.map((json) => Debt.fromJson(json)).toList(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Adicionar membro ao grupo
  static Future<Map<String, dynamic>> addMember({
    required String groupId,
    required String memberEmail,
  }) async {
    try {
      final response = await ApiService.post('/groups/$groupId/members', {
        'email': memberEmail,
      });

      return {
        'success': true,
        'member': User.fromJson(response['member']),
        'message': response['message'],
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Adicionar despesa ao grupo
  static Future<Map<String, dynamic>> addExpense({
    required String groupId,
    required String description,
    required double amount,
    String? date,
    List<String>? memberIds, // Mudado de List<int> para List<String>
  }) async {
    try {
      final data = {
        'description': description,
        'amount': amount,
        if (date != null) 'date': date,
        if (memberIds != null) 'member_ids': memberIds,
      };

      final response = await ApiService.post('/groups/$groupId/expenses', data);

      return {
        'success': true,
        'expense': Expense.fromJson(response['expense']),
        'message': response['message'],
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Deletar despesa
  static Future<Map<String, dynamic>> deleteExpense({
    required String groupId,
    required String expenseId,
  }) async {
    try {
      final response = await ApiService.delete('/groups/$groupId/expenses/$expenseId');

      return {
        'success': true,
        'message': response['message'],
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}