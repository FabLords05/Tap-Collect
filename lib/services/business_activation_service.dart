import 'package:grove_rewards/services/auth_service.dart';
import 'package:grove_rewards/services/api_service.dart'; // Import the API
import 'package:grove_rewards/services/app_logger.dart';

class BusinessActivationService {
  
  // Activate a business for the current user
  static Future<bool> activateBusiness(String businessId) async {
    try {
      final currentUser = AuthService.currentUser;
      if (currentUser == null) return false;

      // 1. Check if already activated locally
      if (currentUser.activatedBusinessIds.contains(businessId)) {
        return true; 
      }

      // 2. Prepare the new list
      final updatedList = [...currentUser.activatedBusinessIds, businessId];

      // 3. Save to Backend API (MongoDB)
      bool success = await ApiService.updateUser(currentUser.id, {
        'activated_business_ids': updatedList
      });

      // 4. If Server Success, Update Local App State
      if (success) {
        final updatedUser = currentUser.copyWith(
          activatedBusinessIds: updatedList,
        );
        await AuthService.updateCurrentUser(updatedUser);
        return true;
      }
      
      return false;
    } catch (e, st) {
      AppLogger.error('Error activating business: $e', e, st);
      return false;
    }
  }

  // Deactivate a business
  static Future<bool> deactivateBusiness(String businessId) async {
    try {
      final currentUser = AuthService.currentUser;
      if (currentUser == null) return false;

      // 1. Remove the ID
      final updatedList = currentUser.activatedBusinessIds
          .where((id) => id != businessId)
          .toList();

      // 2. Save to Backend API
      bool success = await ApiService.updateUser(currentUser.id, {
        'activated_business_ids': updatedList
      });

      // 3. Update Local App State
      if (success) {
        final updatedUser = currentUser.copyWith(
          activatedBusinessIds: updatedList,
        );
        await AuthService.updateCurrentUser(updatedUser);
        return true;
      }

      return false;
    } catch (e, st) {
      AppLogger.error('Error deactivating business: $e', e, st);
      return false;
    }
  }

  // Check if business is activated
  static bool isBusinessActivated(String businessId) {
    final currentUser = AuthService.currentUser;
    return currentUser?.activatedBusinessIds.contains(businessId) ?? false;
  }

  // Get list of activated businesses
  static List<String> getActivatedBusinesses() {
    return AuthService.currentUser?.activatedBusinessIds ?? [];
  }
}