class Group {
  final int id;
  final String name;
  final String? description;
  final String createdBy; // Mudado de int para String (UUID)
  final String? creatorName;
  final DateTime? createdAt;
  final int membersCount;
  final double totalExpenses;

  Group({
    required this.id,
    required this.name,
    this.description,
    required this.createdBy,
    this.creatorName,
    this.createdAt,
    required this.membersCount,
    required this.totalExpenses,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      createdBy: json['created_by'].toString(), // Garantir que seja String
      creatorName: json['creator_name'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      membersCount: json['members_count'],
      totalExpenses: json['total_expenses'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_by': createdBy,
      'creator_name': creatorName,
      'created_at': createdAt?.toIso8601String(),
      'members_count': membersCount,
      'total_expenses': totalExpenses,
    };
  }
}