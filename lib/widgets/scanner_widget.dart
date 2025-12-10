import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:grove_rewards/services/app_logger.dart';

/// A self-contained scanner widget that manages its own
/// MobileScannerController lifecycle and forwards detected barcodes
/// through [onDetect]. It automatically requests camera permission
/// and starts the camera after the widget is mounted.
class ScannerWidget extends StatefulWidget {
  final void Function(BarcodeCapture) onDetect;
  final BoxFit fit;

  const ScannerWidget({super.key, required this.onDetect, this.fit = BoxFit.cover});

  @override
  State<ScannerWidget> createState() => _ScannerWidgetState();
}

class _ScannerWidgetState extends State<ScannerWidget> {
  late final MobileScannerController _controller;
  bool _isInitialized = false;
  bool _isStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    try {
      // Request camera permission (except on web)
      if (!kIsWeb) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          AppLogger.warning('Camera permission denied by user');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Camera permission denied')),
            );
          }
          return;
        }
      }
      
      // Permission granted, mark ready to build MobileScanner
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e, st) {
      AppLogger.error('Permission request error', e, st);
    }
  }

  Future<void> _startScanner() async {
    if (_isStarted) return; // Prevent multiple start calls
    
    try {
      _isStarted = true;
      // Now that MobileScanner widget is built, start the controller
      await _controller.start();
      AppLogger.info('MobileScanner started successfully');
    } catch (e, st) {
      _isStarted = false;
      AppLogger.error('Scanner start error', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    try {
      _controller.dispose();
    } catch (e) {
      AppLogger.warning('Error disposing scanner controller: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Requesting camera permission...'),
          ],
        ),
      );
    }

    // Schedule start after MobileScanner is built (only once)
    if (!_isStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startScanner();
      });
    }

    return MobileScanner(
      controller: _controller,
      onDetect: widget.onDetect,
      fit: widget.fit,
    );
  }
}
