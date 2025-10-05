class Receivable {
  final String id;
  final String? ownerId; // Mudado de int para String (UUID)
  final String? ownerName;
  final String? buyerId; // Mudado de int para String (UUID)
  final String? buyerName;
  final String? debtId;
  final double nominalAmount;
  final double sellingPrice;
  final double profitEstimated;
  final double? ownerScore;
  final String status;
  final DateTime? createdAt;
  final DateTime? soldAt;

  Receivable({
    required this.id,
    this.ownerId,
    this.ownerName,
    this.buyerId,
    this.buyerName,
    this.debtId,
    required this.nominalAmount,
    required this.sellingPrice,
    required this.profitEstimated,
    this.ownerScore,
    required this.status,
    this.createdAt,
    this.soldAt,
  });

  factory Receivable.fromJson(Map<String, dynamic> json) {
    return Receivable(
      id: json['id'].toString(),
      ownerId: json['owner_id']?.toString(), // Garantir que seja String ou null
      ownerName: json['owner_name'],
      buyerId: json['buyer_id']?.toString(), // Garantir que seja String ou null
      buyerName: json['buyer_name'],
      debtId: json['debt_id']?.toString(),
      nominalAmount: json['nominal_amount'].toDouble(),
      sellingPrice: json['selling_price'].toDouble(),
      profitEstimated: json['profit_estimated'].toDouble(),
      ownerScore: json['owner_score']?.toDouble(),
      status: json['status'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      soldAt: json['sold_at'] != null 
          ? DateTime.parse(json['sold_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'owner_name': ownerName,
      'buyer_id': buyerId,
      'buyer_name': buyerName,
      'debt_id': debtId,
      'nominal_amount': nominalAmount,
      'selling_price': sellingPrice,
      'profit_estimated': profitEstimated,
      'owner_score': ownerScore,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'sold_at': soldAt?.toIso8601String(),
    };
  }

  bool get isForSale => status == 'for_sale';
  bool get isSold => status == 'sold';
  bool get isCancelled => status == 'cancelled';

  double get discountPercentage {
    return ((nominalAmount - sellingPrice) / nominalAmount) * 100;
  }
}

class MarketplaceItem {
  final String id;
  final double nominalAmount;
  final double sellingPrice;
  final double profitEstimated;
  final double ownerScore;
  final String status;
  final String sellerAnonymousId;
  final DateTime? createdAt;

  MarketplaceItem({
    required this.id,
    required this.nominalAmount,
    required this.sellingPrice,
    required this.profitEstimated,
    required this.ownerScore,
    required this.status,
    required this.sellerAnonymousId,
    this.createdAt,
  });

  factory MarketplaceItem.fromJson(Map<String, dynamic> json) {
    return MarketplaceItem(
      id: json['id'].toString(),
      nominalAmount: json['nominal_amount'].toDouble(),
      sellingPrice: json['selling_price'].toDouble(),
      profitEstimated: json['profit_estimated'].toDouble(),
      ownerScore: json['owner_score'].toDouble(),
      status: json['status'],
      sellerAnonymousId: json['seller_anonymous_id'] ?? 'Usuário Anônimo',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  double get discountPercentage {
    return ((nominalAmount - sellingPrice) / nominalAmount) * 100;
  }
}