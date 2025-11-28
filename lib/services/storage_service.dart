import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _userKey = 'current_user';
  static const String _transactionsKey = 'user_transactions';
  static const String _rewardsKey = 'business_rewards';
  static const String _vouchersKey = 'user_vouchers';
  static const String _businessesKey = 'businesses';
  static const String _pointsBalanceKey = 'points_balance';

  static Future<SharedPreferences> get _prefs async {
    return await SharedPreferences.getInstance();
  }

  // Generic save method
  static Future<void> saveData(String key, Map<String, dynamic> data) async {
    final prefs = await _prefs;
    await prefs.setString(key, jsonEncode(data));
  }

  // Generic load method
  static Future<Map<String, dynamic>?> loadData(String key) async {
    try {
      final prefs = await _prefs;
      final data = prefs.getString(key);
      if (data != null) {
        return jsonDecode(data) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Generic save list method
  static Future<void> saveList(String key, List<Map<String, dynamic>> list) async {
    final prefs = await _prefs;
    await prefs.setString(key, jsonEncode(list));
  }

  // Generic load list method
  static Future<List<Map<String, dynamic>>> loadList(String key) async {
    try {
      final prefs = await _prefs;
      final data = prefs.getString(key);
      if (data != null) {
        final decoded = jsonDecode(data);
        if (decoded is List) {
          return List<Map<String, dynamic>>.from(
            decoded.map((item) => Map<String, dynamic>.from(item))
          );
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Save user data
  static Future<void> saveUser(Map<String, dynamic> user) async {
    await saveData(_userKey, user);
  }

  // Load user data
  static Future<Map<String, dynamic>?> loadUser() async {
    return await loadData(_userKey);
  }

  // Clear user data (logout)
  static Future<void> clearUser() async {
    final prefs = await _prefs;
    await prefs.remove(_userKey);
  }

  // Points balance methods
  static Future<void> savePointsBalance(int balance) async {
    final prefs = await _prefs;
    await prefs.setInt(_pointsBalanceKey, balance);
  }

  static Future<int> loadPointsBalance() async {
    final prefs = await _prefs;
    return prefs.getInt(_pointsBalanceKey) ?? 0;
  }

  // Per-user points balance (stored as key: points_balance_{userId})
  static Future<void> savePointsBalanceForUser(String userId, int balance) async {
    final prefs = await _prefs;
    await prefs.setInt('\${_pointsBalanceKey}_$userId', balance);
  }

  static Future<int> loadPointsBalanceForUser(String userId) async {
    final prefs = await _prefs;
    return prefs.getInt('\${_pointsBalanceKey}_$userId') ?? 0;
  }

  // Clear the old global points balance key (used during migration)
  static Future<void> clearGlobalPointsBalance() async {
    final prefs = await _prefs;
    await prefs.remove(_pointsBalanceKey);
  }

  // Transactions methods
  static Future<void> saveTransactions(List<Map<String, dynamic>> transactions) async {
    await saveList(_transactionsKey, transactions);
  }

  static Future<List<Map<String, dynamic>>> loadTransactions() async {
    return await loadList(_transactionsKey);
  }

  // Rewards methods
  static Future<void> saveRewards(List<Map<String, dynamic>> rewards) async {
    await saveList(_rewardsKey, rewards);
  }

  static Future<List<Map<String, dynamic>>> loadRewards() async {
    return await loadList(_rewardsKey);
  }

  // Vouchers methods
  static Future<void> saveVouchers(List<Map<String, dynamic>> vouchers) async {
    await saveList(_vouchersKey, vouchers);
  }

  static Future<List<Map<String, dynamic>>> loadVouchers() async {
    return await loadList(_vouchersKey);
  }

  // Businesses methods
  static Future<void> saveBusinesses(List<Map<String, dynamic>> businesses) async {
    await saveList(_businessesKey, businesses);
  }

  static Future<List<Map<String, dynamic>>> loadBusinesses() async {
    return await loadList(_businessesKey);
  }

  // Clear all data
  static Future<void> clearAll() async {
    final prefs = await _prefs;
    await prefs.clear();
  }
}