import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart'; // Import NFC Manager
import 'package:grove_rewards/theme.dart';
import 'package:grove_rewards/services/auth_service.dart';
import 'package:grove_rewards/services/merchant_auth_service.dart';
import 'package:grove_rewards/services/local_database.dart';
import 'package:grove_rewards/services/storage_service.dart'; // Import Storage
import 'package:grove_rewards/screens/auth/login_screen.dart';
import 'package:grove_rewards/screens/home/home_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AuthService.initialize();
  await MerchantAuthService.initialize();

  // --- NEW: HARDWARE DETECTION LOGIC ---
  // 1. Check if we already have a mode saved
  String? currentMode = await StorageService.getAppMode();
  // -------------------------------------

  // Migrate any global points balance into the current user's storage (one-time)
  var migratedPoints = false;
  try {
    final user = AuthService.currentUser;
    if (user != null) {
      final globalPoints = await StorageService.loadPointsBalance();
      final userPoints = await StorageService.loadPointsBalanceForUser(user.id);
      if (globalPoints > 0 && userPoints == 0) {
        await StorageService.savePointsBalanceForUser(user.id, globalPoints);
        await StorageService.clearGlobalPointsBalance();
        migratedPoints = true;
      }
    }
  } catch (_) {
    // Ignore migration errors — proceed with app startup
  }
  // Initialize local database (best-effort; don't block startup on failure)
  try {
    await LocalDatabase.instance.database;
    // optional: insert a sample business for quick testing (no-op if exists)
    await LocalDatabase.instance.upsertBusiness({
      'id': 'sample-biz',
      'name': 'Sample Business',
      'meta': '{}',
    });
  } catch (_) {
    // Silently ignore DB init errors so the app can still run
  }

  runApp(MyApp(migratedPoints: migratedPoints));
}

// Add a global key so other code (NFC handler) can call into the widget state
final GlobalKey<_NfcTapHandlerState> nfcTapKey =
    GlobalKey<_NfcTapHandlerState>();

class MyApp extends StatelessWidget {
  final bool migratedPoints;
  const MyApp({super.key, this.migratedPoints = false});

  static bool _migrationShown = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tap&Collect',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      // Wrap HomeScreen with NfcTapHandler so it owns setState/context
      home: AuthService.isLoggedIn
          ? NfcTapHandler(key: nfcTapKey, child: const HomeScreen())
          : const LoginScreen(),
      builder: (context, child) {
        if (migratedPoints && !_migrationShown) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final messenger = ScaffoldMessenger.maybeOf(context);
            if (messenger != null) {
              messenger.showSnackBar(
                const SnackBar(
                    content: Text('Your points were migrated to your account')),
              );
              _migrationShown = true;
            }
          });
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}

// New Stateful widget that owns the points balance and the NFC handler
class NfcTapHandler extends StatefulWidget {
  final Widget child;
  const NfcTapHandler({super.key, required this.child});

  @override
  _NfcTapHandlerState createState() => _NfcTapHandlerState();
}

class _NfcTapHandlerState extends State<NfcTapHandler> {
  int _pointsBalance = 0;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    final user = AuthService.currentUser;
    if (user != null) {
      final bal = await StorageService.loadPointsBalanceForUser(user.id);
      setState(() => _pointsBalance = bal);
    }
  }

  // Call this from NFC code:
  // nfcTapKey.currentState?.handleNfcTap(businessId, amount: 5.0);
  Future<void> handleNfcTap(String businessId, {double? amount}) async {
    final user = AuthService.currentUser;
    if (user == null) return;

    final newBalance = await TransactionService.postTransaction(
      userId: user.id,
      businessId: businessId,
      type: 'EARN',
      points: null, // let server compute from amount_spent if provided
      amountSpent: amount,
      description: 'NFC tap',
    );

    if (!mounted) return;

    if (newBalance != null) {
      setState(() {
        _pointsBalance = newBalance;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You earned points! New balance: $newBalance')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tap recorded but failed to update balance')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // You can optionally pass _pointsBalance to the child via constructor
    // if HomeScreen accepts it. For now we just render the child.
    return widget.child;
  }
}

class TransactionService {
  // Use emulator host for Android emulator; replace when deploying or testing on device
  static const _serverBase = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  /// Send a transaction and update local stored balance on success.
  /// returns the newBalance on success, null on failure.
  static Future<int?> postTransaction({
    required String userId,
    required String businessId,
    required String type, // 'EARN' or 'REDEEM'
    int? points,
    double? amountSpent,
    String? description,
  }) async {
    final url = Uri.parse('$_serverBase/transactions');
    final body = <String, dynamic>{
      'user_id': userId,
      'business_id': businessId,
      'type': type,
      if (points != null) 'points': points,
      if (amountSpent != null) 'amount_spent': amountSpent,
      if (description != null) 'description': description,
    };

    try {
      final resp = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body));

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        // server should return new_balance (see server handler)
        final newBalance = data['new_balance'];
        if (newBalance != null) {
          final int balanceInt = (newBalance).toInt();
          await StorageService.savePointsBalanceForUser(userId, balanceInt);
          return balanceInt;
        }
        return null;
      } else {
        // log server error for debugging
        // print('trans failed ${resp.statusCode}: ${resp.body}');
        return null;
      }
    } catch (e) {
      // network error
      // print('trans network error: $e');
      return null;
    }
  }
}

// Replace the erroneous top-level handler with a small delegate that calls the StatefulWidget's method.
Future<void> triggerNfcTap(String businessId, {double? amount}) async {
  // Delegates to the NfcTapHandler state; safe if state isn't mounted.
  await nfcTapKey.currentState?.handleNfcTap(businessId, amount: amount);
}
