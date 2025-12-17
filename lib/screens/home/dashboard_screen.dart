import 'package:flutter/material.dart';
import 'package:grove_rewards/services/auth_service.dart';
import 'package:grove_rewards/services/points_service.dart';
import 'package:grove_rewards/services/transaction_service.dart';
import 'package:grove_rewards/services/nfc_service.dart';
import 'package:grove_rewards/services/business_activation_service.dart';
import 'package:grove_rewards/services/api_service.dart'; // <--- FIX: Added missing import
import 'package:grove_rewards/services/storage_service.dart';
import 'package:grove_rewards/widgets/qr_collection_widget.dart';
import 'package:grove_rewards/models/transaction.dart';
import 'package:grove_rewards/widgets/nfc_collection_widget.dart';
import 'package:grove_rewards/widgets/points_card.dart';
import 'package:grove_rewards/widgets/recent_activity_card.dart';
import 'package:grove_rewards/widgets/business_activation_button.dart';
import 'package:grove_rewards/screens/home/visited_businesses_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onNavigateToRewards;

  const DashboardScreen({
    super.key,
    required this.onNavigateToRewards,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _pointsBalance = 0;
  List<Transaction> _recentTransactions = [];
  bool _isLoading = true;

  String? _currentBusinessId;
  bool _isBusinessActivated = false;

  @override
  void initState() {
    super.initState();
    // Try to use the first activated business from the local user cache.
    // The backend refresh in `_loadDashboardData()` will update this.
    _currentBusinessId =
        AuthService.currentUser?.activatedBusinessIds.isNotEmpty == true
            ? AuthService.currentUser!.activatedBusinessIds.first
            : null;
    // Quickly load the cached balance so the UI shows the user's points
    // as soon as possible while the full dashboard refresh runs.
    PointsService.getBalance().then((balance) {
      if (mounted) {
        setState(() {
          _pointsBalance = balance;
        });
      }
    });
    _loadDashboardData();
    _initializeNFC();
    _checkBusinessActivation();
  }

  Future<void> _initializeNFC() async {
    await NFCService.initialize();
  }

  void _checkBusinessActivation() {
    setState(() {
      _isBusinessActivated = _currentBusinessId != null &&
          BusinessActivationService.isBusinessActivated(
            _currentBusinessId!,
          );
    });
  }

  void _onBusinessActivationComplete() {
    // Refresh the current business id from the updated user
    final updated = AuthService.currentUser;
    if (updated != null && updated.activatedBusinessIds.isNotEmpty) {
      setState(() {
        _currentBusinessId = updated.activatedBusinessIds.first;
      });
    } else {
      setState(() {
        _currentBusinessId = null;
      });
    }
    _checkBusinessActivation();
  }

  Future<void> _loadDashboardData() async {
    try {
      final user = AuthService.currentUser;

      // Fetch fresh data from backend (MongoDB)
      if (user != null) {
        final userFromBackend = await ApiService.getUser(user.id);
        if (userFromBackend != null) {
          // Update local storage with backend data
          await AuthService.updateCurrentUser(userFromBackend);
          // Update active business id from backend user if available
          if (userFromBackend.activatedBusinessIds.isNotEmpty) {
            _currentBusinessId = userFromBackend.activatedBusinessIds.first;
          } else {
            _currentBusinessId = null;
          }
          _checkBusinessActivation();
        }
      }

      // Now load balance and transactions from storage
      final balance = await PointsService.getBalance();
      final transactions = await TransactionService.getRecentTransactions(5);

      if (mounted) {
        setState(() {
          _pointsBalance = balance;
          _recentTransactions = transactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await _loadDashboardData();
  }

  // --- NEW: Save points to MongoDB via ApiService ---
  void _onPointsCollected(int points) async {
    final user = AuthService.currentUser;
    if (user == null) return;

    if (_currentBusinessId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activate a business first to collect points.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 1. Optimistic Update (Update screen instantly)
    setState(() {
      _pointsBalance += points;
    });

    // 2. Send to Server
    bool success = await ApiService.earnPoints(
      userId: user.id,
      amount: points,
      businessId: _currentBusinessId!,
    );

    if (success) {
      // 3. Sync Data (Success)
      _loadDashboardData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Saved +$points points to cloud!")),
      );
    } else {
      // 4. Rollback (Failure)
      setState(() {
        _pointsBalance -= points;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Connection failed. Points not saved."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = AuthService.currentUser;

    return FutureBuilder<String?>(
      future: StorageService.getAppMode(),
      builder: (context, snapshot) {
        final appMode = snapshot.data ?? 'tap';
        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              color: theme.colorScheme.primary,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    floating: true,
                    backgroundColor: theme.colorScheme.surface,
                    elevation: 0,
                    flexibleSpace: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Text(
                              user?.name.isNotEmpty == true
                                  ? user!.name[0].toUpperCase()
                                  : 'U',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Welcome back,',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
                                ),
                                Text(
                                  user?.name ?? 'User',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Notifications coming soon!')),
                              );
                            },
                            icon: Icon(
                              Icons.notifications_outlined,
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    expandedHeight: 80,
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        PointsCard(
                            points: _pointsBalance, isLoading: _isLoading),
                        const SizedBox(height: 24),
                        if (!_isBusinessActivated)
                          BusinessActivationButton(
                            businessId: _currentBusinessId ?? 'sample-biz',
                            businessName: 'This Business',
                            onActivationComplete: _onBusinessActivationComplete,
                          )
                        else if (appMode == 'tap')
                          NFCCollectionWidget(
                              onPointsCollected: _onPointsCollected)
                        else
                          QRCollectionWidget(
                            businessId: _currentBusinessId ?? 'sample-biz',
                            onPointsCollected: _onPointsCollected,
                          ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Activity',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_recentTransactions.isNotEmpty)
                              TextButton(
                                onPressed: () {},
                                child: Text(
                                  'View All',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_isLoading)
                          const Center(
                              child: Padding(
                                  padding: EdgeInsets.all(32),
                                  child: CircularProgressIndicator()))
                        else if (_recentTransactions.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: theme.colorScheme.outline
                                      .withOpacity(0.2)),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.history_outlined,
                                    size: 48,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.4)),
                                const SizedBox(height: 16),
                                Text(
                                  'No activity yet',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.6)),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  appMode == 'tap'
                                      ? 'Start collecting points by tapping NFC tags at participating businesses'
                                      : 'Start collecting points by scanning QR codes at participating businesses',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.5)),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        else
                          ...List.generate(
                            _recentTransactions.length,
                            (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: RecentActivityCard(
                                  transaction: _recentTransactions[index]),
                            ),
                          ),
                        const SizedBox(height: 24),
                        Text(
                          'Quick Actions',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickActionCard(
                                context,
                                icon: Icons.card_giftcard,
                                title: 'Browse Rewards',
                                subtitle: 'See what you can redeem',
                                onTap: widget.onNavigateToRewards,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildQuickActionCard(
                                context,
                                icon: Icons.store,
                                title: 'Find Businesses',
                                subtitle: 'Discover nearby partners',
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Business finder coming soon!')),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildFullWidthActionCard(
                          context,
                          icon: Icons.business,
                          title: 'My Visited Businesses',
                          subtitle: 'View businesses you\'ve scanned',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const VisitedBusinessesScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: theme.colorScheme.onPrimary, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullWidthActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: theme.colorScheme.secondary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: theme.colorScheme.onSecondary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: theme.colorScheme.onSurface.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }
}
