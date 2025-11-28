# QR Activation Feature - Visual Diagrams & Flowcharts

## 1. Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         FLUTTER APP                              │
│                                                                   │
│  ┌────────────────────────────────────────────────────────┐    │
│  │           DashboardScreen (Customer View)              │    │
│  │                                                         │    │
│  │  1. Load currentBusinessId (e.g., "shop_123")         │    │
│  │  2. Check: isBusinessActivated(currentBusinessId)?    │    │
│  └────────────────────┬────────────────────────────────┬─┘    │
│                       │                                 │        │
│         YES (Activated)│                       NO (Not Activated)
│                       │                                 │        │
│                       ▼                                 ▼        │
│          ┌──────────────────────┐      ┌──────────────────────┐ │
│          │  NFCCollectionWidget │      │ BusinessActivation   │ │
│          │  (Tap for Points)    │      │ Button (Scan QR)     │ │
│          └──────────────────────┘      └──────────┬───────────┘ │
│                                                   │                │
│                                                   ▼                │
│                                    ┌──────────────────────────┐   │
│                                    │   QRService              │   │
│                                    │ .scanQRCode()            │   │
│                                    │                          │   │
│                                    │ Opens mobile_scanner     │   │
│                                    │ in bottom sheet          │   │
│                                    └──────────┬───────────────┘   │
│                                               │                    │
│                                    Gets QR data (e.g.              │
│                                    "shop_123")                     │
│                                               │                    │
│                                               ▼                    │
│                                    ┌──────────────────────────┐   │
│                                    │ QRService                │   │
│                                    │ .validateBusinessQRData()│   │
│                                    │                          │   │
│                                    │ QRData == businessId?    │   │
│                                    └──────────┬──────┬────────┘   │
│                                               │      │             │
│                                    YES(Valid) │      │ NO(Invalid) │
│                                               │      │             │
│                                               ▼      ▼             │
│                                    ┌──────────────┐  Show Error   │
│                                    │ Business     │  Message &    │
│                                    │ Activation   │  Retry        │
│                                    │ Service      │               │
│                                    │ .activate()  │               │
│                                    └──────┬───────┘               │
│                                           │                        │
│                                           ▼                        │
│                                    ┌──────────────────────────┐   │
│                                    │ AuthService              │   │
│                                    │ .updateCurrentUser()     │   │
│                                    │                          │   │
│                                    │ Add businessId to        │   │
│                                    │ activatedBusinessIds     │   │
│                                    │                          │   │
│                                    │ Save to local storage    │   │
│                                    └──────────┬───────────────┘   │
│                                               │                    │
│                                               ▼                    │
│                                    ┌──────────────────────────┐   │
│                                    │ Callback fired:          │   │
│                                    │ onActivationComplete()   │   │
│                                    │                          │   │
│                                    │ setState() updates UI    │   │
│                                    │ NFCCollectionWidget now  │   │
│                                    │ visible                  │   │
│                                    └──────────────────────────┘   │
│                                                                     │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. State Machine Diagram

```
                          ┌─────────────────────┐
                          │   App Starts        │
                          │   (First Visit)     │
                          └──────────┬──────────┘
                                     │
                                     ▼
                    ┌────────────────────────────────┐
                    │  Load User Data                │
                    │  activatedBusinessIds = []     │
                    └──────────┬─────────────────────┘
                               │
                               ▼
                    ┌────────────────────────────────┐
                    │ Navigate to Business A         │
                    │ _currentBusinessId = "A"       │
                    └──────────┬─────────────────────┘
                               │
                               ▼
         ┌─────────────────────────────────────────┐
         │    CHECK: isBusinessActivated("A")?     │
         └──────────┬──────────────────────────────┘
                    │
         ┌──────────┴──────────┐
         │                     │
       NO                     YES
         │                     │
         ▼                     ▼
  ┌────────────────┐  ┌──────────────────┐
  │ SHOW QR BUTTON │  │ SHOW NFC BUTTON  │
  └────────┬───────┘  └──────────┬───────┘
           │                     │
           ▼                     ▼
    ┌──────────────┐      ┌──────────────────┐
    │ WAITING FOR  │      │ User taps NFC    │
    │ QR SCAN      │      │ Collect points!  │
    └────────┬─────┘      └──────────────────┘
             │
             ▼
  ┌────────────────────┐
  │ User scans QR      │
  └────────┬───────────┘
           │
      ┌────┴─────┐
      │           │
    VALID     INVALID
      │           │
      ▼           ▼
  ┌────────┐  ┌─────────────────┐
  │ACTIVATE│  │ Show Error:     │
  │ "A"    │  │ Wrong QR code   │
  └────┬───┘  │ Try again       │
       │       └────────┬────────┘
       │                │
       ▼                ▼
  ┌──────────────────────┐
  │ Update User:         │
  │ activatedBusinessIds │
  │ += ["A"]             │
  └────────┬─────────────┘
           │
           ▼
  ┌──────────────────────┐
  │ Save to storage      │
  │ Show success snack   │
  └────────┬─────────────┘
           │
           ▼
  ┌──────────────────────┐
  │ setState() triggers  │
  │ Refresh UI           │
  └────────┬─────────────┘
           │
           ▼
  ┌──────────────────────┐
  │ SHOW NFC BUTTON      │
  │ (Business "A"        │
  │  activated)          │
  └──────────────────────┘


┌─────────────────────────────────────────────────────────────┐
│ VISIT TO DIFFERENT BUSINESS (Business B)                    │
│                                                               │
│  Navigate to Business B                                      │
│  _currentBusinessId = "B"                                    │
│  │                                                            │
│  ▼                                                            │
│  CHECK: isBusinessActivated("B")?                            │
│  activatedBusinessIds = ["A"]  → "B" not in list             │
│  Result: NO                                                  │
│  │                                                            │
│  ▼                                                            │
│  SHOW QR BUTTON (repeat activation for Business B)           │
│                                                               │
│  After activation:                                           │
│  activatedBusinessIds = ["A", "B"]                           │
│  Can use NFC at BOTH businesses!                             │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Component Interaction Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                     DashboardScreen                               │
│  (knows _currentBusinessId and _isBusinessActivated)             │
└────────────────────┬─────────────────────────────────────────────┘
                     │
        ┌────────────┼────────────┐
        │            │            │
        ▼            ▼            ▼
    ┌─────────┐ ┌─────────┐ ┌──────────────────┐
    │ PointsCard  │NFCCollection │BusinessActivationButton
    │(displays    │Widget        │(handles activation)
    │points       │(shows button)│
    │balance)     └─────────┘    └────────┬─────────────────┘
    └─────────┘                           │
                                          │
                        ┌─────────────────┼─────────────────┐
                        │                 │                 │
                        ▼                 ▼                 ▼
                   ┌─────────┐     ┌────────────┐    ┌──────────────┐
                   │ QRService   │BusinessAct │    │AuthService   │
                   │            │Service     │    │              │
                   │            │            │    │              │
                   │.scanQR()   │.activate() │    │.updateCurrent│
                   │.validate() │.isActive() │    │User()        │
                   │            │            │    │              │
                   └─────┬──────┘    ┬───────┘    └──────┬───────┘
                         │           │                   │
                         │           ▼                   │
                         │    ┌─────────────────┐       │
                         │    │ User Model      │       │
                         │    │ (updated)       │       │
                         │    │                 │       │
                         │    │activated        │◄──────┘
                         │    │BusinessIds[]    │
                         │    └────────┬────────┘
                         │             │
                         └─────────────┼──────────────┐
                                       │              │
                                       ▼              ▼
                            ┌──────────────────┐ ┌──────────────┐
                            │ StorageService   │ │ User displays
                            │ (persist via     │ │ success message
                            │ SharedPrefs)     │ │ NFC button now
                            └──────────────────┘ │ visible
                                                 └──────────────┘
```

---

## 4. Sequence Diagram - Happy Path

```
User                Button              Services            Storage
  │                  │                   │                   │
  ├─ Tap Scan ──────→│                   │                   │
  │                  │                   │                   │
  │                  ├─ scanQRCode() ──→ QRService          │
  │                  │                   │                   │
  │                  │                   │ Opens Scanner     │
  │                  │◄─ User Position QR Code              │
  │                  │                   │                   │
  │◄─ Point QR Code ─┤                   │                   │
  │                  │ Detect QR Data    │                   │
  │                  │◄─────────────────┤                   │
  │                  │                   │                   │
  │                  ├─ validateQRData()─→ QRService        │
  │                  │   (matches biz ID?)                  │
  │                  │◄───────────────────┤                   │
  │                  │                   │                   │
  │                  ├─ activateBusiness() → BusinessActService
  │                  │                   │                   │
  │                  │                   ├─ updateCurrentUser()
  │                  │                   │───────────────────→│
  │                  │                   │                   │
  │                  │                   │   Save to Storage │
  │                  │                   │◄───────────────────┤
  │                  │◄────────────────────────────────────┤
  │                  │                   │                   │
  │                  ├─ setState()        │                   │
  │                  │                   │                   │
  │◄─ Success! ──────│                   │                   │
  │   NFC Enabled    │                   │                   │
  │                  │                   │                   │
```

---

## 5. Database/Storage Schema

```
┌─────────────────────────────────────────────────────────────────┐
│ Local Storage (SharedPreferences)                                │
│ Key: "user_data"                                                │
│                                                                  │
│ {                                                               │
│   "id": "user_xyz789",                                          │
│   "email": "customer@example.com",                              │
│   "name": "John Doe",                                           │
│   "avatar": "https://...",                                      │
│   "activated_business_ids": [                                   │
│     "coffee_shop_downtown",    ◄─── Business A (Activated)    │
│     "cafe_plaza_mall",         ◄─── Business B (Activated)    │
│     "restaurant_uptown"        ◄─── Business C (Activated)    │
│   ],                           ◄─── NEW FIELD                  │
│   "created_at": "2025-11-14T10:00:00Z",                         │
│   "updated_at": "2025-11-14T15:30:00Z"                          │
│ }                                                               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

When visiting:
- Business A: activated_business_ids contains "coffee_shop_downtown" ✓
- Business B: activated_business_ids contains "cafe_plaza_mall" ✓
- Business D: activated_business_ids DOES NOT contain "burger_joint" ✗
  → Show QR activation button
```

---

## 6. File Structure Tree

```
lib/
├── models/
│   ├── user.dart                          ✅ UPDATED
│   │   └── List<String> activatedBusinessIds (NEW)
│   ├── business.dart
│   ├── reward.dart
│   └── ...
│
├── services/
│   ├── auth_service.dart                  ✅ UPDATED
│   │   └── updateCurrentUser() method (NEW)
│   │
│   ├── qr_service.dart                    ✅ NEW
│   │   ├── scanQRCode()
│   │   └── validateBusinessQRData()
│   │
│   ├── business_activation_service.dart   ✅ NEW
│   │   ├── activateBusiness()
│   │   ├── isBusinessActivated()
│   │   ├── getActivatedBusinesses()
│   │   └── deactivateBusiness()
│   │
│   ├── nfc_service.dart
│   ├── points_service.dart
│   └── ...
│
├── screens/
│   └── home/
│       ├── dashboard_screen.dart          ✅ UPDATED
│       │   └── Conditional UI (QR vs NFC)
│       ├── home_screen.dart
│       └── ...
│
├── widgets/
│   ├── business_activation_button.dart    ✅ NEW
│   │   └── Complete activation flow UI
│   ├── nfc_collection_widget.dart
│   ├── points_card.dart
│   └── ...
│
└── main.dart
    └── Entry point

pubspec.yaml                                ✅ UPDATED
└── Added mobile_scanner: ^5.0.0

Documentation/
├── QR_ACTIVATION_SUMMARY.md               ✅ NEW
├── QR_ACTIVATION_IMPLEMENTATION.md        ✅ NEW
├── QR_ACTIVATION_EXAMPLES.md              ✅ NEW
└── (this file - diagrams)                 ✅ NEW
```

---

## 7. State Transition Matrix

| Current State | Event | Action | New State | UI Result |
|---|---|---|---|---|
| NOT_ACTIVATED | App Load | Check isBusinessActivated() | NOT_ACTIVATED | Show QR Button |
| NOT_ACTIVATED | Scan Valid QR | activateBusiness() | ACTIVATED | Show Success + NFC |
| NOT_ACTIVATED | Scan Invalid QR | Show Error | NOT_ACTIVATED | Show Error + QR Button |
| NOT_ACTIVATED | Scan Timeout | Dismiss Scanner | NOT_ACTIVATED | Show QR Button |
| ACTIVATED | App Load | Check isBusinessActivated() | ACTIVATED | Show NFC Button |
| ACTIVATED | Visit Different Biz | Check isBusinessActivated() | NOT_ACTIVATED (for new biz) | Show QR Button |
| ACTIVATED | Deactivate | Remove from list | NOT_ACTIVATED | Show QR Button |

---

## 8. Error Handling Flow

```
                    ┌──────────────┐
                    │ Scan QR Code │
                    └──────┬───────┘
                           │
           ┌───────────────┼───────────────┐
           │               │               │
           ▼               ▼               ▼
      ┌────────┐    ┌────────────┐    ┌────────────┐
      │ NULL   │    │ MISMATCH   │    │ TIMEOUT    │
      │ (User  │    │ (Wrong QR) │    │ (30 sec)   │
      │Canceled)    └──────┬─────┘    └──────┬─────┘
      └────┬───┘            │                │
           │         ┌───────────────────────┘
           │         │
           ▼         ▼
    ┌──────────────────────────────┐
    │ Show SnackBar Error Message  │
    │ (Context-specific)           │
    │                              │
    │ Examples:                    │
    │ • "QR code doesn't match"   │
    │ • "Scanner timeout"          │
    │ • "Scan cancelled"           │
    └────────┬─────────────────────┘
             │
             ▼
    ┌──────────────────────────────┐
    │ Keep "Scan QR" Button Visible│
    │ User can retry immediately   │
    └──────────────────────────────┘
```

---

## 9. Multi-Business Activation Scenario

```
User Account: john@example.com
╔════════════════════════════════════════════════════════════╗
║ activatedBusinessIds: []                                    ║  ← Start
╚════════════════════════════════════════════════════════════╝

Day 1: Visit Coffee Shop A
  Scan QR → "coffee_a"
╔════════════════════════════════════════════════════════════╗
║ activatedBusinessIds: ["coffee_a"]                          ║
╚════════════════════════════════════════════════════════════╝

Day 2: Visit Coffee Shop A Again
  Check: "coffee_a" in activatedBusinessIds? YES
  → Show NFC button immediately ✓

Day 2: Visit Pizza Restaurant B
  Scan QR → "pizza_b"
╔════════════════════════════════════════════════════════════╗
║ activatedBusinessIds: ["coffee_a", "pizza_b"]              ║
╚════════════════════════════════════════════════════════════╝

Day 3: Visit Bakery C
  Scan QR → "bakery_c"
╔════════════════════════════════════════════════════════════╗
║ activatedBusinessIds: ["coffee_a", "pizza_b", "bakery_c"]  ║
╚════════════════════════════════════════════════════════════╝

Day 10: Visit Coffee Shop A Again
  Check: "coffee_a" in activatedBusinessIds? YES
  → Show NFC button immediately ✓
  (Never needs to scan QR again)
```

---

## 10. Integration Points

```
┌──────────────────────────────────────────────────────────────┐
│                   EXTERNAL SYSTEMS                            │
│                                                                │
│  ┌─────────────┐  ┌────────────┐  ┌──────────────────┐      │
│  │  Backend    │  │  Firebase  │  │  Device Camera   │      │
│  │  API        │  │  Analytics │  │  (QR Scanning)   │      │
│  │  /users/:id │  │  (optional)│  │                  │      │
│  └──────┬──────┘  └──────┬─────┘  └────────┬─────────┘      │
│         │                │                 │                 │
│         │                │                 │                 │
└─────────┼────────────────┼─────────────────┼─────────────────┘
          │                │                 │
          ▼                ▼                 ▼
     ┌─────────────────────────────────────────────────────┐
     │            FLUTTER APP LAYER                         │
     │                                                       │
     │  BusinessActivationService                           │
     │  ├─ (Optional) API call on activation               │
     │  └─ Local state management                          │
     │                                                       │
     │  QRService                                           │
     │  └─ Uses device camera via mobile_scanner           │
     │                                                       │
     │  AuthService                                         │
     │  └─ Persists to local storage                       │
     │                                                       │
     │  DashboardScreen                                     │
     │  └─ Orchestrates UI updates                         │
     │                                                       │
     │  BusinessActivationButton                            │
     │  └─ Reusable UI component                           │
     │                                                       │
     └─────────────────────────────────────────────────────┘
          │
          ▼
     ┌──────────────────────────────────┐
     │   LOCAL STORAGE                  │
     │   (SharedPreferences)            │
     │                                  │
     │   Persists:                      │
     │   • activatedBusinessIds         │
     │   • User profile data            │
     │   • Points balance               │
     └──────────────────────────────────┘
```

---

**Visual diagrams created to help understand the complete feature implementation and data flow!**
