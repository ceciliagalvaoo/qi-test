class Expense {
  final int id;
  final int groupId;
  final String payerId; // Mudado de int para String (UUID)
  final String? payerName;
  final String description;
  final double amount;
  final DateTime? date;
  final DateTime? createdAt;
  final List<Debt>? debts;

  Expense({
    required this.id,
    required this.groupId,
    required this.payerId,
    this.payerName,
    required this.description,
    required this.amount,
    this.date,
    this.createdAt,
    this.debts,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      groupId: json['group_id'],
      payerId: json['payer_id'].toString(), // Garantir que seja String
      payerName: json['payer_name'],
      description: json['description'],
      amount: json['amount'].toDouble(),
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      debts: json['debts'] != null 
          ? (json['debts'] as List).map((d) => Debt.fromJson(d)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'payer_id': payerId,
      'payer_name': payerName,
      'description': description,
      'amount': amount,
      'date': date?.toIso8601String().split('T')[0],
      'created_at': createdAt?.toIso8601String(),
      'debts': debts?.map((d) => d.toJson()).toList(),
    };
  }
}

class Debt {
  final int id;
  final int expenseId;
  final String debtorId; // Mudado de int para String (UUID)
  final String? debtorName;
  final String creditorId; // Mudado de int para String (UUID)
  final String? creditorName;
  final double amount;
  final String status;
  final DateTime? dueDate;
  final DateTime? paidAt;
  final DateTime? createdAt;
  final String? expenseDescription;

  Debt({
    required this.id,
    required this.expenseId,
    required this.debtorId,
    this.debtorName,
    required this.creditorId,
    this.creditorName,
    required this.amount,
    required this.status,
    this.dueDate,
    this.paidAt,
    this.createdAt,
    this.expenseDescription,
  });

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      id: json['id'],
      expenseId: json['expense_id'],
      debtorId: json['debtor_id'].toString(), // Garantir que seja String
      debtorName: json['debtor_name'],
      creditorId: json['creditor_id'].toString(), // Garantir que seja String
      creditorName: json['creditor_name'],
      amount: json['amount'].toDouble(),
      status: json['status'],
      dueDate: json['due_date'] != null 
          ? DateTime.parse(json['due_date']) 
          : null,
      paidAt: json['paid_at'] != null 
          ? DateTime.parse(json['paid_at']) 
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      expenseDescription: json['expense_description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'expense_id': expenseId,
      'debtor_id': debtorId,
      'debtor_name': debtorName,
      'creditor_id': creditorId,
      'creditor_name': creditorName,
      'amount': amount,
      'status': status,
      'due_date': dueDate?.toIso8601String().split('T')[0],
      'paid_at': paidAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'expense_description': expenseDescription,
    };
  }

  bool get isPending => status == 'pending';
  bool get isPaid => status == 'paid';
  bool get isCancelled => status == 'cancelled';
}