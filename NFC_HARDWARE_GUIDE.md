// Usage Guide: Responsive NFC Reader with Hardware Support

/*
FEATURES:
1. Real hardware NFC tag reading using nfc_manager v4.0.0
2. Fully responsive UI that adapts to screen size
3. Real-time NFC session management
4. Error handling and user feedback
5. Tag type detection (Type A, Type B, Type F, MIFARE, etc.)
6. Graceful fallback for devices without NFC

QUICK START:
*/

// 1. Initialize NFC on app startup (in main.dart or startup screen)
import 'package:grove_rewards/services/nfc_service.dart';

@override
void initState() {
  super.initState();
  _initNFC();
}

Future<void> _initNFC() async {
  bool available = await NFCService.initialize();
  if (available) {
    print('NFC is available on this device');
  }
}

// 2. Open the NFC reader screen from your dashboard
import 'package:grove_rewards/screens/nfc_reader_screen.dart';

ElevatedButton(
  onPressed: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NFCReaderScreen(
          businessId: 'sample-cafe-001',
          businessName: 'Grove Café',
        ),
      ),
    );
  },
  child: const Text('Read NFC Tag'),
);

// 3. The NFCReaderScreen handles everything:
//    - Checks NFC availability
//    - Shows responsive UI based on device size
//    - Initiates scanning session
//    - Displays detected tags
//    - Handles errors gracefully

/*
NFC SERVICE METHODS:

1. Initialize:
   bool available = await NFCService.initialize();
   
2. Check availability:
   bool available = NFCService.isAvailable;
   
3. Check if scanning:
   bool scanning = NFCService.isScanning;
   
4. Read single tag:
   NFCTagData? tag = await NFCService.readNFCTag();
   
5. Start continuous session:
   NFCService.startNFCSession(
     (NFCTagData tag) {
       print('Tag detected: ${tag.content}');
     },
     (String error) {
       print('Error: $error');
     },
   );
   
6. Stop session:
   await NFCService.stopNFCSession();

NFCTagData STRUCTURE:
{
  id: String,           // Unique tag identifier
  content: String,      // Tag content/data
  type: String,         // 'Read-Only' or 'Read-Write'
  tagType: String       // 'Type A', 'Type B', 'MIFARE', etc.
}

HARDWARE COMPATIBILITY:
✅ iOS: Supported (requires iOS 13+)
✅ Android: Supported (requires NFC hardware + Android 4.1+)
⚠️  Web: Not supported (NFC Manager limitation)

PERMISSIONS REQUIRED:
Android (AndroidManifest.xml):
  <uses-permission android:name="android.permission.NFC" />
  <uses-feature android:name="android.hardware.nfc" android:required="false" />

iOS (Info.plist):
  <key>NFCReaderUsageDescription</key>
  <string>We need NFC access to collect loyalty points</string>

RESPONSIVE DESIGN:
- Auto-detects screen size
- Adapts spacing and icon sizes
- Touch-friendly buttons (min 48x48dp)
- Clear visual feedback during scanning
- Success/error animations

POINTS INTEGRATION:
To collect points on NFC tag read:
   NFCService.startNFCSession(
     (NFCTagData tag) async {
       final result = await PointsService.addPoints(
         points: 25,
         businessId: 'sample-cafe-001',
         description: 'NFC Tag Tap - ${tag.tagType}',
       );
     },
     (String error) => showErrorSnackbar(error),
   );

TROUBLESHOOTING:
1. Device not detecting tags:
   - Ensure NFC is enabled in device settings
   - Check permissions are granted
   - Hold device within 5-10cm of tag

2. Tag not reading content:
   - Some tags may be write-protected
   - Check tag format (NDEF required for content)
   - Try alternative tag or verify tag isn't corrupted

3. Performance issues:
   - Limit concurrent NFC sessions
   - Call stopNFCSession() when not needed
   - Dispose service in widget dispose()

4. iOS specific:
   - NFC requires physical device (simulator not supported)
   - May need to rebuild app after permission changes
   - Reader mode works best with Type 4A/4B tags
