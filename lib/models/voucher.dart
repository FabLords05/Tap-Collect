enum VoucherStatus {
  active,
  redeemed,
  expired,
}

class Voucher {
  final String id;
  final String userId;
  final String rewardId;
  final String code;
  final VoucherStatus status;
  final DateTime expiresAt;
  final DateTime? redeemedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Voucher({
    required this.id,
    required this.userId,
    required this.rewardId,
    required this.code,
    required this.status,
    required this.expiresAt,
    this.redeemedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'reward_id': rewardId,
      'code': code,
      'status': status.name,
      'expires_at': expiresAt.toIso8601String(),
      'redeemed_at': redeemedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      rewardId: json['reward_id'] as String,
      code: json['code'] as String,
      status: VoucherStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      redeemedAt: json['redeemed_at'] != null
          ? DateTime.parse(json['redeemed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Voucher copyWith({
    String? id,
    String? userId,
    String? rewardId,
    String? code,
    VoucherStatus? status,
    DateTime? expiresAt,
    DateTime? redeemedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Voucher(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      rewardId: rewardId ?? this.rewardId,
      code: code ?? this.code,
      status: status ?? this.status,
      expiresAt: expiresAt ?? this.expiresAt,
      redeemedAt: redeemedAt ?? this.redeemedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}