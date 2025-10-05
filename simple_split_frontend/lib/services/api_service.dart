import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5000/api';
  
  static String? _token;
  
  // Headers padrão
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // Configurar token de autenticação
  static void setToken(String token) {
    _token = token;
  }

  // Limpar token
  static void clearToken() {
    _token = null;
  }

  // Salvar token no SharedPreferences
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    setToken(token);
  }

  // Carregar token do SharedPreferences
  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      setToken(token);
    }
  }

  // Remover token do SharedPreferences
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    clearToken();
  }

  // Método genérico para requisições GET
  static Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  // Método genérico para requisições POST
  static Future<Map<String, dynamic>> post(
    String endpoint, 
    Map<String, dynamic> data
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
      body: jsonEncode(data),
    );

    return _handleResponse(response);
  }

  // Método genérico para requisições PUT
  static Future<Map<String, dynamic>> put(
    String endpoint, 
    Map<String, dynamic> data
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
      body: jsonEncode(data),
    );

    return _handleResponse(response);
  }

  // Método genérico para requisições DELETE
  static Future<Map<String, dynamic>> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  // Tratar resposta da API
  static Map<String, dynamic> _handleResponse(http.Response response) {
    final data = jsonDecode(response.body);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw ApiException(
        message: data['error'] ?? 'Erro desconhecido',
        statusCode: response.statusCode,
      );
    }
  }

  // ===== MARKETPLACE METHODS =====
  
  // Buscar recebíveis disponíveis no marketplace
  static Future<List<Map<String, dynamic>>> getMarketplaceReceivables() async {
    final response = await get('/marketplace');
    return List<Map<String, dynamic>>.from(response['receivables'] ?? []);
  }

  // Comprar um recebível do marketplace
  static Future<bool> buyReceivable(String buyerId, int receivableId) async {
    try {
      await post('/marketplace/buy', {
        'buyer_id': buyerId,
        'receivable_id': receivableId,
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException({required this.message, required this.statusCode});

  @override
  String toString() {
    return 'ApiException: $message (Status: $statusCode)';
  }
}