import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:grove_rewards/screens/merchant/merchant_point_entry_screen.dart';

class MerchantScanScreen extends StatefulWidget {
  const MerchantScanScreen({super.key});

  @override
  State<MerchantScanScreen> createState() => _MerchantScanScreenState();
}

class _MerchantScanScreenState extends State<MerchantScanScreen> {
  final MobileScannerController _cameraController = MobileScannerController();
  
  bool _isScanning = false;
  bool _isNfcListening = false;
  bool _hasFoundUser = false;

  @override
  void initState() {
    super.initState();
    _initializeScanners();
  }

  @override
  void dispose() {
    _cameraController.dispose(); // void, do not await
    NfcManager.instance.stopSession(); // Future, but fine to fire-and-forget here
    super.dispose();
  }

  Future<void> _initializeScanners() async {
    await _startCamera();
    await _startNfc();
  }

  // --- QR CAMERA LOGIC ---
  Future<void> _startCamera() async {
    final status = await Permission.camera.request();
    
    if (status.isGranted) {
      try {
        await _cameraController.start();
        if (mounted) {
          setState(() => _isScanning = true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Camera error: $e')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission denied')),
        );
      }
    }
  }

  void _onQrDetected(BarcodeCapture capture) {
    if (_hasFoundUser) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        _handleUserFound(barcode.rawValue!);
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

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        if (_hasFoundUser) return;
        
        // Simple simulation: if any tag is found, use a placeholder ID
        // In production, read NDEF payload here
        // String userId = "EXTRACTED_ID";
        // _handleUserFound(userId);
      },
    );
  }

  // --- SUCCESS HANDLER ---
  // FIX: Marked as Future<void> just in case, though void is fine if not awaited
  Future<void> _handleUserFound(String userId) async {
    if (_hasFoundUser) return;

    setState(() {
      _hasFoundUser = true;
      _isScanning = false;
    });

    // Stop hardware
    try {
      await _cameraController.stop();
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
          if (_isScanning)
            MobileScanner(
              controller: _cameraController,
              onDetect: _onQrDetected,
            )
          else
            const Center(child: Text("Initializing Camera...")),

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