import 'package:grove_rewards/models/transaction.dart';
import 'package:grove_rewards/services/auth_service.dart';
import 'package:grove_rewards/services/storage_service.dart';

class TransactionService {
  // Add new transaction
  static Future<void> addTransaction(Transaction transaction) async {
    try {
      final transactions = await getAllTransactions();
      transactions.insert(0, transaction); // Add to beginning for chronological order
      
      final transactionJsonList = transactions.map((t) => t.toJson()).toList();
      await StorageService.saveTransactions(transactionJsonList);
    } catch (e) {
      // Skip corrupted entries and continue
    }
  }

  // Get all transactions for current user
  static Future<List<Transaction>> getAllTransactions() async {
    final user = AuthService.currentUser;
    if (user == null) return [];

    try {
      final transactionData = await StorageService.loadTransactions();
      final transactions = <Transaction>[];
      
      for (final data in transactionData) {
        try {
          final transaction = Transaction.fromJson(data);
          if (transaction.userId == user.id) {
            transactions.add(transaction);
          }
        } catch (e) {
          // Skip corrupted entries and continue
          continue;
        }
      }
      
      // Sort by creation date (newest first)
      transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return transactions;
    } catch (e) {
      return [];
    }
  }

  // Get recent transactions (last N transactions)
  static Future<List<Transaction>> getRecentTransactions([int limit = 10]) async {
    final allTransactions = await getAllTransactions();
    return allTransactions.take(limit).toList();
  }

  // Get transactions by type
  static Future<List<Transaction>> getTransactionsByType(TransactionType type) async {
    final allTransactions = await getAllTransactions();
    return allTransactions.where((t) => t.type == type).toList();
  }

  // Get transactions for a specific business
  static Future<List<Transaction>> getTransactionsForBusiness(String businessId) async {
    final allTransactions = await getAllTransactions();
    return allTransactions.where((t) => t.businessId == businessId).toList();
  }

  // Get transaction by ID
  static Future<Transaction?> getTransactionById(String transactionId) async {
    final allTransactions = await getAllTransactions();
    try {
      return allTransactions.firstWhere((t) => t.id == transactionId);
    } catch (e) {
      return null;
    }
  }

  // ===== Merchant/global helpers =====
  // Load all transactions across all users
  static Future<List<Transaction>> getAllTransactionsGlobal() async {
    try {
      final transactionData = await StorageService.loadTransactions();
      final transactions = <Transaction>[];
      for (final data in transactionData) {
        try {
          transactions.add(Transaction.fromJson(data));
        } catch (_) {
          continue;
        }
      }
      transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return transactions;
    } catch (_) {
      return [];
    }
  }

  // Get transactions for a business across all users
  static Future<List<Transaction>> getTransactionsForBusinessGlobal(String businessId) async {
    final all = await getAllTransactionsGlobal();
    return all.where((t) => t.businessId == businessId).toList();
  }

  // Aggregate monthly points for a business (earned vs redeemed)
  static Future<Map<String, dynamic>> getMonthlySummaryForBusiness(String businessId, {DateTime? month}) async {
    final targetMonth = month ?? DateTime.now();
    final startDate = DateTime(targetMonth.year, targetMonth.month, 1);
    final endDate = DateTime(targetMonth.year, targetMonth.month + 1, 1);

    final txs = await getTransactionsForBusinessGlobal(businessId);
    final filtered = txs.where((t) => t.createdAt.isAfter(startDate) && t.createdAt.isBefore(endDate));

    int earned = 0;
    int redeemed = 0;
    for (final t in filtered) {
      if (t.type == TransactionType.earn) {
        earned += t.points;
      } else {
        redeemed += t.points;
      }
    }

    return {
      'earnedPoints': earned,
      'redeemedPoints': redeemed,
      'netPoints': earned - redeemed,
      'month': targetMonth.month,
      'year': targetMonth.year,
      'count': filtered.length,
    };
  }

  // Get transactions within date range
  static Future<List<Transaction>> getTransactionsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final allTransactions = await getAllTransactions();
    return allTransactions.where((t) => 
      t.createdAt.isAfter(startDate) && t.createdAt.isBefore(endDate)
    ).toList();
  }

  // Get monthly transaction summary
  static Future<Map<String, dynamic>> getMonthlyTransactionSummary([DateTime? month]) async {
    final targetMonth = month ?? DateTime.now();
    final startDate = DateTime(targetMonth.year, targetMonth.month, 1);
    final endDate = DateTime(targetMonth.year, targetMonth.month + 1, 1);
    
    final monthlyTransactions = await getTransactionsByDateRange(
      startDate: startDate,
      endDate: endDate,
    );

    int earnedPoints = 0;
    int redeemedPoints = 0;
    int totalTransactions = monthlyTransactions.length;

    for (final transaction in monthlyTransactions) {
      if (transaction.type == TransactionType.earn) {
        earnedPoints += transaction.points;
      } else {
        redeemedPoints += transaction.points;
      }
    }

    return {
      'totalTransactions': totalTransactions,
      'earnedPoints': earnedPoints,
      'redeemedPoints': redeemedPoints,
      'netPoints': earnedPoints - redeemedPoints,
      'month': targetMonth.month,
      'year': targetMonth.year,
    };
  }

  // Clear all transactions (for testing)
  static Future<void> clearAllTransactions() async {
    await StorageService.saveTransactions([]);
  }

  // Initialize with sample data
  static Future<void> initializeSampleData() async {
    final user = AuthService.currentUser;
    if (user == null) return;

    final existingTransactions = await getAllTransactions();
    if (existingTransactions.isNotEmpty) return; // Don't add sample data if transactions exist

    // Sample transactions data will be added by the points service when needed
  }
}