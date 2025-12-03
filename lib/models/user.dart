class User {
  final String id;
  final String email;
  final String name;
  final String? avatar;
  final List<String> activatedBusinessIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  // NEW: Field to store custom point rate if applicable
  final double? pointsPerCurrency;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.avatar,
    this.activatedBusinessIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.pointsPerCurrency,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar': avatar,
      'activated_business_ids': activatedBusinessIds,
      'points_per_currency': pointsPerCurrency, // Save to DB
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    // Sanitize ID
    String rawId = json['id'].toString();
    if (rawId.startsWith('ObjectId("')) {
      rawId = rawId.substring(10, 34);
    }

    return User(
      id: rawId,
      email: json['email'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      activatedBusinessIds: List<String>.from(
        json['activated_business_ids'] as List<dynamic>? ?? [],
      ),
      // Parse double safely (handles int or double from DB)
      pointsPerCurrency: (json['points_per_currency'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? avatar,
    List<String>? activatedBusinessIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? pointsPerCurrency,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      activatedBusinessIds: activatedBusinessIds ?? this.activatedBusinessIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pointsPerCurrency: pointsPerCurrency ?? this.pointsPerCurrency,
    );
  }
}