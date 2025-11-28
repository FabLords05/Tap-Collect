enum TransactionType {
  earn,
  redeem,
}

class Transaction {
  final String id;
  final String userId;
  final String businessId;
  final TransactionType type;
  final int points;
  final String description;
  final String? rewardId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Transaction({
    required this.id,
    required this.userId,
    required this.businessId,
    required this.type,
    required this.points,
    required this.description,
    this.rewardId,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'business_id': businessId,
      'type': type.name,
      'points': points,
      'description': description,
      'reward_id': rewardId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      businessId: json['business_id'] as String,
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      points: json['points'] as int,
      description: json['description'] as String,
      rewardId: json['reward_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Transaction copyWith({
    String? id,
    String? userId,
    String? businessId,
    TransactionType? type,
    int? points,
    String? description,
    String? rewardId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessId: businessId ?? this.businessId,
      type: type ?? this.type,
      points: points ?? this.points,
      description: description ?? this.description,
      rewardId: rewardId ?? this.rewardId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}