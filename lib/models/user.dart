class User {
  final String id;
  final String email;
  final String name;
  final String? avatar;
  final List<String> activatedBusinessIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  // NEW: Field to store custom point rate if applicable
  final double? pointsRate;
  final int pointsBalance;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.avatar,
    this.activatedBusinessIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.pointsRate,
    this.pointsBalance = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar': avatar,
      'activated_business_ids': activatedBusinessIds,
      'points_balance': pointsBalance,
      'points_per_unit': pointsRate, // Save to DB (new key)
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    // 1. SAFELY GET THE ID
    // Check 'id' first, if missing check '_id', if both missing use empty string
    var idValue = json['id'] ?? json['_id'];
    String rawId = idValue?.toString() ?? '';

    // 2. CLEAN THE MONGODB FORMAT
    // Removes 'ObjectId("...")' wrapper if present
    if (rawId.startsWith('ObjectId("')) {
      rawId = rawId.substring(10, 34);
    }

    return User(
      id: rawId,
      // 3. SAFE STRING HANDLING (Prevents crash if null)
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? 'User', // Defaults to 'User' if null
      avatar: json['avatar'] as String?,

      activatedBusinessIds: List<String>.from(
        json['activated_business_ids'] as List<dynamic>? ?? [],
      ),

      pointsBalance: (json['points_balance'] as num?)?.toInt() ?? 0,
      pointsRate: (json['points_per_unit'] as num?)?.toDouble(),

      // 4. SAFE DATE PARSING
      // If date is missing/null, use current time instead of crashing
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? avatar,
    List<String>? activatedBusinessIds,
    double? pointsRate,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? pointsBalance,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      activatedBusinessIds: activatedBusinessIds ?? this.activatedBusinessIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pointsRate: pointsRate ?? this.pointsRate,
      pointsBalance: pointsBalance ?? this.pointsBalance,
    );
  }
}
