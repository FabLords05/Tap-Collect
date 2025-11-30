import 'package:flutter/material.dart';
import 'package:grove_rewards/screens/home/dashboard_screen.dart';
import 'package:grove_rewards/screens/home/rewards_screen.dart';
import 'package:grove_rewards/screens/home/history_screen.dart';
import 'package:grove_rewards/services/storage_service.dart';
import 'package:grove_rewards/widgets/qr_collection_widget.dart';
import 'package:grove_rewards/screens/home/profile_screen.dart';
import 'package:grove_rewards/widgets/nfc_collection_widget.dart';
import 'package:grove_rewards/services/nfc_service.dart';
import 'package:grove_rewards/services/navigation_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _nfcPressed = false;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    NavigationService.currentIndex.addListener(_onNavigationRequest);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    NavigationService.currentIndex.removeListener(_onNavigationRequest);
    super.dispose();
  }

  void _onNavigationRequest() {
    final idx = NavigationService.currentIndex.value;
    if (mounted && idx != _currentIndex) {
      setState(() => _currentIndex = idx);
    }
  }

  // 1. ADDED: This function switches the tab to index 1 (Rewards)
  void _goToRewardsTab() {
    setState(() {
      _currentIndex = 1;
    });
  }

  Future<void> _openCollectorSheet() async {
    final theme = Theme.of(context);
    String? appMode = await StorageService.getAppMode();
    await NFCService.initialize();

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: theme.colorScheme.surface,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              if (appMode == 'tap')
                NFCCollectionWidget(
                  onPointsCollected: (points) {
                    Navigator.of(sheetContext).maybePop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Collected +$points points')),
                    );
                  },
                )
              else
                QRCollectionWidget(
                  businessId: 'sample-biz',
                  onPointsCollected: (points) {
                    Navigator.of(sheetContext).maybePop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Collected +$points points via QR')),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 2. FIXED: We define screens here so we can pass the function
    final List<Widget> screens = [
      // Pass the function to Dashboard!
      DashboardScreen(onNavigateToRewards: _goToRewardsTab),
      const RewardsScreen(),
      const HistoryScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.1),
              offset: const Offset(0, -2),
              blurRadius: 8,
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 92,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        icon: Icons.dashboard_outlined,
                        activeIcon: Icons.dashboard,
                        label: 'Home',
                        index: 0,
                      ),
                      _buildNavItem(
                        icon: Icons.card_giftcard_outlined,
                        activeIcon: Icons.card_giftcard,
                        label: 'Rewards',
                        index: 1,
                      ),
                      const SizedBox(width: 96),
                      _buildNavItem(
                        icon: Icons.history_outlined,
                        activeIcon: Icons.history,
                        label: 'History',
                        index: 2,
                      ),
                      _buildNavItem(
                        icon: Icons.person_outline,
                        activeIcon: Icons.person,
                        label: 'Profile',
                        index: 3,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  child: GestureDetector(
                    onTapDown: (_) => setState(() => _nfcPressed = true),
                    onTapCancel: () => setState(() => _nfcPressed = false),
                    onTapUp: (_) => setState(() => _nfcPressed = false),
                    onTap: _openCollectorSheet,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final t = _pulseController.value;
                            final scale = 1.0 + (t * 0.5);
                            final opacity = (1.0 - t) * 0.35;
                            return Opacity(
                              opacity: opacity,
                              child: Transform.scale(
                                scale: scale,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.20),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        AnimatedScale(
                          scale: _nfcPressed ? 0.95 : 1.0,
                          duration: const Duration(milliseconds: 120),
                          curve: Curves.easeOut,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.22),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                              border: Border.all(
                                color: theme.colorScheme.onPrimary
                                    .withValues(alpha: 0.10),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.nfc,
                                  color: theme.colorScheme.onPrimary,
                                  size: 34,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final theme = Theme.of(context);
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              size: 24,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
