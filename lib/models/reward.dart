class Reward {
  final String id;
  final String businessId;
  final String title;
  final String description;
  final int pointsCost;
  final String? imageUrl;
  final bool isActive;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Reward({
    required this.id,
    required this.businessId,
    required this.title,
    required this.description,
    required this.pointsCost,
    this.imageUrl,
    required this.isActive,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'title': title,
      'description': description,
      'points_cost': pointsCost,
      'image_url': imageUrl,
      'is_active': isActive,
      'expires_at': expiresAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      pointsCost: json['points_cost'] as int,
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Reward copyWith({
    String? id,
    String? businessId,
    String? title,
    String? description,
    int? pointsCost,
    String? imageUrl,
    bool? isActive,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reward(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      title: title ?? this.title,
      description: description ?? this.description,
      pointsCost: pointsCost ?? this.pointsCost,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}