import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Requires qr_flutter package
import 'package:grove_rewards/services/auth_service.dart';

class CustomerIdentityScreen extends StatelessWidget {
  const CustomerIdentityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to view your ID")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Member ID"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Scan to collect points",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            
            // QR CODE GENERATOR
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: QrImageView(
                data: user.id, // Embeds User ID in the QR
                version: QrVersions.auto,
                size: 250.0,
                backgroundColor: Colors.white,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // NFC ANIMATION / INDICATOR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Theme.of(context).primaryColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.nfc, size: 30, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 12),
                  const Text(
                    "Or tap on terminal",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}