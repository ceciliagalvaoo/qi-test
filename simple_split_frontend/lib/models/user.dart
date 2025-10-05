class User {
  final String id; // UUID
  final String name;
  final String email;
  final String? phone;
  final double score;
  final DateTime? createdAt;
  final double walletBalance;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.score,
    this.createdAt,
    required this.walletBalance,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      score: (json['score'] ?? 0).toDouble(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      walletBalance: (json['wallet_balance'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'score': score,
      'created_at': createdAt?.toIso8601String(),
      'wallet_balance': walletBalance,
    };
  }

  String get scoreText {
    return score.toStringAsFixed(1);
  }

  String get scoreDescription {
    if (score >= 9.0) {
      return "Excelente! Você é um usuário confiável.";
    } else if (score >= 7.0) {
      return "Bom! Continue pagando em dia.";
    } else if (score >= 5.0) {
      return "Regular. Tente melhorar pagando pontualmente.";
    } else {
      return "Baixo. Pague suas dívidas em dia para melhorar.";
    }
  }
}