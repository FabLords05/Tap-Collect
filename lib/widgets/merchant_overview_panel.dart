import 'package:flutter/material.dart';
import 'package:grove_rewards/services/transaction_service.dart';
import 'package:grove_rewards/services/voucher_service.dart';

class MerchantOverviewPanel extends StatelessWidget {
  final String businessId;
  const MerchantOverviewPanel({required this.businessId, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        VoucherService.getVoucherStatsForBusiness(businessId),
        TransactionService.getMonthlySummaryForBusiness(businessId),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
              height: 120, child: Center(child: CircularProgressIndicator()));
        }

        final voucherStats =
            (snapshot.data != null && snapshot.data!.isNotEmpty)
                ? Map<String, int>.from(snapshot.data![0] as Map)
                : {'total': 0, 'active': 0, 'redeemed': 0, 'expired': 0};

        final month = (snapshot.data != null && snapshot.data!.length > 1)
            ? Map<String, dynamic>.from(snapshot.data![1] as Map)
            : {
                'earnedPoints': 0,
                'redeemedPoints': 0,
                'netPoints': 0,
                'count': 0
              };

        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.insights_outlined,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Overview',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('This month', style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatCard(
                      label: 'Total Vouchers',
                      value: voucherStats['total'] ?? 0,
                      icon: Icons.wallet_giftcard_outlined,
                      color: Colors.purple),
                  const SizedBox(width: 12),
                  _StatCard(
                      label: 'Active',
                      value: voucherStats['active'] ?? 0,
                      icon: Icons.check_circle_outline,
                      color: Colors.green),
                  const SizedBox(width: 12),
                  _StatCard(
                      label: 'Redeemed',
                      value: voucherStats['redeemed'] ?? 0,
                      icon: Icons.verified,
                      color: Colors.blue),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _TinyStat(
                              label: 'Earned',
                              value: month['earnedPoints'] ?? 0,
                              icon: Icons.add_circle_outline),
                          _TinyStat(
                              label: 'Redeemed',
                              value: month['redeemedPoints'] ?? 0,
                              icon: Icons.remove_circle_outline),
                          _TinyStat(
                              label: 'Net',
                              value: month['netPoints'] ?? 0,
                              icon: Icons.equalizer),
                          _TinyStat(
                              label: 'Tx',
                              value: month['count'] ?? 0,
                              icon: Icons.receipt_long),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 6),
            Text(label,
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
            Text('$value',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _TinyStat extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  const _TinyStat(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onPrimaryContainer),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer
                        .withValues(alpha: 0.9))),
            Text('$value',
                style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
