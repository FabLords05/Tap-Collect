import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';

class MerchantQRWidget extends StatelessWidget {
  final String businessId;
  final String businessName;

  /// Optional: pass a custom payload; otherwise a signed-ish URL is generated
  final String? payload;

  const MerchantQRWidget({
    super.key,
    required this.businessId,
    required this.businessName,
    this.payload,
  });

  String _buildPayload() {
    if (payload != null && payload!.isNotEmpty) return payload!;
    final nonce = const Uuid().v4();
    final ts = DateTime.now().toUtc().millisecondsSinceEpoch;
    // Simple merchant QR format — parseable on the client: grove://merchant/<businessId>?nonce=<uuid>&ts=<ts>
    return 'grove://merchant/$businessId?nonce=$nonce&ts=$ts';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qrData = _buildPayload();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            businessName,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: qrData,
              size: 220.0,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          SelectableText(qrData, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy Code'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: qrData));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('QR code copied')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                  onPressed: () {
                    // Use platform share if available — keep minimal (no package added)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Use OS share to share the QR image'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
