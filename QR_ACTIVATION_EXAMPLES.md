
# QR Activation Feature - Code Examples & Integration Guide

## Quick Reference

### 1. Basic Usage in Dashboard

The feature is already integrated into `DashboardScreen`. Here's what happens:

```dart
// In dashboard_screen.dart build() method
if (!_isBusinessActivated)
  // Shows QR scan button until activated
  BusinessActivationButton(
    businessId: _currentBusinessId,
    businessName: 'This Business',
    onActivationComplete: _onBusinessActivationComplete,
  )
else
  // Shows NFC tap button after activation
  NFCCollectionWidget(
    onPointsCollected: _onPointsCollected,
  ),
```

---

## 2. Getting Business ID from Navigation

### Option A: Route Parameters (Recommended)
```dart
// When navigating to dashboard from a business listing
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const DashboardScreen(),
    settings: RouteSettings(
      arguments: 'business_abc123', // Pass business ID here
    ),
  ),
);

// In DashboardScreen.initState()
@override
void initState() {
  super.initState();
  // Get business ID from route arguments
  _currentBusinessId = ModalRoute.of(context)?.settings.arguments as String? 
      ?? 'business_demo_001';
  _loadDashboardData();
  _initializeNFC();
  _checkBusinessActivation();
}
```

### Option B: Using go_router (if transitioning)
```dart
// Define route
GoRoute(
  path: 'dashboard/:businessId',
  builder: (context, state) => DashboardScreen(
    businessId: state.pathParameters['businessId']!,
  ),
),

// Navigate
context.go('/dashboard/business_abc123');

// In DashboardScreen constructor
class DashboardScreen extends StatefulWidget {
  final String businessId;
  const DashboardScreen({
    super.key,
    required this.businessId,
  });
  
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

// Use in state
@override
void initState() {
  super.initState();
  _currentBusinessId = widget.businessId;
  // ...
}
```

### Option C: Provider Pattern (for global state)
```dart
// Create provider
final currentBusinessProvider = StateProvider<String>((ref) {
  return 'business_demo_001';
});

// Use in DashboardScreen
@override
void initState() {
  super.initState();
  _currentBusinessId = ref.read(currentBusinessProvider);
}
```

---

## 3. Advanced Scenarios

### Scenario A: Multiple Businesses in One Session

```dart
// User taps on a business card in a listing
void _handleBusinessTap(Business business) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const DashboardScreen(),
      settings: RouteSettings(arguments: business.id),
    ),
  );
}

// DashboardScreen automatically:
// 1. Checks if this business ID is in activatedBusinessIds
// 2. Shows QR scan if not activated
// 3. Shows NFC if already activated
// 4. User can go back and visit another business
```

### Scenario B: Manual Activation Check

```dart
// Anywhere in the app, check activation status
bool isActivated = BusinessActivationService.isBusinessActivated('business_xyz');

if (isActivated) {
  print('Ready to collect points at this business!');
} else {
  print('Need to scan QR first');
}

// Get all activated businesses
List<String> myBusinesses = BusinessActivationService.getActivatedBusinesses();
print('Activated at ${myBusinesses.length} businesses');
```

### Scenario C: Deactivate a Business

```dart
// Remove activation (e.g., after customer request)
await BusinessActivationService.deactivateBusiness('business_xyz');

// Dashboard will now show QR button again on next visit
```

---

## 4. Backend Integration Examples

### Option A: Direct API Call in Service

```dart
// Update BusinessActivationService.activateBusiness()
import 'package:http/http.dart' as http;
import 'dart:convert';

static Future<bool> activateBusiness(String businessId) async {
  try {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) return false;

    if (currentUser.activatedBusinessIds.contains(businessId)) {
      return true;
    }

    final updatedList = [...currentUser.activatedBusinessIds, businessId];
    
    // API call to persist
    const String apiUrl = 'http://localhost:8080'; // Update for production
    
    final response = await http.patch(
      Uri.parse('$apiUrl/users/${currentUser.id}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthService.getToken()}', // If needed
      },
      body: jsonEncode({
        'activated_business_ids': updatedList,
      }),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Request timeout'),
    );

    if (response.statusCode == 200) {
      // Success: update local
      final updatedUser = currentUser.copyWith(
        activatedBusinessIds: updatedList,
      );
      AuthService.updateCurrentUser(updatedUser);
      return true;
    } else {
      throw Exception('Server returned ${response.statusCode}');
    }
  } catch (e) {
    print('Error activating business: $e');
    return false;
  }
}
```

### Option B: Using a Shared HTTP Client

```dart
// Create a dedicated HTTP service
class ApiService {
  static const String baseUrl = 'http://localhost:8080';
  
  static Future<Map<String, dynamic>> updateUserActivations(
    String userId,
    List<String> businessIds,
  ) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/users/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'activated_business_ids': businessIds}),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update: ${response.statusCode}');
    }
  }
}

// Use in service
import 'package:grove_rewards/services/api_service.dart';

await ApiService.updateUserActivations(
  currentUser.id,
  updatedList,
);
```

---

## 5. Testing the Feature

### Unit Test Example

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:grove_rewards/services/business_activation_service.dart';
import 'package:grove_rewards/services/qr_service.dart';

void main() {
  group('Business Activation', () {
    
    test('Validates business QR code correctly', () {
      final businessId = 'business_123';
      final validQR = 'business_123';
      final invalidQR = 'business_456';
      
      expect(
        QRService.validateBusinessQRData(validQR, businessId),
        true,
      );
      expect(
        QRService.validateBusinessQRData(invalidQR, businessId),
        false,
      );
    });
    
    test('Tracks activated businesses', () {
      BusinessActivationService.activateBusiness('business_1');
      
      expect(
        BusinessActivationService.isBusinessActivated('business_1'),
        true,
      );
      expect(
        BusinessActivationService.isBusinessActivated('business_2'),
        false,
      );
    });
  });
}
```

### Widget Test Example

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:grove_rewards/widgets/business_activation_button.dart';

void main() {
  testWidgets('Shows scan button before activation', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BusinessActivationButton(
            businessId: 'test_business',
            businessName: 'Test Shop',
            onActivationComplete: () {},
          ),
        ),
      ),
    );
    
    expect(find.text('Scan QR to Activate'), findsOneWidget);
    expect(find.byIcon(Icons.qr_code_2), findsOneWidget);
  });
}
```

---

## 6. Merchant Dashboard Integration

### Generate QR Code for Business

```dart
// In merchant app, when setting up a business
import 'package:qr_flutter/qr_flutter.dart';

class MerchantQRSetup extends StatelessWidget {
  final String businessId;
  
  const MerchantQRSetup({required this.businessId});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Print this QR Code in your store:'),
        QrImage(
          data: businessId,
          version: QrVersions.auto,
          size: 200.0,
        ),
        const Text('Customers will scan this to unlock NFC features'),
      ],
    );
  }
}
```

---

## 7. Error Handling & Edge Cases

### Handling Network Failures

```dart
// In BusinessActivationService
static Future<bool> activateBusiness(String businessId) async {
  try {
    // ... validation ...
    
    // Attempt API call with retry logic
    int retries = 3;
    while (retries > 0) {
      try {
        await ApiService.updateUserActivations(userId, updatedList);
        break; // Success
      } on SocketException {
        retries--;
        if (retries == 0) throw Exception('Network error after 3 retries');
        await Future.delayed(const Duration(seconds: 1)); // Retry delay
      }
    }
    
    // Update local state
    AuthService.updateCurrentUser(updatedUser);
    return true;
    
  } catch (e) {
    print('Activation failed: $e');
    // Keep activation in local state but mark as "pending sync"
    // Retry on next app startup
    return false;
  }
}
```

### Handling QR Scan Timeout

```dart
// In QRService
static Future<String?> scanQRCode(BuildContext context) async {
  try {
    String? scannedData;
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        // ... scanner UI ...
      ),
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        // Auto-close scanner after 30 seconds
        Navigator.pop(context);
        return null;
      },
    );
    
    return scannedData;
  } catch (e) {
    print('QR scan error: $e');
    return null;
  }
}
```

---

## 8. UI Customization Examples

### Custom Activation Button

```dart
// If you want to use your own button instead of BusinessActivationButton

ElevatedButton.icon(
  onPressed: () async {
    final qrData = await QRService.scanQRCode(context);
    
    if (qrData != null && 
        QRService.validateBusinessQRData(qrData, businessId)) {
      final success = await BusinessActivationService.activateBusiness(businessId);
      
      if (success && mounted) {
        setState(() => _isActivated = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activated!')),
        );
      }
    }
  },
  icon: const Icon(Icons.qr_code_2),
  label: const Text('Scan QR'),
),
```

### Showing List of Activated Businesses

```dart
// Display all businesses user has activated
class ActivatedBusinessesList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final activatedIds = BusinessActivationService.getActivatedBusinesses();
    
    return ListView.builder(
      itemCount: activatedIds.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text('Business ${activatedIds[index]}'),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              BusinessActivationService.deactivateBusiness(
                activatedIds[index],
              );
            },
          ),
        );
      },
    );
  }
}
```

---

## 9. Migration Path for Existing Users

```dart
// If adding this feature to existing app with users
// In AuthService.initialize()

static Future<void> initialize() async {
  final userData = await StorageService.loadUser();
  if (userData != null) {
    try {
      // Handle old user data without activatedBusinessIds
      if (!userData.containsKey('activated_business_ids')) {
        userData['activated_business_ids'] = []; // Default empty
      }
      _currentUser = User.fromJson(userData);
    } catch (e) {
      await StorageService.clearUser();
    }
  }
}
```

---

## 10. Logging & Analytics

### Track Activation Events

```dart
// Add analytics tracking
void _trackActivation(String businessId, bool success) {
  // Example: using Firebase Analytics or custom logging
  print('[ACTIVATION] Business: $businessId, Success: $success');
  
  // Could send to analytics:
  // analyticsService.logEvent(
  //   name: 'business_activated',
  //   parameters: {
  //     'business_id': businessId,
  //     'timestamp': DateTime.now().toIso8601String(),
  //   },
  // );
}

// In BusinessActivationButton
Future<void> _handleQRScan() async {
  final qrData = await QRService.scanQRCode(context);
  
  if (qrData != null) {
    final isValid = QRService.validateBusinessQRData(qrData, widget.businessId);
    
    if (isValid) {
      final success = await BusinessActivationService.activateBusiness(
        widget.businessId,
      );
      _trackActivation(widget.businessId, success);
    }
  }
}
```

---

**Ready to implement!** Use these examples as references for customizing the feature to your specific needs.
