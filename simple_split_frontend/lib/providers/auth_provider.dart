import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = true;
  bool _isAuthenticated = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  // Inicializar provider
  Future<void> initialize() async {
    if (!_isLoading) return;
    
    try {
      await ApiService.loadToken();
      
      try {
        final userData = await ApiService.get('/auth/profile');
        _user = User.fromJson(userData['user']);
        _isAuthenticated = true;
      } catch (e) {
        await ApiService.removeToken();
        _isAuthenticated = false;
        _user = null;
      }
    } catch (e) {
      _isAuthenticated = false;
      _user = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService.post('/auth/login', {
        'email': email,
        'password': password,
      });
      
      // Criar usuário da response do login
      if (result['user'] != null) {
        _user = User.fromJson(result['user']);
      }
      
      // Salvar token
      if (result['access_token'] != null) {
        await ApiService.saveToken(result['access_token']);
        _isAuthenticated = true;
      }
      
      _isLoading = false;
      notifyListeners();
      
      return {
        'success': true,
        'user': _user,
        'message': result['message'] ?? 'Login realizado com sucesso!'
      };
    } catch (e, stackTrace) {
      print('[AuthProvider] Erro no login: $e');
      print('[AuthProvider] Stack trace completo:');
      print('=== INÍCIO DO STACK TRACE ===');
      print(stackTrace.toString());
      print('=== FIM DO STACK TRACE ===');
      print('[AuthProvider] Erro capturado, definindo estado como não autenticado');
      _isLoading = false;
      _isAuthenticated = false;
      _user = null;
      notifyListeners();
      return {
        'success': false,
        'error': e is ApiException ? e.message : e.toString(),
      };
    }
  }

  // Registro
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService.post('/auth/register', {
        'name': name,
        'email': email,
        'password': password,
        if (phone != null) 'phone': phone,
      });

      _isLoading = false;
      notifyListeners();
      
      return {
        'success': true,
        'message': result['message'] ?? 'Usuário registrado com sucesso!'
      };
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'error': e is ApiException ? e.message : e.toString(),
      };
    }
  }

  // Atualizar perfil
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (phone != null) body['phone'] = phone;
      
      final result = await ApiService.put('/auth/profile', body);
      
      // Atualizar dados do usuário local
      _user = User.fromJson(result['user']);

      _isLoading = false;
      notifyListeners();
      
      return {
        'success': true,
        'user': _user,
        'message': 'Perfil atualizado com sucesso!'
      };
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'error': e is ApiException ? e.message : e.toString(),
      };
    }
  }

  // Logout
  Future<void> logout() async {
    await ApiService.removeToken();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  // Atualizar dados do usuário (para refresh de carteira, etc.)
  Future<void> refreshUser() async {
    try {
      final userData = await ApiService.get('/auth/profile');
      _user = User.fromJson(userData['user']);
      notifyListeners();
    } catch (e) {
      // Silenciosamente falha se não conseguir atualizar
    }
  }
}