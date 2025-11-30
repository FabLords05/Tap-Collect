import 'package:grove_rewards/models/merchant.dart';
import 'package:grove_rewards/services/storage_service.dart';
import 'package:uuid/uuid.dart';

class MerchantAuthService {
  static const _uuid = Uuid();

  static const String _currentMerchantKey = 'current_merchant';
  static const String _merchantsKey = 'merchants';
  static const String _merchantCredsKey = 'merchant_credentials';

  static Merchant? _currentMerchant;

  static Merchant? get currentMerchant => _currentMerchant;
  static bool get isLoggedIn => _currentMerchant != null;

  // Initialize merchant auth and seed demo merchant
  static Future<void> initialize() async {
    // Load current merchant session
    final current = await StorageService.loadData(_currentMerchantKey);
    if (current != null) {
      try {
        _currentMerchant = Merchant.fromJson(current);
      } catch (_) {
        _currentMerchant = null;
        // Clean corrupted session
        await StorageService.saveData(_currentMerchantKey, {});
      }
    }

    // Seed demo merchants if none exists (create several for testing)
    final merchantsList = await StorageService.loadList(_merchantsKey);
    if (merchantsList.isEmpty) {
      final now = DateTime.now();

      final demoMerchants = [
        Merchant(
          id: _uuid.v4(),
          email: 'merchant@grovecafe.com',
          name: 'Grove Café Admin',
          businessId: 'sample-cafe-001',
          createdAt: now,
          updatedAt: now,
        ),
        Merchant(
          id: _uuid.v4(),
          email: 'merchant@cornerbistro.com',
          name: 'Corner Bistro Admin',
          businessId: 'corner-bistro-002',
          createdAt: now,
          updatedAt: now,
        ),
        Merchant(
          id: _uuid.v4(),
          email: 'merchant@greenmarket.com',
          name: 'Green Market Admin',
          businessId: 'green-market-003',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      await StorageService.saveList(
        _merchantsKey,
        demoMerchants.map((m) => m.toJson()).toList(),
      );

      // Seed credentials: email -> password (lowercase keys)
      final creds = {
        'merchant@grovecafe.com': '123456',
        'merchant@cornerbistro.com': 'corner123',
        'merchant@greenmarket.com': 'green123',
      };
      await StorageService.saveData(_merchantCredsKey, creds);
    }
  }

  static Future<Merchant?> login({
    required String email,
    required String password,
  }) async {
    // Load credentials map
    final creds = await StorageService.loadData(_merchantCredsKey) ?? {};
    final stored = creds[email.trim().toLowerCase()];
    if (stored == null || stored != password) {
      return null;
    }

    final merchants = await StorageService.loadList(_merchantsKey);
    for (final m in merchants) {
      try {
        final merchant = Merchant.fromJson(m);
        if (merchant.email.toLowerCase() == email.trim().toLowerCase()) {
          _currentMerchant = merchant;
          await StorageService.saveData(_currentMerchantKey, merchant.toJson());
          return merchant;
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  /// Set current merchant from a server response map and persist session
  static Future<Merchant?> setCurrentMerchantFromMap(
      Map<String, dynamic> data) async {
    try {
      final merchant = Merchant.fromJson(data);
      _currentMerchant = merchant;
      await StorageService.saveData(_currentMerchantKey, merchant.toJson());
      return merchant;
    } catch (_) {
      return null;
    }
  }

  static Future<void> logout() async {
    _currentMerchant = null;
    // Clear session
    await StorageService.saveData(_currentMerchantKey, {});
  }

  // Step 1: Add new merchant to local storage
  static Future<void> addMerchant({
    required String email,
    required String name,
    required String businessId,
    required String password,
  }) async {
    final merchants = await StorageService.loadList(_merchantsKey);

    final newMerchant = Merchant(
      id: _uuid.v4(),
      email: email,
      name: name,
      businessId: businessId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    merchants.add(newMerchant.toJson());
    await StorageService.saveList(_merchantsKey, merchants);

    // Step 2: Store credentials
    final creds = await StorageService.loadData(_merchantCredsKey) ?? {};
    creds[email.toLowerCase()] = password;
    await StorageService.saveData(_merchantCredsKey, creds);
  }
}
