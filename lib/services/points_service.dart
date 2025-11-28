import 'package:grove_rewards/models/transaction.dart';
import 'package:grove_rewards/services/auth_service.dart';
import 'package:grove_rewards/services/storage_service.dart';
import 'package:grove_rewards/services/transaction_service.dart';
import 'package:uuid/uuid.dart';

class PointsService {
  static const _uuid = Uuid();

  // Get current points balance
  static Future<int> getBalance() async {
    final user = AuthService.currentUser;
    if (user != null) {
      // user is non-nullable when obtained from AuthService.currentUser, but keep the check
      return await StorageService.loadPointsBalanceForUser(user.id);
    }
    return await StorageService.loadPointsBalance();
  }

  // Add points (NFC tap or purchase)
  static Future<bool> addPoints({
    required int points,
    required String businessId,
    required String description,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) return false;

    try {
      // Get current balance
      final currentBalance = await getBalance();
      final newBalance = currentBalance + points;

      // Create transaction record
      final transaction = Transaction(
        id: _uuid.v4(),
        userId: user.id,
        businessId: businessId,
        type: TransactionType.earn,
        points: points,
        description: description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save transaction
      await TransactionService.addTransaction(transaction);

      // Update balance (per-user)
      await StorageService.savePointsBalanceForUser(user.id, newBalance);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Deduct points (reward redemption)
  static Future<bool> deductPoints({
    required int points,
    required String businessId,
    required String description,
    String? rewardId,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) return false;

    try {
      // Get current balance
      final currentBalance = await getBalance();

      // Check if user has enough points
      if (currentBalance < points) {
        return false;
      }

      final newBalance = currentBalance - points;

      // Create transaction record
      final transaction = Transaction(
        id: _uuid.v4(),
        userId: user.id,
        businessId: businessId,
        type: TransactionType.redeem,
        points: points,
        description: description,
        rewardId: rewardId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save transaction
      await TransactionService.addTransaction(transaction);

      // Update balance (per-user)
      await StorageService.savePointsBalanceForUser(user.id, newBalance);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Check if user has enough points for a reward
  static Future<bool> hasEnoughPoints(int requiredPoints) async {
    final balance = await getBalance();
    return balance >= requiredPoints;
  }

  // Get points history summary
  static Future<Map<String, int>> getPointsSummary() async {
    final transactions = await TransactionService.getAllTransactions();

    int totalEarned = 0;
    int totalRedeemed = 0;

    for (final transaction in transactions) {
      if (transaction.type == TransactionType.earn) {
        totalEarned += transaction.points;
      } else {
        totalRedeemed += transaction.points;
      }
    }

    return {
      'totalEarned': totalEarned,
      'totalRedeemed': totalRedeemed,
      'currentBalance': await getBalance(),
    };
  }

  // Simulate NFC point collection
  static Future<bool> simulateNFCCollection({
    required String businessId,
    int? customPoints,
  }) async {
    // Simulate random points between 10-50 or use custom amount
    final points = customPoints ?? (10 + (DateTime.now().millisecond % 41));

    return await addPoints(
      points: points,
      businessId: businessId,
      description: 'NFC Tap Collection',
    );
  }

  // Reset all points (for testing)
  static Future<void> resetPoints() async {
    final user = AuthService.currentUser;
    if (user != null) {
      await StorageService.savePointsBalanceForUser(user.id, 0);
    } else {
      await StorageService.savePointsBalance(0);
    }
  }
}
