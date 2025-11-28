import 'package:flutter/material.dart';
import 'package:grove_rewards/services/business_activation_service.dart';
import 'package:grove_rewards/services/qr_service.dart';
import 'package:grove_rewards/services/business_service.dart';

class BusinessActivationButton extends StatefulWidget {
  final String businessId;
  final String businessName;
  final VoidCallback onActivationComplete;

  const BusinessActivationButton({
    super.key,
    required this.businessId,
    required this.businessName,
    required this.onActivationComplete,
  });

  @override
  State<BusinessActivationButton> createState() =>
      _BusinessActivationButtonState();
}

class _BusinessActivationButtonState extends State<BusinessActivationButton> {
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleQRScan() async {
    setState(() => _isScanning = true);

    try {
      // Scan and parse business id from QR
      final parsedId = await QRService.scanAndGetBusinessId(context);

      if (!mounted) return;

      if (parsedId == null) {
        // User cancelled or invalid QR
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No valid business QR detected.'),
            duration: Duration(seconds: 2),
          ),
        );
        setState(() => _isScanning = false);
        return;
      }

      // Activate the scanned business automatically
      final success =
          await BusinessActivationService.activateBusiness(parsedId);

      if (!mounted) return;

      if (success) {
        // Try to resolve business name for friendlier messaging
        final business = await BusinessService.getBusinessById(parsedId);
        final name = business?.name ?? parsedId;

        setState(() {
          _isScanning = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ $name activated! You can now use NFC tap.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        widget.onActivationComplete();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to activate business. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isScanning = false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isScanning ? null : _handleQRScan,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          disabledBackgroundColor:
              theme.colorScheme.primary.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isScanning
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Scanning...'),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_2),
                  const SizedBox(width: 8),
                  const Text('Scan QR to Activate'),
                ],
              ),
      ),
    );
  }
}
