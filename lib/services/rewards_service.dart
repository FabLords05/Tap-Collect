import 'package:grove_rewards/models/reward.dart';
import 'package:grove_rewards/services/storage_service.dart';
import 'package:uuid/uuid.dart';

class RewardsService {
  static const _uuid = Uuid();

  // Get all available rewards
  static Future<List<Reward>> getAllRewards() async {
    try {
      final rewardData = await StorageService.loadRewards();
      final rewards = <Reward>[];
      
      for (final data in rewardData) {
        try {
          final reward = Reward.fromJson(data);
          if (reward.isActive && (reward.expiresAt == null || reward.expiresAt!.isAfter(DateTime.now()))) {
            rewards.add(reward);
          }
        } catch (e) {
          // Skip corrupted entries
          continue;
        }
      }
      
      // Sort by points cost (lowest first)
      rewards.sort((a, b) => a.pointsCost.compareTo(b.pointsCost));
      return rewards;
    } catch (e) {
      return [];
    }
  }

  // Get reward by ID
  static Future<Reward?> getRewardById(String rewardId) async {
    final allRewards = await getAllRewards();
    try {
      return allRewards.firstWhere((r) => r.id == rewardId);
    } catch (e) {
      return null;
    }
  }

  // Get rewards for a specific business
  static Future<List<Reward>> getRewardsForBusiness(String businessId) async {
    final allRewards = await getAllRewards();
    return allRewards.where((r) => r.businessId == businessId).toList();
  }

  // Get rewards within points range
  static Future<List<Reward>> getRewardsByPointsRange({
    int? minPoints,
    int? maxPoints,
  }) async {
    final allRewards = await getAllRewards();
    return allRewards.where((r) {
      if (minPoints != null && r.pointsCost < minPoints) return false;
      if (maxPoints != null && r.pointsCost > maxPoints) return false;
      return true;
    }).toList();
  }

  // Get affordable rewards based on user's points
  static Future<List<Reward>> getAffordableRewards(int userPoints) async {
    final allRewards = await getAllRewards();
    return allRewards.where((r) => r.pointsCost <= userPoints).toList();
  }

  // Add new reward (for admin/merchant use)
  static Future<void> addReward(Reward reward) async {
    try {
      final allRewards = await getAllRewards();
      allRewards.add(reward);
      
      final rewardJsonList = allRewards.map((r) => r.toJson()).toList();
      await StorageService.saveRewards(rewardJsonList);
    } catch (e) {
      // Handle error
    }
  }

  // Initialize sample rewards data
  static Future<void> initializeSampleData() async {
    final existingRewards = await getAllRewards();
    if (existingRewards.isNotEmpty) return; // Don't add sample data if rewards exist

    final now = DateTime.now();
    final sampleRewards = [
      Reward(
        id: _uuid.v4(),
        businessId: 'sample-cafe-001',
        title: 'Free Coffee ☕',
        description: 'Get a free regular coffee of your choice',
        pointsCost: 100,
        imageUrl: null,
        isActive: true,
        expiresAt: null,
        createdAt: now,
        updatedAt: now,
      ),
      Reward(
        id: _uuid.v4(),
        businessId: 'sample-cafe-001',
        title: 'Free Pastry 🥐',
        description: 'Choose any pastry from our selection',
        pointsCost: 75,
        imageUrl: null,
        isActive: true,
        expiresAt: null,
        createdAt: now,
        updatedAt: now,
      ),
      Reward(
        id: _uuid.v4(),
        businessId: 'sample-cafe-001',
        title: 'Free Lunch Combo 🥪',
        description: 'Sandwich, drink, and chips combo',
        pointsCost: 250,
        imageUrl: null,
        isActive: true,
        expiresAt: null,
        createdAt: now,
        updatedAt: now,
      ),
      Reward(
        id: _uuid.v4(),
        businessId: 'sample-cafe-001',
        title: '10% Off Purchase 💰',
        description: 'Get 10% off your entire purchase',
        pointsCost: 50,
        imageUrl: null,
        isActive: true,
        expiresAt: null,
        createdAt: now,
        updatedAt: now,
      ),
      Reward(
        id: _uuid.v4(),
        businessId: 'sample-cafe-001',
        title: 'Free Dessert 🍰',
        description: 'Any dessert from our display case',
        pointsCost: 120,
        imageUrl: null,
        isActive: true,
        expiresAt: null,
        createdAt: now,
        updatedAt: now,
      ),
      Reward(
        id: _uuid.v4(),
        businessId: 'sample-cafe-001',
        title: 'Premium Coffee Upgrade ⭐',
        description: 'Upgrade any coffee to premium blend',
        pointsCost: 30,
        imageUrl: null,
        isActive: true,
        expiresAt: null,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final rewardJsonList = sampleRewards.map((r) => r.toJson()).toList();
    await StorageService.saveRewards(rewardJsonList);
  }

  // Clear all rewards (for testing)
  static Future<void> clearAllRewards() async {
    await StorageService.saveRewards([]);
  }

  // Update reward
  static Future<void> updateReward(Reward updatedReward) async {
    try {
      final allRewards = await getAllRewards();
      final index = allRewards.indexWhere((r) => r.id == updatedReward.id);
      
      if (index >= 0) {
        allRewards[index] = updatedReward;
        final rewardJsonList = allRewards.map((r) => r.toJson()).toList();
        await StorageService.saveRewards(rewardJsonList);
      }
    } catch (e) {
      // Handle error
    }
  }

  // Deactivate reward
  static Future<void> deactivateReward(String rewardId) async {
    final reward = await getRewardById(rewardId);
    if (reward != null) {
      final deactivatedReward = reward.copyWith(
        isActive: false,
        updatedAt: DateTime.now(),
      );
      await updateReward(deactivatedReward);
    }
  }
}