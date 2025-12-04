# Tap&Collect Copilot Instructions

## Project Overview
**Tap&Collect** is a Flutter mobile loyalty app combining NFC hardware with QR code business activation. Customers tap NFC-enabled devices to earn points at registered merchants; merchants activate customers via unique QR codes. The app features a Dart Shelf backend running on Render with MongoDB persistence.

## Architecture & Key Patterns

### Service Layer (Single-responsibility pattern)
Services live in `lib/services/` as static-method classes with singleton state:
- **AuthService**: User authentication + session persistence (via StorageService)
- **BusinessActivationService**: QR-based merchant activation, manages `user.activatedBusinessIds`
- **PointsService**: Point balance tracking, transaction creation, backend sync
- **NFCService**: Hardware NFC polling with callbacks (uses `nfc_manager` package)
- **QRService**: QR scanning UI (uses `mobile_scanner` package)
- **ApiService**: HTTP REST calls to backend (base: `https://tap-collect.onrender.com`)
- **StorageService**: JSON serialization to SharedPreferences for local persistence

**Critical pattern**: Services persist data locally FIRST, then sync to backend fire-and-forget. Example in `PointsService.addPoints()`:
```dart
// 1. Update local balance immediately
await StorageService.savePointsBalanceForUser(user.id, newBalance);
// 2. Attempt async backend sync (don't block UI)
try { await ApiService.earnPoints(...); } catch (_) {}
```

### Model Serialization (toJson/fromJson)
All models in `lib/models/` implement `toJson()` and `fromJson()`:
- **User**: Parse ObjectId from backend (sanitize `"ObjectId(\"...\")"`), handle `activated_business_ids` list
- **Transaction**: Type enum (earn/redeem), timestamps as ISO8601 strings
- **Reward/Voucher**: Business-specific foreign keys

Handle type mismatches in fromJson: `(json['points_per_currency'] as num?)?.toDouble()`

### Data Flow for Point Collection
1. User scans NFC tag → `NFCService.startScanning()` detects tag
2. Calls `PointsService.addPoints(businessId, points, description)`
3. Creates Transaction record, updates local balance
4. Fire-and-forget: `ApiService.earnPoints()` syncs to MongoDB
5. UI updates via state (no reactive streams—use setState/refresh)

### App Initialization (main.dart)
```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.initialize();        // Load user from storage
  await MerchantAuthService.initialize();
  // Migrate any global points to user-specific storage (one-time)
  runApp(MyApp(...));
}
```

Storage persists user session across app restarts via SharedPreferences. No token-based auth; backend validates email only.

## Business Activation Flow (QR-based)

**Problem**: Customer must prove they're authorized at SPECIFIC business before NFC taps count.  
**Solution**: Scan unique business QR → `BusinessActivationService.activateBusiness(businessId)` adds ID to `user.activatedBusinessIds`.

Implementation in `business_activation_button.dart`:
1. `QRService.scanQRCode()` → shows modal scanner
2. `QRService.parseBusinessIdFromQR()` → extract ID from QR data (supports plain ID or `grove://merchant/{businessId}` format)
3. Call `BusinessActivationService.activateBusiness()` → updates user locally + backend
4. Check `BusinessActivationService.isBusinessActivated()` before accepting NFC points

## NFC Hardware Integration

**NFCService** (`lib/services/nfc_service.dart`) wraps `nfc_manager` v3.2.0:
- `initialize()` → detect NFC capability on startup
- `startScanning()` / `stopScanning()` → polling loop
- Type callbacks: `typedef OnNFCTagDetected = Function(NFCTagData tag)`
- Tag parsing: detects Type A/B/F, MIFARE
- 30-second timeout protection

NFC is **optional**—gracefully degrade if device lacks capability. See `NFCReaderScreen` for UI pattern: animated icon during scan → success/error state.

## Backend API Contracts

**Base URL**: `https://tap-collect.onrender.com` (local: `http://localhost:8080`)

Key endpoints:
- `POST /auth/register` → `{ name, email, password, avatar }`
- `POST /auth/login` → `{ email, password }` → returns full user JSON
- `PUT /users/{id}` → update user fields (e.g., `{ activated_business_ids: [...] }`)
- `POST /users/{id}/earn-points` → `{ amount, business_id }`
- `GET /businesses/{id}` → fetch business details
- `GET /businesses/{id}/rewards` → list available rewards

**Error handling**: All API calls return `null` on failure. Services handle gracefully (e.g., PointsService still updates local balance).

## Naming & Conventions

- **Files**: snake_case (e.g., `auth_service.dart`, `points_card.dart`)
- **Classes/Enums**: PascalCase (e.g., `AuthService`, `TransactionType.earn`)
- **Variables/Methods**: camelCase
- **Color constants**: `LightModeColors.lightPrimary` (green #2D5016), `DarkModeColors.darkSecondary` (brown #CD853F)
- **Assets**: `assets/images/` and `assets/icons/` with Material 3 icon set
- **Fonts**: Google Fonts Inter family via `theme.dart`

## State Management & Persistence

**No Redux/Provider/Riverpod**—use local state with `setState()`. Example:
```dart
class MyState extends State { ... }
// Rebuild widget:
setState(() { _points = newPoints; });
```

To trigger updates across app (e.g., after points earned), use:
- **Global key callback**: `nfcTapKey.currentState?.updatePoints()` (defined in main.dart)
- **Refresh home screen**: Navigator.pushReplacementNamed() to reload
- **SharedPreferences listener**: Wrap StorageService in StreamController (not yet implemented)

## Development Workflow

### Build & Run
```powershell
# Flutter setup
flutter clean
flutter pub get
flutter pub upgrade

# Development run (debug mode)
flutter run

# Build APK (Android release)
flutter build apk --release

# Build iOS
flutter build ios --release
```

### Testing
```powershell
flutter test                    # Run unit tests
flutter test --coverage         # Generate coverage report
dart analyze                    # Lint check
```

### Backend Development
```powershell
cd backend_my_api
docker compose up --build       # Runs server + MongoDB locally
dart run bin/server.dart        # Or direct Dart execution
```

## Common Tasks

**Add a new screen**:
1. Create `lib/screens/feature/feature_screen.dart` extending StatelessWidget/StatefulWidget
2. Use theme colors via `Theme.of(context).colorScheme.primary`
3. Add route in GoRouter config (if using navigation)

**Add a new service**:
1. Create `lib/services/new_service.dart` with static methods
2. Import in relevant screens/services
3. Call from main.dart if initialization needed

**Add a model**:
1. Create `lib/models/new_model.dart` with toJson/fromJson
2. Update ApiService with new endpoint if backend sync needed

**Debug NFC/QR**:
- Enable app logger via `AppLogger.info()` statements
- Use Android Studio logcat for real device logs
- Test QR with `QRService.scanQRCode()` in isolation

## Key Dependencies & Versions
- `flutter 3.6+`, `dart 3.6+`
- `nfc_manager 3.2.0` (hardware NFC)
- `mobile_scanner 7.1.3` (QR camera)
- `http 1.6.0` (REST)
- `shared_preferences 2.2.2` (session/config)
- `go_router 17.0.0` (navigation)

## Important Notes

- **No async/await for setState**: Services are async, but UI updates happen in sync callbacks
- **Offline resilience**: Point earning succeeds offline (local); background sync happens when online
- **Email normalization**: ApiService sanitizes input (titleCase for names, lowercase/trim for emails)
- **Business activation is per-user**: Each user maintains independent `activatedBusinessIds` list
- **NFC on iOS**: Requires entitlements; use `ios/Runner.xcworkspace` for builds
