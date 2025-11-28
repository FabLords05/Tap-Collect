import 'package:grove_rewards/models/user.dart';
import 'package:grove_rewards/services/storage_service.dart';
import 'package:grove_rewards/services/api_service.dart';
import 'package:grove_rewards/services/app_logger.dart';

class AuthService {
  static User? _currentUser;

  // Get current user
  static User? get currentUser => _currentUser;

  // Check if user is logged in
  static bool get isLoggedIn => _currentUser != null;

  // Initialize: Just load from local storage (keep user logged in)
  static Future<void> initialize() async {
    final userData = await StorageService.loadUser();
    if (userData != null) {
      try {
        _currentUser = User.fromJson(userData);
      } catch (e) {
        await StorageService.clearUser();
      }
    }
  }

  // --- REAL LOGIN LOGIC ---
  static Future<User?> login({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Call the Server
      final userData = await ApiService.loginUser(email, password);

      // 2. If server returned null, login failed
      if (userData == null) {
        return null;
      }

      // 3. Convert JSON to User Object
      final user = User.fromJson(userData);

      // 4. Save to Local Storage (Keep me logged in)
      await StorageService.saveUser(user.toJson());
      
      // 5. Update State
      _currentUser = user;
      
      return user;
    } catch (e, st) {
      AppLogger.error("AuthService Login Error: $e", e, st);
      return null;
    }
  }

  // --- REAL REGISTER LOGIC ---
  static Future<User?> register({
    required String email,
    required String password,
    required String name,
  }) async {
    // We try to create the account
    bool success = await ApiService.registerUser(name, email, password);
    
    if (success) {
      // If successful, we automatically log them in
      return await login(email: email, password: password);
    }
    return null;
  }

  // Update profile locally
  static Future<User?> updateProfile({String? name, String? avatar}) async {
    if (_currentUser == null) return null;
    final updatedUser = _currentUser!.copyWith(
      name: name,
      avatar: avatar,
      updatedAt: DateTime.now(),
    );
    await StorageService.saveUser(updatedUser.toJson());
    _currentUser = updatedUser;
    return updatedUser;
  }

  // --- THIS IS THE MISSING METHOD ---
  // It allows BusinessActivationService to save the new business list
  static Future<void> updateCurrentUser(User user) async {
    try {
      await StorageService.saveUser(user.toJson());
      _currentUser = user;
    } catch (e, st) {
      AppLogger.error('Error updating current user: $e', e, st);
    }
  }

  static Future<void> logout() async {
    _currentUser = null;
    await StorageService.clearUser();
  }
}