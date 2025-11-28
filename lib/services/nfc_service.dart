import 'dart:async';
import 'package:grove_rewards/services/points_service.dart';
import 'package:nfc_manager/nfc_manager.dart';

/// Callback type for NFC tag detection
typedef OnNFCTagDetected = Function(NFCTagData tag);

/// Callback type for NFC errors
typedef OnNFCError = Function(String error);

class NFCService {
  static bool _isScanning = false;
  static bool _isAvailable = false;

  // Initialize NFC service - must be called on app startup
  static Future<bool> initialize() async {
    try {
      _isAvailable = await NfcManager.instance.isAvailable();
      return _isAvailable;
    } catch (e) {
      _isAvailable = false;
      return false;
    }
  }

  // Check if NFC is available on device
  static bool get isAvailable => _isAvailable;

  // Check if currently scanning
  static bool get isScanning => _isScanning;

  // Start NFC scanning for point collection
  static Future<NFCResult> startScanning() async {
    if (!_isAvailable) {
      return NFCResult(
        success: false,
        message: 'NFC is not available on this device',
      );
    }

    if (_isScanning) {
      return NFCResult(
        success: false,
        message: 'NFC scanning is already in progress',
      );
    }

    try {
      _isScanning = true;
      return NFCResult(
        success: true,
        message: 'NFC scanning started successfully',
      );
    } catch (e) {
      _isScanning = false;
      return NFCResult(
        success: false,
        message: 'Failed to start NFC scanning: ${e.toString()}',
      );
    }
  } // Stop NFC scanning

  static Future<void> stopScanning() async {
    _isScanning = false;
  }

  // Simulate NFC collection for testing without hardware
  static Future<NFCResult> simulateNFCCollection() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      const businessId = 'sample-cafe-001';
      final pointsEarned = 10 + (DateTime.now().millisecond % 41);

      final pointsCollected = await PointsService.addPoints(
        points: pointsEarned,
        businessId: businessId,
        description: 'NFC Tap Collection (Simulated)',
      );

      if (pointsCollected) {
        return NFCResult(
          success: true,
          message: 'Points collected successfully!',
          businessId: businessId,
          pointsEarned: pointsEarned,
        );
      } else {
        return NFCResult(
          success: false,
          message: 'Failed to collect points',
        );
      }
    } catch (e) {
      return NFCResult(
        success: false,
        message: 'Error during NFC simulation: ${e.toString()}',
      );
    }
  }

  // Read NFC tag from actual hardware
  static Future<NFCTagData?> readNFCTag() async {
    try {
      bool isAvailable = await NfcManager.instance.isAvailable();
      if (!isAvailable) {
        return null;
      }

      NFCTagData? tagData;
      Completer<NFCTagData?> completer = Completer();

      await NfcManager.instance.startSession(
        pollingOptions: {},
        onDiscovered: (NfcTag tag) async {
          try {
            tagData = _parseNFCTag(tag);
            if (tagData != null && !completer.isCompleted) {
              completer.complete(tagData);
            }
            await NfcManager.instance.stopSession();
          } catch (e) {
            if (!completer.isCompleted) {
              completer.complete(null);
            }
            await NfcManager.instance.stopSession();
          }
        },
      );

      // Timeout after 30 seconds
      return await completer.future
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => null,
          )
          .catchError((_) => null);
    } catch (e) {
      return null;
    }
  } // Listen to NFC tags in real-time from actual hardware

  static Future<void> startNFCSession(
    OnNFCTagDetected onTagDetected,
    OnNFCError onError,
  ) async {
    try {
      bool isAvailable = await NfcManager.instance.isAvailable();
      if (!isAvailable) {
        onError('NFC is not available on this device');
        return;
      }

      _isScanning = true;

      await NfcManager.instance.startSession(
        pollingOptions: {},
        onDiscovered: (NfcTag tag) async {
          try {
            final tagData = _parseNFCTag(tag);
            onTagDetected(tagData);
            await NfcManager.instance.stopSession();
          } catch (e) {
            onError('Error reading tag: $e');
            await NfcManager.instance.stopSession();
          }
        },
      );
    } catch (e) {
      _isScanning = false;
      onError('NFC session error: $e');
    }
  }

  // Stop NFC session
  static Future<void> stopNFCSession() async {
    try {
      _isScanning = false;
      await NfcManager.instance.stopSession();
    } catch (_) {}
  }

  // Dispose resources
  static Future<void> dispose() async {
    await stopScanning();
    await stopNFCSession();
  }

  // Parse NFC tag data from hardware
  static NFCTagData _parseNFCTag(NfcTag tag) {
    String id = tag.hashCode.toString();
    String content = 'NFC Tag Detected';
    String type = 'Standard';
    String tagType = 'NFC Tag';

    try {
      // nfc_manager v4.0.0 simplified API
      // Extract whatever information is available from the tag
      final tagString = tag.toString();

      // Try to identify common tag types
      if (tagString.contains('Type A') || tagString.contains('ISO14443A')) {
        tagType = 'Type A (ISO14443A)';
      } else if (tagString.contains('Type B') ||
          tagString.contains('ISO14443B')) {
        tagType = 'Type B (ISO14443B)';
      } else if (tagString.contains('Type F') || tagString.contains('FeliCa')) {
        tagType = 'Type F (FeliCa)';
      } else if (tagString.contains('MIFARE')) {
        tagType = 'MIFARE Tag';
      } else if (tagString.contains('NDEF')) {
        tagType = 'NDEF Tag';
        type = 'Read-Write';
      }

      // Create a simple ID from hash
      id = 'TAG-${tag.hashCode.abs().toString().substring(0, 8)}';
      content = 'Successfully scanned $tagType';
    } catch (e) {
      content = 'Error parsing tag: $e';
    }

    return NFCTagData(
      id: id,
      content: content,
      type: type,
      tagType: tagType,
    );
  }
}

// Result class for NFC operations
class NFCResult {
  final bool success;
  final String message;
  final String? businessId;
  final int? pointsEarned;

  const NFCResult({
    required this.success,
    required this.message,
    this.businessId,
    this.pointsEarned,
  });

  @override
  String toString() {
    return 'NFCResult(success: $success, message: $message, businessId: $businessId, pointsEarned: $pointsEarned)';
  }
}

// NFC Tag Data class
class NFCTagData {
  final String id;
  final String content;
  final String type;
  final String tagType;

  NFCTagData({
    required this.id,
    required this.content,
    required this.type,
    required this.tagType,
  });

  @override
  String toString() {
    return 'NFCTagData(id: $id, content: $content, type: $type, tagType: $tagType)';
  }
}
