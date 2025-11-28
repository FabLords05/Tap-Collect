import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRService {
  // Scan QR code and return the data
  static Future<String?> scanQRCode(BuildContext context) async {
    try {
      final MobileScannerController controller = MobileScannerController();
      String? scannedData;

      if (!context.mounted) return null;

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Scan Business QR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Scanner
              Expanded(
                child: MobileScanner(
                  controller: controller,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty) {
                      scannedData = barcodes.first.rawValue;
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
              // Instructions
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Position the QR code in the frame to scan',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );

      await controller.dispose();
      return scannedData;
    } catch (e) {
      debugPrint('QR Scan error: $e');
      return null;
    }
  }

  // Validate if QR data matches business ID format
  // Try to extract businessId from different QR payloads and validate
  static String? parseBusinessIdFromQR(String qrData) {
    try {
      final data = qrData.trim();
      // Support plain businessId or the merchant URL scheme: grove://merchant/<businessId>?...
      if (data.startsWith('grove://merchant/')) {
        final after = data.substring('grove://merchant/'.length);
        final parts = after.split(RegExp(r'[\?/#]'));
        if (parts.isNotEmpty) return parts.first;
        return null;
      }
      // If it's a URL with path containing merchant
      if (data.contains('/merchant/')) {
        final idx = data.indexOf('/merchant/');
        final after = data.substring(idx + '/merchant/'.length);
        final parts = after.split(RegExp(r'[\?/#]'));
        if (parts.isNotEmpty) return parts.first;
      }
      // Fallback: if qrData looks like an id (no spaces), return it
      if (!data.contains(' ')) return data;
    } catch (e) {
      debugPrint('parseBusinessIdFromQR error: $e');
    }
    return null;
  }

  static bool validateBusinessQRData(String qrData, String businessId) {
    final parsed = parseBusinessIdFromQR(qrData);
    if (parsed == null) return false;
    return parsed.trim() == businessId.trim();
  }

  // Scan a QR and return parsed business id (no activation here to avoid circular imports)
  static Future<String?> scanAndGetBusinessId(BuildContext context) async {
    final scanned = await scanQRCode(context);
    if (scanned == null) return null;
    final parsedId = parseBusinessIdFromQR(scanned);
    return parsedId;
  }
}
