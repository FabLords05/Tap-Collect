import 'package:flutter/material.dart';
import 'package:grove_rewards/services/qr_service.dart';
import 'package:grove_rewards/services/api_service.dart';
import 'package:grove_rewards/services/auth_service.dart';

class QRCollectionWidget extends StatelessWidget {
  final Function(int points)? onPointsCollected;
  final String businessId;

  const QRCollectionWidget({
    super.key,
    required this.businessId,
    this.onPointsCollected,
  });

  Future<void> _handleQRCollect(BuildContext context) async {
    final scanned = await QRService.scanQRCode(context);
    if (scanned == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No QR code detected.')),
      );
      return;
    }
    // Validate QR matches business
    if (!QRService.validateBusinessQRData(scanned, businessId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid QR code for this business.')),
      );
      return;
    }
    // Award points (simulate, or call API)
    final user = AuthService.currentUser;
    if (user == null) return;
    // For demo, award 10 points
    final success = await ApiService.earnPoints(
      userId: user.id,
      amount: 10,
      businessId: businessId,
    );
    if (success) {
      onPointsCollected?.call(10);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Collected +10 points via QR!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to collect points.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.qr_code_2),
        label: const Text('Collect via QR'),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: () => _handleQRCollect(context),
      ),
    );
  }
}
