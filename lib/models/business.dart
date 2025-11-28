class Business {
  final String id;
  final String name;
  final String description;
  final String? logoUrl;
  final String address;
  final String? phone;
  final String? email;
  final int pointsPerDollar;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Business({
    required this.id,
    required this.name,
    required this.description,
    this.logoUrl,
    required this.address,
    this.phone,
    this.email,
    required this.pointsPerDollar,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'logo_url': logoUrl,
      'address': address,
      'phone': phone,
      'email': email,
      'points_per_dollar': pointsPerDollar,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      logoUrl: json['logo_url'] as String?,
      address: json['address'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      pointsPerDollar: json['points_per_dollar'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Business copyWith({
    String? id,
    String? name,
    String? description,
    String? logoUrl,
    String? address,
    String? phone,
    String? email,
    int? pointsPerDollar,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Business(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      pointsPerDollar: pointsPerDollar ?? this.pointsPerDollar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}