import '../models/receivable.dart';
import 'api_service.dart';

class MarketplaceService {
  // Obter itens do marketplace
  static Future<List<MarketplaceItem>> getMarketplaceItems() async {
    try {
      final response = await ApiService.get('/marketplace/');
      final List<dynamic> itemsData = response as List<dynamic>;
      return itemsData.map((json) => MarketplaceItem.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao carregar marketplace: ${e.toString()}');
    }
  }

  // Colocar dívida à venda
  static Future<Map<String, dynamic>> createReceivable({
    required String debtId,
    required double sellingPrice,
  }) async {
    try {
      final response = await ApiService.post('/marketplace/sell', {
        'debt_id': debtId,
        'selling_price': sellingPrice,
      });

      return {
        'success': true,
        'receivable': Receivable.fromJson(response['receivable']),
        'message': response['message'],
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Comprar título de recebível
  static Future<Map<String, dynamic>> buyReceivable(String receivableId) async {
    try {
      final response = await ApiService.post('/marketplace/buy/$receivableId', {});

      return {
        'success': true,
        'receivable': Receivable.fromJson(response['receivable']),
        'profit_when_paid': response['profit_when_paid'],
        'message': response['message'],
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Obter meus recebíveis
  static Future<Map<String, dynamic>> getMyReceivables() async {
    try {
      final response = await ApiService.get('/marketplace/my-receivables');

      final List<dynamic> sellingData = response['selling'] ?? [];
      final List<dynamic> boughtData = response['bought'] ?? [];

      return {
        'success': true,
        'selling': sellingData.map((json) => Receivable.fromJson(json)).toList(),
        'bought': boughtData.map((json) => Receivable.fromJson(json)).toList(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'selling': <Receivable>[],
        'bought': <Receivable>[],
      };
    }
  }

  // Cancelar venda de recebível
  static Future<Map<String, dynamic>> cancelReceivable(String receivableId) async {
    try {
      final response = await ApiService.delete('/marketplace/cancel/$receivableId');

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

  // Obter estatísticas do marketplace
  static Future<Map<String, dynamic>> getMarketplaceStats() async {
    try {
      final response = await ApiService.get('/marketplace/stats');
      return {
        'success': true,
        'data': response,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'data': {
          'total_titles_for_sale': 0,
          'total_volume': 0.0,
          'max_discount_available': 0.0,
          'average_discount': 0.0,
        },
      };
    }
  }
}