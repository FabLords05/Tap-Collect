import 'package:flutter/material.dart';
import 'package:grove_rewards/models/voucher.dart';

class VoucherCard extends StatelessWidget {
  final Voucher voucher;
  final VoidCallback onTap;

  const VoucherCard({
    super.key,
    required this.voucher,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = voucher.status == VoucherStatus.active && 
                    voucher.expiresAt.isAfter(DateTime.now());
    final isExpired = voucher.expiresAt.isBefore(DateTime.now()) || 
                     voucher.status == VoucherStatus.expired;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? theme.colorScheme.primary.withValues(alpha: 0.3)
                : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive ? [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Voucher icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(voucher.status, isExpired, theme).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.confirmation_num,
                    color: _getStatusColor(voucher.status, isExpired, theme),
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Voucher code
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Voucher Code',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        voucher.code,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(voucher.status, isExpired, theme).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(voucher.status, isExpired),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _getStatusColor(voucher.status, isExpired, theme),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Expiry date
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  isExpired 
                      ? 'Expired ${_formatDate(voucher.expiresAt)}'
                      : 'Expires ${_formatDate(voucher.expiresAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isExpired 
                        ? Colors.orange
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: isExpired ? FontWeight.w600 : null,
                  ),
                ),
              ],
            ),
            
            // Redemption date (if redeemed)
            if (voucher.status == VoucherStatus.redeemed && voucher.redeemedAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Redeemed ${_formatDate(voucher.redeemedAt!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Action hint
            Row(
              children: [
                Text(
                  isActive 
                      ? 'Tap to view details and redeem'
                      : 'Tap to view details',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary.withValues(alpha: isActive ? 1.0 : 0.6),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(VoucherStatus status, bool isExpired, ThemeData theme) {
    if (isExpired) return Colors.orange;
    
    switch (status) {
      case VoucherStatus.active:
        return theme.colorScheme.primary;
      case VoucherStatus.redeemed:
        return Colors.green;
      case VoucherStatus.expired:
        return Colors.orange;
    }
  }

  String _getStatusText(VoucherStatus status, bool isExpired) {
    if (isExpired && status == VoucherStatus.active) return 'Expired';
    
    switch (status) {
      case VoucherStatus.active:
        return 'Active';
      case VoucherStatus.redeemed:
        return 'Used';
      case VoucherStatus.expired:
        return 'Expired';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return 'on ${date.day}/${date.month}/${date.year}';
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}