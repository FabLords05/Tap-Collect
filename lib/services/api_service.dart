import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:grove_rewards/services/app_logger.dart';

// Helper functions for normalization
String _titleCase(String? input) {
  if (input == null) return '';
  return input
      .split(RegExp(r"\s+"))
      .where((s) => s.isNotEmpty)
      .map((word) => word.length == 1
          ? word.toUpperCase()
          : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
      .join(' ');
}

String _normalizeEmail(String? input) => (input ?? '').trim().toLowerCase();

class ApiService {
  // Use 'http://localhost:8080' for Chrome/Web
  // Use 'http://10.0.2.2:8080' for Android Emulator
  // Use 'http://192.168.1.X:8080' for Real Phone (Check ipconfig)
  //static const String baseUrl = 'http://localhost:8080';
  static const String baseUrl = 'https://tap-collect.onrender.com';

  // 1. Health Check
  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 2. Register User (With Normalization)
  static Future<bool> registerUser(
      String name, String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/register');
    final normalizedName = _titleCase(name);
    final normalizedEmail = _normalizeEmail(email);

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": normalizedName,
          "email": normalizedEmail,
          "password": password,
          "avatar": "default.png"
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // 3. Login User (With Normalization)
  static Future<Map<String, dynamic>?> loginUser(
      String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    try {
      final normalizedEmail = _normalizeEmail(email);
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": normalizedEmail, "password": password}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // 4. Update User (RESTORED - Critical for Business Activation)
  static Future<bool> updateUser(
      String userId, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/users/$userId');
    try {
      final response = await http.patch(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e, st) {
      // Using AppLogger if available, or print fallback
      try {
        AppLogger.error('Update user error: $e', e, st);
      } catch (_) {
        print("Update Error: $e");
      }
      return false;
    }
  }

  // 5. Earn Points
  static Future<bool> earnPoints({
    required String userId,
    required int amount,
    String businessId = "sample-biz",
  }) async {
    final url = Uri.parse('$baseUrl/transactions');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "business_id": businessId,
          "type": "EARN",
          "points": amount,
          "description": "NFC Tap Collection",
        }),
      );

      if (response.statusCode == 201) {
        print("✅ Points Saved: ${response.body}");
        return true;
      }
      return false;
    } catch (e) {
      print("❌ Error saving points: $e");
      return false;
    }
  }

  // 6. Delete user account
  static Future<bool> deleteUser(String userId) async {
    final url = Uri.parse('$baseUrl/users/$userId');
    try {
      final response = await http.delete(url);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e, st) {
      try {
        AppLogger.error('Delete user error: $e', e, st);
      } catch (_) {}
      return false;
    }
  }

  // 7. Export user data
  static Future<Map<String, dynamic>?> exportUserData(String userId) async {
    final url = Uri.parse('$baseUrl/users/$userId/export');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e, st) {
      try {
        AppLogger.error('Export user data error: $e', e, st);
      } catch (_) {}
      return null;
    }
  }

  // 8. Upload avatar
  static Future<String?> uploadAvatar(
      String userId, String filename, String base64Data) async {
    final url = Uri.parse('$baseUrl/users/$userId/avatar');
    try {
      final response = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'filename': filename, 'data': base64Data}));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['avatar'] as String?;
      }
      return null;
    } catch (e, st) {
      try {
        AppLogger.error('Upload avatar error: $e', e, st);
      } catch (_) {}
      return null;
    }
  }
}
