class Merchant {
  final String id;
  final String email;
  final String name;
  final String businessId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Merchant({
    required this.id,
    required this.email,
    required this.name,
    required this.businessId,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'business_id': businessId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Merchant.fromJson(Map<String, dynamic> json) {
    return Merchant(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      businessId: json['business_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Merchant copyWith({
    String? id,
    String? email,
    String? name,
    String? businessId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Merchant(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      businessId: businessId ?? this.businessId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
