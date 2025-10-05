class Insight {
  final String type;
  final String title;
  final String description;
  final Map<String, dynamic> details;
  final String priority;

  Insight({
    required this.type,
    required this.title,
    required this.description,
    required this.details,
    required this.priority,
  });

  factory Insight.fromJson(Map<String, dynamic> json) {
    return Insight(
      type: json['type'],
      title: json['title'],
      description: json['description'],
      details: json['details'] ?? {},
      priority: json['priority'],
    );
  }

  bool get isHighPriority => priority == 'high';
  bool get isMediumPriority => priority == 'medium';
  bool get isLowPriority => priority == 'low';
  bool get isInfo => priority == 'info';
}

class FinancialSummary {
  final double walletBalance;
  final double totalToPay;
  final double totalToReceive;
  final double netBalance;
  final int activeGroups;
  final double score;

  FinancialSummary({
    required this.walletBalance,
    required this.totalToPay,
    required this.totalToReceive,
    required this.netBalance,
    required this.activeGroups,
    required this.score,
  });

  factory FinancialSummary.fromJson(Map<String, dynamic> json) {
    return FinancialSummary(
      walletBalance: json['wallet_balance'].toDouble(),
      totalToPay: json['total_to_pay'].toDouble(),
      totalToReceive: json['total_to_receive'].toDouble(),
      netBalance: json['net_balance'].toDouble(),
      activeGroups: json['active_groups'],
      score: json['score'].toDouble(),
    );
  }

  bool get isPositiveBalance => netBalance > 0;
  bool get hasOutstandingDebts => totalToPay > 0;
  bool get hasIncomingPayments => totalToReceive > 0;
}