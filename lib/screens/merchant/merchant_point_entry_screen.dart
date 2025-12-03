import 'package:flutter/material.dart';
import 'package:grove_rewards/services/api_service.dart';
import 'package:grove_rewards/services/auth_service.dart';
import 'package:grove_rewards/services/merchant_auth_service.dart';
import 'package:grove_rewards/services/app_logger.dart';

class MerchantPointEntryScreen extends StatefulWidget {
  final String userId; // The customer's ID (scanned from QR/NFC)
  
  const MerchantPointEntryScreen({
    super.key, 
    required this.userId
  });

  @override
  State<MerchantPointEntryScreen> createState() => _MerchantPointEntryScreenState();
}

class _MerchantPointEntryScreenState extends State<MerchantPointEntryScreen> {
  final TextEditingController _amountController = TextEditingController();
  
  // Default rate (1 currency unit = 10 points)
  // In a real app, this comes from the database
  double _pointsPerCurrency = 10.0; 
  
  int _calculatedPoints = 0;
  bool _isLoading = false;
  String? _merchantBusinessId;

  @override
  void initState() {
    super.initState();
    _loadMerchantData();
    // Listen to typing changes to update points in real-time
    _amountController.addListener(_calculatePoints);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  // 1. Load the Merchant's specific settings (Rate & Business ID)
  Future<void> _loadMerchantData() async {
    try {
      // Try to get the currently logged-in merchant
      final merchant = MerchantAuthService.currentMerchant;
      
      if (merchant != null) {
        setState(() {
          _merchantBusinessId = merchant.businessId;
          // If merchant has a specific rate, use it, otherwise default to 10
          _pointsPerCurrency = merchant.pointsPerCurrency?.toDouble() ?? 10.0;
        });
      } else {
        // Fallback for testing (if logged in as a regular user debugging this screen)
        setState(() {
           _pointsPerCurrency = AuthService.currentUser?.pointsPerCurrency?.toDouble() ?? 10.0;
           _merchantBusinessId = 'sample-biz'; // Fallback ID
        });
      }
      
      // Recalculate in case text was already entered
      _calculatePoints();
    } catch (e, st) {
      AppLogger.error('Error loading merchant data: $e', e, st);
    }
  }

  // 2. The Math Logic
  void _calculatePoints() {
    // Remove non-numeric characters (like currency symbols) if pasted
    String cleanText = _amountController.text.replaceAll(RegExp(r'[^0-9.]'), '');
    
    if (cleanText.isEmpty) {
      setState(() => _calculatedPoints = 0);
      return;
    }

    double amount = double.tryParse(cleanText) ?? 0.0;
    
    setState(() {
      // Formula: Amount Spent * Rate = Points
      _calculatedPoints = (amount * _pointsPerCurrency).round();
    });
  }

  // 3. Submit to Server
  Future<void> _submitTransaction() async {
    if (_calculatedPoints <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Call API to award points
      final success = await ApiService.earnPoints(
        userId: widget.userId,
        amount: _calculatedPoints,
        businessId: _merchantBusinessId ?? 'unknown-biz',
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (success) {
        // Success Dialog
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Success'),
              ],
            ),
            content: Text(
              'Awarded $_calculatedPoints points to customer successfully!',
              style: const TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to scanner
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to award points. Please check connection.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Add Points'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Customer ID Badge
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: theme.colorScheme.secondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer ID',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          Text(
                            widget.userId,
                            style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Amount Input
              Text(
                "Bill Amount",
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixText: '\$ ',
                  hintText: '0.00',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
              ),

              const SizedBox(height: 32),

              // Conversion Display
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Conversion Rate:',
                          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                        ),
                        Text(
                          'x${_pointsPerCurrency.toInt()}', // e.g. "x10"
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            color: theme.colorScheme.primary
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    const Text('TOTAL POINTS'),
                    const SizedBox(height: 8),
                    Text(
                      '$_calculatedPoints',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Icon(Icons.stars, size: 32, color: Colors.amber),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Confirm Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: (_calculatedPoints > 0 && !_isLoading) 
                      ? _submitTransaction 
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24, 
                          width: 24, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : const Text(
                          'Confirm & Award Points',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}