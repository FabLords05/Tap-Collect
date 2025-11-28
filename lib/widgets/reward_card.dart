import 'package:flutter/material.dart';
import 'package:grove_rewards/models/reward.dart';

class RewardCard extends StatelessWidget {
  final Reward reward;
  final int userPoints;
  final VoidCallback onRedeem;
  final String? businessName;

  const RewardCard({
    super.key,
    required this.reward,
    required this.userPoints,
    required this.onRedeem,
    this.businessName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canAfford = userPoints >= reward.pointsCost;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canAfford 
              ? theme.colorScheme.primary.withValues(alpha: 0.2)
              : theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: canAfford ? [
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
          // Header with emoji and title
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reward icon/emoji
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: canAfford 
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: canAfford
                          ? theme.colorScheme.primary.withValues(alpha: 0.2)
                          : theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    _getRewardEmoji(reward.title),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Title and description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reward.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                        if (businessName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            businessName!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      const SizedBox(height: 6),
                      Text(
                        reward.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Points cost badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: canAfford
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.stars,
                        size: 14,
                        color: canAfford
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${reward.pointsCost}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: canAfford
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Progress bar (if user is close to affording)
          if (!canAfford && userPoints > 0) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress to reward',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        '${reward.pointsCost - userPoints} more needed',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: userPoints / reward.pointsCost,
                    backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                  ),
                ],
              ),
            ),
          ],
          
          // Action button
          Padding(
            padding: const EdgeInsets.all(20).copyWith(top: canAfford ? 20 : 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: canAfford ? onRedeem : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canAfford 
                      ? theme.colorScheme.primary 
                      : theme.colorScheme.surface,
                  foregroundColor: canAfford 
                      ? theme.colorScheme.onPrimary 
                      : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: !canAfford ? BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ) : BorderSide.none,
                  ),
                ),
                child: Text(
                  canAfford ? 'Redeem Now' : 'Not enough points',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: canAfford 
                        ? theme.colorScheme.onPrimary 
                        : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRewardEmoji(String title) {
    final lowercaseTitle = title.toLowerCase();
    
    if (lowercaseTitle.contains('coffee')) return '☕';
    if (lowercaseTitle.contains('pastry')) return '🥐';
    if (lowercaseTitle.contains('lunch') || lowercaseTitle.contains('combo')) return '🥪';
    if (lowercaseTitle.contains('discount') || lowercaseTitle.contains('%') || lowercaseTitle.contains('off')) return '💰';
    if (lowercaseTitle.contains('dessert') || lowercaseTitle.contains('cake')) return '🍰';
    if (lowercaseTitle.contains('premium') || lowercaseTitle.contains('upgrade')) return '⭐';
    if (lowercaseTitle.contains('drink') || lowercaseTitle.contains('beverage')) return '🥤';
    if (lowercaseTitle.contains('sandwich')) return '🥪';
    if (lowercaseTitle.contains('tea')) return '🍵';
    if (lowercaseTitle.contains('smoothie')) return '🥤';
    if (lowercaseTitle.contains('burger')) return '🍔';
    if (lowercaseTitle.contains('pizza')) return '🍕';
    
    return '🎁'; // Default gift emoji
  }
}