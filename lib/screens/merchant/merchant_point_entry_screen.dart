import 'package:flutter/material.dart';
import 'package:grove_rewards/services/api_service.dart';
import 'package:grove_rewards/services/auth_service.dart';
import 'package:grove_rewards/services/merchant_auth_service.dart';
import 'package:grove_rewards/services/app_logger.dart';

class MerchantPointEntryScreen extends StatefulWidget {
  final String userId;
  const MerchantPointEntryScreen({super.key, required this.userId});

  @override
  State<MerchantPointEntryScreen> createState() => _MerchantPointEntryScreenState();
}

class _MerchantPointEntryScreenState extends State<MerchantPointEntryScreen> {
  final TextEditingController _amountController = TextEditingController();
  
  double _pointsPerCurrency = 10.0; // fallback default
  
  int _calculatedPoints = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadRate();
    _amountController.addListener(_recalculate);
  }

  void _recalculate() {
    final text = _amountController.text.replaceAll(',', '').trim();
    final value = double.tryParse(text) ?? 0.0;
    setState(() {
      _calculatedPoints = (value * _pointsPerCurrency).round();
    });
  }

  Future<void> _loadRate() async {
    try {
      // Try merchant-specific service first; fallback to auth user
      double? rate;
      try {
        final merchant = MerchantAuthService.currentMerchant;
        rate = merchant?.pointsPerCurrency?.toDouble(); 
      } catch (_) {}
      
      rate ??= AuthService.currentUser?.pointsPerCurrency?.toDouble();
      
      // FIX: Use null-aware assignment operator instead of 'if'
      rate ??= 10.0;
      
      setState(() => _pointsPerCurrency = rate!);
      _recalculate();
    } catch (e, st) {
      // AppLogger.error('Load rate error: $e', e, st);
      setState(() => _pointsPerCurrency = 10.0);
    }
  }

  Future<void> _confirm() async {
    if (_calculatedPoints <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid bill amount')));
      return;
    }
    setState(() => _loading = true);
    try {
      final success = await ApiService.earnPoints(
        userId: widget.userId,
        amount: _calculatedPoints,
      );
      setState(() => _loading = false);
      if (success) {
        if (mounted) {
          await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Success'),
              content: Text('Awarded $_calculatedPoints points to ${widget.userId}'),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
              ],
            ),
          );
          Navigator.of(context).pop(); // go back to scanner
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to award points')));
        }
      }
    } catch (e, st) {
      // AppLogger.error('Earn points error: $e', e, st);
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error during transaction')));
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.userId;
    return Scaffold(
      appBar: AppBar(title: const Text('Award Points')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Customer ID: $userId', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Total Bill Amount',
                prefixText: '\$ ', 
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Points per Unit: ${_pointsPerCurrency.toStringAsFixed(2)}'),
                Text('Total Points: $_calculatedPoints'),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _confirm,
              child: _loading ? const CircularProgressIndicator.adaptive() : const Text('Confirm Transaction'),
            ),
          ],
        ),
      ),
    );
  }
}