import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grove_rewards/services/nfc_service.dart';

class NFCCollectionWidget extends StatefulWidget {
  final Function(int points) onPointsCollected;

  const NFCCollectionWidget({
    super.key,
    required this.onPointsCollected,
  });

  @override
  State<NFCCollectionWidget> createState() => _NFCCollectionWidgetState();
}

class _NFCCollectionWidgetState extends State<NFCCollectionWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  bool _isScanning = false;
  String _statusMessage = 'Tap to collect points';

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startNFCCollection() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _statusMessage = 'Hold your device near the NFC tag...';
    });

    // Start pulse animation
    _pulseController.repeat(reverse: true);

    // Haptic feedback
    HapticFeedback.lightImpact();

    try {
      // For demo purposes, simulate NFC collection after a delay
      await Future.delayed(const Duration(seconds: 2));

      final result = await NFCService.simulateNFCCollection();

      if (result.success && result.pointsEarned != null) {
        // Success animation
        await _animationController.forward();
        await _animationController.reverse();

        // Stop pulse
        _pulseController.stop();
        _pulseController.reset();

        // Success haptic feedback
        HapticFeedback.heavyImpact();

        setState(() {
          _isScanning = false;
          _statusMessage = 'Success! +${result.pointsEarned} points earned';
        });

        // Notify parent
        widget.onPointsCollected(result.pointsEarned!);

        // Show success dialog
        _showSuccessDialog(result.pointsEarned!);

        // Reset message after delay
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _statusMessage = 'Tap to collect points';
            });
          }
        });
      } else {
        _handleNFCError(result.message);
      }
    } catch (e) {
      _handleNFCError('Failed to collect points. Please try again.');
    }
  }

  void _handleNFCError(String errorMessage) {
    _pulseController.stop();
    _pulseController.reset();

    HapticFeedback.heavyImpact();

    setState(() {
      _isScanning = false;
      _statusMessage = errorMessage;
    });

    // Reset message after delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _statusMessage = 'Tap to collect points';
        });
      }
    });
  }

  void _showSuccessDialog(int points) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildSuccessDialog(points),
    );

    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  Widget _buildSuccessDialog(int points) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: theme.colorScheme.onPrimary,
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Points Collected!',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              '+$points points added to your account',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Continue',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isScanning
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: _isScanning
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Text(
            'NFC Collection',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Hold your phone near an NFC tag to collect loyalty points',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // NFC Icon with animations
          GestureDetector(
            onTap: _isScanning ? null : _startNFCCollection,
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: _isScanning
                              ? theme.colorScheme.primary.withValues(alpha: 0.1)
                              : theme.colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                          border: _isScanning
                              ? Border.all(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.5 / _pulseAnimation.value,
                                  ),
                                  width: 2 * _pulseAnimation.value,
                                )
                              : null,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.nfc,
                            size: 48,
                            color: _isScanning
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Status message
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _statusMessage,
              key: ValueKey(_statusMessage),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _isScanning
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                fontWeight: _isScanning ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          if (_isScanning) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 2,
              child: LinearProgressIndicator(
                color: theme.colorScheme.primary,
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
