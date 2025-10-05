class Group {
  final String id; // Mudado de int para String (UUID)
  final String name;
  final String? description;
  final String createdBy; // UUID
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
      id: json['id'].toString(), // Garantir que seja String (UUID)
      name: json['name'].toString(),
      description: json['description']?.toString(),
      createdBy: json['created_by'].toString(), // Garantir que seja String
      creatorName: json['creator_name']?.toString(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      membersCount: (json['members_count'] ?? 0).toInt(),
      totalExpenses: (json['total_expenses'] ?? 0.0).toDouble(),
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