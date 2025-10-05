import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  // Login do usuário
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await ApiService.post('/auth/login', {
        'email': email,
        'password': password,
      });

      // Salvar token
      if (response['access_token'] != null) {
        await ApiService.saveToken(response['access_token']);
      }

      return {
        'success': true,
        'user': User.fromJson(response['user']),
        'token': response['access_token'],
        'message': response['message'],
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Registro de novo usuário
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final response = await ApiService.post('/auth/register', {
        'name': name,
        'email': email,
        'password': password,
        if (phone != null) 'phone': phone,
      });

      // Salvar token
      if (response['access_token'] != null) {
        await ApiService.saveToken(response['access_token']);
      }

      return {
        'success': true,
        'user': User.fromJson(response['user']),
        'token': response['access_token'],
        'message': response['message'],
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }



  // Obter perfil do usuário
  static Future<User?> getProfile() async {
    try {
      final response = await ApiService.get('/auth/profile');
      return User.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Atualizar perfil
  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (phone != null) data['phone'] = phone;

      final response = await ApiService.put('/auth/profile', data);

      return {
        'success': true,
        'user': User.fromJson(response['user']),
        'message': response['message'],
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Logout
  static Future<void> logout() async {
    await ApiService.removeToken();
  }

  // Verificar se usuário está autenticado
  static Future<bool> isAuthenticated() async {
    await ApiService.loadToken();
    
    try {
      await getProfile();
      return true;
    } catch (e) {
      await logout();
      return false;
    }
  }
}