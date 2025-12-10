class Merchant {
  final String id;
  final String email;
  final String name;
  final String businessId;
  final DateTime createdAt;
  final DateTime updatedAt;
  // NEW: Field to store the merchant's specific rate
  final double? pointsRate;

  const Merchant({
    required this.id,
    required this.email,
    required this.name,
    required this.businessId,
    required this.createdAt,
    required this.updatedAt,
    this.pointsRate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'business_id': businessId,
      'points_per_unit': pointsRate, // Save to DB (new key)
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Merchant.fromJson(Map<String, dynamic> json) {
    // Sanitize ID logic (Good practice to include here too)
    String rawId = json['id'].toString();
    if (rawId.startsWith('ObjectId("')) {
      rawId = rawId.substring(10, 34);
    }

    return Merchant(
      id: rawId,
      email: json['email'] as String,
      name: json['name'] as String,
      businessId: json['business_id'] as String,
      // Parse new key
      pointsRate: (json['points_per_unit'] as num?)?.toDouble(),
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
    double? pointsRate,
  }) {
    return Merchant(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      businessId: businessId ?? this.businessId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pointsRate: pointsRate ?? this.pointsRate,
    );
  }
}