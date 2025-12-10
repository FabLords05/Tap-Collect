import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:grove_rewards/widgets/scanner_widget.dart';
import 'package:grove_rewards/screens/merchant/merchant_point_entry_screen.dart';

class MerchantScanScreen extends StatefulWidget {
  const MerchantScanScreen({super.key});

  @override
  State<MerchantScanScreen> createState() => _MerchantScanScreenState();
}

class _MerchantScanScreenState extends State<MerchantScanScreen> {
  bool _isNfcListening = false;
  bool _hasFoundUser = false;

  @override
  void initState() {
    super.initState();
    _startNfc(); // Start NFC immediately, camera handled by ScannerWidget
  }

  @override
  void dispose() {
    // ScannerWidget disposes its controller automatically.
    NfcManager.instance.stopSession(); // Future, but fine to fire-and-forget here
    super.dispose();
  }

  Future<void> _initializeScanners() async {
    // Camera is handled by dedicated ScannerWidget. We just enable scanning UI.
    await _startNfc();
  }
  // Camera logic is implemented inside `ScannerWidget`.

  void _onQrDetected(BarcodeCapture capture) {
    if (_hasFoundUser) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final value = barcode.rawValue ?? barcode.displayValue;
      debugPrint('QR detected value: $value, format: ${barcode.format}');
      if (value != null && value.isNotEmpty) {
        _handleUserFound(value);
        break;
      }
    }
  }

  // --- NFC LOGIC ---
  Future<void> _startNfc() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) return;

    if (mounted) {
      setState(() => _isNfcListening = true);
    }

    try {
      NfcManager.instance.startSession(
       pollingOptions: {},
         onDiscovered: (NfcTag tag) async {
           if (_hasFoundUser) return;
           
           // Extract userId from tag (NDEF or ID)
           try {
             final ndef = Ndef.from(tag);
             if (ndef != null && ndef.cachedMessage != null) {
               for (final record in ndef.cachedMessage!.records) {
                 final payload = String.fromCharCodes(record.payload);
                 if (payload.isNotEmpty) {
                   _handleUserFound(payload);
                   return;
                 }
               }
             }
           } catch (_) {}
           
           // Fallback: use tag ID as userId
           final tagId = tag.data['id'];
           if (tagId != null && tagId is List) {
             final hex = tagId.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
             if (hex.isNotEmpty) {
               _handleUserFound(hex);
             }
           }
         },
       );
    } catch (e) {
      print('NFC start error: $e');
      if (mounted) {
        setState(() => _isNfcListening = false);
      }
    }
  }

  // --- SUCCESS HANDLER ---
  // FIX: Marked as Future<void> just in case, though void is fine if not awaited
  Future<void> _handleUserFound(String userId) async {
    if (_hasFoundUser) return;

    setState(() {
      _hasFoundUser = true;
    });

    // Stop hardware
    try {
      await NfcManager.instance.stopSession();
    } catch (e) {
      print("Error stopping scanners: $e");
    }

    if (!mounted) return;

    // Navigate
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MerchantPointEntryScreen(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Customer")),
      body: Stack(
        children: [
          // ScannerWidget handles its own initialization with FutureBuilder
          ScannerWidget(
            onDetect: _onQrDetected,
          ),

          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.qr_code, color: Colors.white54, size: 48),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Scan Customer QR",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Align QR code within the frame",
                        style: TextStyle(color: Colors.grey),
                      ),
                      if (_isNfcListening) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.nfc, color: Colors.blue),
                              SizedBox(width: 12),
                              Text("Or TAP phone", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}