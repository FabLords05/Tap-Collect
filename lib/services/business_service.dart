import 'package:grove_rewards/models/business.dart';
import 'package:grove_rewards/services/storage_service.dart';

class BusinessService {
  // Get all businesses
  static Future<List<Business>> getAllBusinesses() async {
    try {
      final businessData = await StorageService.loadBusinesses();
      final businesses = <Business>[];

      for (final data in businessData) {
        try {
          final business = Business.fromJson(data);
          businesses.add(business);
        } catch (e) {
          // Skip corrupted entries
          continue;
        }
      }

      // Sort by name
      businesses.sort((a, b) => a.name.compareTo(b.name));
      return businesses;
    } catch (e) {
      return [];
    }
  }

  // Get business by ID
  static Future<Business?> getBusinessById(String businessId) async {
    final allBusinesses = await getAllBusinesses();
    try {
      return allBusinesses.firstWhere((b) => b.id == businessId);
    } catch (e) {
      return null;
    }
  }

  // Add new business
  static Future<void> addBusiness(Business business) async {
    try {
      final businesses = await getAllBusinesses();
      businesses.add(business);

      final businessJsonList = businesses.map((b) => b.toJson()).toList();
      await StorageService.saveBusinesses(businessJsonList);
    } catch (e) {
      // Handle error
    }
  }

  // Update business
  static Future<void> updateBusiness(Business updatedBusiness) async {
    try {
      final businesses = await getAllBusinesses();
      final index = businesses.indexWhere((b) => b.id == updatedBusiness.id);

      if (index >= 0) {
        businesses[index] = updatedBusiness;
        final businessJsonList = businesses.map((b) => b.toJson()).toList();
        await StorageService.saveBusinesses(businessJsonList);
      }
    } catch (e) {
      // Handle error
    }
  }

  // Get businesses near location (placeholder for future feature)
  static Future<List<Business>> getBusinessesNearLocation(
      double latitude, double longitude) async {
    // For now, just return all businesses
    return await getAllBusinesses();
  }

  // Search businesses by name
  static Future<List<Business>> searchBusinesses(String query) async {
    final allBusinesses = await getAllBusinesses();
    final searchQuery = query.toLowerCase().trim();

    if (searchQuery.isEmpty) return allBusinesses;

    return allBusinesses
        .where((b) =>
            b.name.toLowerCase().contains(searchQuery) ||
            b.description.toLowerCase().contains(searchQuery))
        .toList();
  }

  // Initialize sample business data
  static Future<void> initializeSampleData() async {
    final existingBusinesses = await getAllBusinesses();
    if (existingBusinesses.isNotEmpty) {
      return; // Don't add sample data if businesses exist
    }

    final now = DateTime.now();
    final sampleBusinesses = [
      Business(
        id: 'sample-cafe-001',
        name: 'Grove Café',
        description: 'Artisan coffee and fresh pastries in a cozy atmosphere',
        logoUrl: null,
        address: '123 Main Street, Downtown',
        phone: '(555) 123-4567',
        email: 'info@grovecafe.com',
        pointsPerDollar: 10, // 10 points per dollar spent
        createdAt: now,
        updatedAt: now,
      ),
      Business(
        id: 'sample-cafe-002',
        name: 'The Green Bean',
        description: 'Sustainable coffee roasters with locally sourced beans',
        logoUrl: null,
        address: '456 Oak Avenue, Midtown',
        phone: '(555) 987-6543',
        email: 'hello@greenbeanroasters.com',
        pointsPerDollar: 15, // 15 points per dollar spent
        createdAt: now,
        updatedAt: now,
      ),
      Business(
        id: 'sample-cafe-003',
        name: 'Mocha & More',
        description: 'Coffee, tea, and delicious homemade treats',
        logoUrl: null,
        address: '789 Pine Road, Uptown',
        phone: '(555) 456-7890',
        email: 'contact@mochaandmore.com',
        pointsPerDollar: 12, // 12 points per dollar spent
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final businessJsonList = sampleBusinesses.map((b) => b.toJson()).toList();
    await StorageService.saveBusinesses(businessJsonList);
  }

  // Clear all businesses (for testing)
  static Future<void> clearAllBusinesses() async {
    await StorageService.saveBusinesses([]);
  }

  // Get default business (for NFC demo)
  static Future<Business?> getDefaultBusiness() async {
    return await getBusinessById('sample-cafe-001');
  }
}
