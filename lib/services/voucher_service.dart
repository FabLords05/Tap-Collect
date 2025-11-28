import 'dart:math';
import 'package:grove_rewards/models/voucher.dart';
import 'package:grove_rewards/models/reward.dart';
import 'package:grove_rewards/services/auth_service.dart';
import 'package:grove_rewards/services/storage_service.dart';
import 'package:grove_rewards/services/points_service.dart';
import 'package:grove_rewards/services/rewards_service.dart';
import 'package:uuid/uuid.dart';

class VoucherService {
  static const _uuid = Uuid();

  // Generate a random voucher code
  static String _generateVoucherCode() {
    const chars = 'ABCDEFGHIJKLMNPQRSTUVWXYZ123456789'; // Excluding O and 0 for clarity
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(8, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }

  // Create new voucher from reward redemption
  static Future<Voucher?> createVoucher({
    required String rewardId,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) return null;

    try {
      // Get the reward details
      final reward = await RewardsService.getRewardById(rewardId);
      if (reward == null || !reward.isActive) return null;

      // Check if user has enough points
      final hasEnoughPoints = await PointsService.hasEnoughPoints(reward.pointsCost);
      if (!hasEnoughPoints) return null;

      // Deduct points
      final pointsDeducted = await PointsService.deductPoints(
        points: reward.pointsCost,
        businessId: reward.businessId,
        description: 'Redeemed: ${reward.title}',
        rewardId: reward.id,
      );

      if (!pointsDeducted) return null;

      // Create voucher
      final now = DateTime.now();
      final voucher = Voucher(
        id: _uuid.v4(),
        userId: user.id,
        rewardId: reward.id,
        code: _generateVoucherCode(),
        status: VoucherStatus.active,
        expiresAt: now.add(const Duration(days: 30)), // 30 days expiry
        createdAt: now,
        updatedAt: now,
      );

      // Save voucher
      await addVoucher(voucher);

      return voucher;
    } catch (e) {
      return null;
    }
  }

  // Add voucher to storage
  static Future<void> addVoucher(Voucher voucher) async {
    try {
      final vouchers = await getAllVouchers();
      vouchers.insert(0, voucher); // Add to beginning
      
      final voucherJsonList = vouchers.map((v) => v.toJson()).toList();
      await StorageService.saveVouchers(voucherJsonList);
    } catch (e) {
      // Handle error
    }
  }

  // Get all vouchers for current user
  static Future<List<Voucher>> getAllVouchers() async {
    final user = AuthService.currentUser;
    if (user == null) return [];

    try {
      final voucherData = await StorageService.loadVouchers();
      final vouchers = <Voucher>[];
      
      for (final data in voucherData) {
        try {
          final voucher = Voucher.fromJson(data);
          if (voucher.userId == user.id) {
            vouchers.add(voucher);
          }
        } catch (e) {
          // Skip corrupted entries
          continue;
        }
      }
      
      // Sort by creation date (newest first)
      vouchers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return vouchers;
    } catch (e) {
      return [];
    }
  }

  // Get active vouchers only
  static Future<List<Voucher>> getActiveVouchers() async {
    final allVouchers = await getAllVouchers();
    final now = DateTime.now();
    
    return allVouchers.where((v) => 
      v.status == VoucherStatus.active && 
      v.expiresAt.isAfter(now)
    ).toList();
  }

  // Get expired vouchers
  static Future<List<Voucher>> getExpiredVouchers() async {
    final allVouchers = await getAllVouchers();
    final now = DateTime.now();
    
    return allVouchers.where((v) => 
      v.status == VoucherStatus.active && 
      v.expiresAt.isBefore(now)
    ).toList();
  }

  // Get redeemed vouchers
  static Future<List<Voucher>> getRedeemedVouchers() async {
    final allVouchers = await getAllVouchers();
    return allVouchers.where((v) => v.status == VoucherStatus.redeemed).toList();
  }

  // Get voucher by ID
  static Future<Voucher?> getVoucherById(String voucherId) async {
    final allVouchers = await getAllVouchers();
    try {
      return allVouchers.firstWhere((v) => v.id == voucherId);
    } catch (e) {
      return null;
    }
  }

  // Get voucher by code
  static Future<Voucher?> getVoucherByCode(String code) async {
    final allVouchers = await getAllVouchers();
    try {
      return allVouchers.firstWhere((v) => v.code == code);
    } catch (e) {
      return null;
    }
  }

  // ===== Merchant/global helpers =====
  // Load all vouchers across all users (merchant scope)
  static Future<List<Voucher>> getAllVouchersGlobal() async {
    try {
      final voucherData = await StorageService.loadVouchers();
      final vouchers = <Voucher>[];
      for (final data in voucherData) {
        try {
          vouchers.add(Voucher.fromJson(data));
        } catch (_) {
          continue;
        }
      }
      // Newest first
      vouchers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return vouchers;
    } catch (_) {
      return [];
    }
  }

  // Find voucher by code across all users
  static Future<Voucher?> findVoucherByCodeGlobal(String code) async {
    final all = await getAllVouchersGlobal();
    try {
      return all.firstWhere((v) => v.code.trim().toUpperCase() == code.trim().toUpperCase());
    } catch (_) {
      return null;
    }
  }

  // Update voucher globally
  static Future<void> updateVoucherGlobal(Voucher updatedVoucher) async {
    try {
      final all = await getAllVouchersGlobal();
      final index = all.indexWhere((v) => v.id == updatedVoucher.id);
      if (index >= 0) {
        all[index] = updatedVoucher;
        await StorageService.saveVouchers(all.map((e) => e.toJson()).toList());
      }
    } catch (_) {}
  }

  // Redeem voucher by code for a specific business (merchant validation)
  static Future<bool> redeemVoucherByCodeForBusiness(String code, String businessId) async {
    final voucher = await findVoucherByCodeGlobal(code);
    if (voucher == null) return false;

    // Get reward to verify ownership
    final Reward? reward = await RewardsService.getRewardById(voucher.rewardId);
    if (reward == null) return false;

    // Ensure this voucher belongs to the merchant's business
    if (reward.businessId != businessId) return false;

    // Validate status and expiry
    if (voucher.status != VoucherStatus.active) return false;
    if (voucher.expiresAt.isBefore(DateTime.now())) return false;

    final redeemed = voucher.copyWith(
      status: VoucherStatus.redeemed,
      redeemedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await updateVoucherGlobal(redeemed);
    return true;
  }

  // Redeem voucher (mark as used)
  static Future<bool> redeemVoucher(String voucherId) async {
    try {
      final voucher = await getVoucherById(voucherId);
      if (voucher == null) return false;

      // Check if voucher is still valid
      if (voucher.status != VoucherStatus.active) return false;
      if (voucher.expiresAt.isBefore(DateTime.now())) return false;

      // Update voucher status
      final redeemedVoucher = voucher.copyWith(
        status: VoucherStatus.redeemed,
        redeemedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await updateVoucher(redeemedVoucher);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Update voucher in storage
  static Future<void> updateVoucher(Voucher updatedVoucher) async {
    try {
      final allVouchers = await getAllVouchers();
      final index = allVouchers.indexWhere((v) => v.id == updatedVoucher.id);
      
      if (index >= 0) {
        allVouchers[index] = updatedVoucher;
        final voucherJsonList = allVouchers.map((v) => v.toJson()).toList();
        await StorageService.saveVouchers(voucherJsonList);
      }
    } catch (e) {
      // Handle error
    }
  }

  // Clean up expired vouchers (update status)
  static Future<void> cleanupExpiredVouchers() async {
    try {
      final expiredVouchers = await getExpiredVouchers();
      final now = DateTime.now();
      
      for (final voucher in expiredVouchers) {
        final expiredVoucher = voucher.copyWith(
          status: VoucherStatus.expired,
          updatedAt: now,
        );
        await updateVoucher(expiredVoucher);
      }
    } catch (e) {
      // Handle error
    }
  }

  // Get voucher statistics
  static Future<Map<String, int>> getVoucherStats() async {
    final allVouchers = await getAllVouchers();
    final now = DateTime.now();
    
    int active = 0;
    int redeemed = 0;
    int expired = 0;
    
    for (final voucher in allVouchers) {
      switch (voucher.status) {
        case VoucherStatus.active:
          if (voucher.expiresAt.isAfter(now)) {
            active++;
          } else {
            expired++;
          }
          break;
        case VoucherStatus.redeemed:
          redeemed++;
          break;
        case VoucherStatus.expired:
          expired++;
          break;
      }
    }
    
    return {
      'active': active,
      'redeemed': redeemed,
      'expired': expired,
      'total': allVouchers.length,
    };
  }

  // Get voucher statistics for a specific business (merchant scope)
  static Future<Map<String, int>> getVoucherStatsForBusiness(String businessId) async {
    final all = await getAllVouchersGlobal();
    final rewards = await RewardsService.getAllRewards();
    final rewardById = {for (final r in rewards) r.id: r};
    final now = DateTime.now();

    int active = 0;
    int redeemed = 0;
    int expired = 0;
    int total = 0;

    for (final v in all) {
      final reward = rewardById[v.rewardId];
      if (reward == null) continue;
      if (reward.businessId != businessId) continue;
      total++;
      if (v.status == VoucherStatus.redeemed) {
        redeemed++;
      } else if (v.status == VoucherStatus.expired || v.expiresAt.isBefore(now)) {
        expired++;
      } else if (v.status == VoucherStatus.active) {
        active++;
      }
    }

    return {
      'active': active,
      'redeemed': redeemed,
      'expired': expired,
      'total': total,
    };
  }

  // Clear all vouchers (for testing)
  static Future<void> clearAllVouchers() async {
    await StorageService.saveVouchers([]);
  }
}