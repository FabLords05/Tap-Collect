class Merchant {
  final String id;
  final String email;
  final String name;
  final String businessId;
  final DateTime createdAt;
  final DateTime updatedAt;
  // NEW: Field to store the merchant's specific rate
  final double? pointsPerCurrency;

  const Merchant({
    required this.id,
    required this.email,
    required this.name,
    required this.businessId,
    required this.createdAt,
    required this.updatedAt,
    this.pointsPerCurrency,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'business_id': businessId,
      'points_per_currency': pointsPerCurrency, // Save to DB
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
      // Parse double safely
      pointsPerCurrency: (json['points_per_currency'] as num?)?.toDouble(),
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
    double? pointsPerCurrency,
  }) {
    return Merchant(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      businessId: businessId ?? this.businessId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pointsPerCurrency: pointsPerCurrency ?? this.pointsPerCurrency,
    );
  }
}