import 'package:flutter/material.dart';
import 'package:grove_rewards/models/reward.dart';
import 'package:grove_rewards/services/merchant_auth_service.dart';
import 'package:grove_rewards/services/rewards_service.dart';
import 'package:grove_rewards/services/voucher_service.dart';
import 'package:grove_rewards/services/transaction_service.dart';
import 'package:grove_rewards/services/business_service.dart';
import 'package:uuid/uuid.dart';
import 'package:grove_rewards/widgets/merchant_qr_widget.dart';

class MerchantDashboardScreen extends StatefulWidget {
  const MerchantDashboardScreen({super.key});

  @override
  State<MerchantDashboardScreen> createState() =>
      _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends State<MerchantDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    // CHANGED: Increased length to 4 to accommodate the new Overview tab
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _switchToTab(int index) {
    _tabController.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    final merchant = MerchantAuthService.currentMerchant;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Merchant Dashboard',
            style: theme.textTheme.titleLarge
                ?.copyWith(color: theme.colorScheme.onSurface)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable:
              true, // Made scrollable in case of small screens with 4 tabs
          tabAlignment: TabAlignment.start,
          labelStyle: theme.textTheme.titleSmall,
          tabs: const [
            // NEW TAB
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Overview'),
            Tab(icon: Icon(Icons.card_giftcard), text: 'Rewards'),
            Tab(icon: Icon(Icons.verified_outlined), text: 'Validate'),
            Tab(icon: Icon(Icons.insights_outlined), text: 'Analytics'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: theme.colorScheme.primary),
            onPressed: () async {
              await MerchantAuthService.logout();
              if (mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: merchant == null
          ? Center(
              child: Text('Session expired. Please log in again.',
                  style: theme.textTheme.bodyMedium),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // NEW TAB WIDGET
                _OverviewTab(
                  businessId: merchant.businessId,
                  onSwitchTab: _switchToTab,
                ),
                _RewardsTab(businessId: merchant.businessId),
                _ValidateTab(businessId: merchant.businessId),
                _AnalyticsTab(businessId: merchant.businessId),
              ],
            ),
    );
  }
}

// --- NEW OVERVIEW TAB ---
class _OverviewTab extends StatefulWidget {
  final String businessId;
  final Function(int) onSwitchTab;
  const _OverviewTab({required this.businessId, required this.onSwitchTab});

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  String _businessName = '...';
  int _activeRewardsCount = 0;
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final business = await BusinessService.getBusinessById(widget.businessId);
    final rewards =
        await RewardsService.getRewardsForBusiness(widget.businessId);
    final stats =
        await VoucherService.getVoucherStatsForBusiness(widget.businessId);

    if (mounted) {
      setState(() {
        _businessName = business?.name ?? 'Merchant';
        _activeRewardsCount = rewards.where((r) => r.isActive).length;
        _stats = stats;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome back,',
                          style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer)),
                      Text(_businessName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer)),
                    ],
                  ),
                ),
                CircleAvatar(
                  backgroundColor: theme.colorScheme.surface,
                  child: Icon(Icons.store, color: theme.colorScheme.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Quick Actions
          Text('Quick Actions',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.qr_code_scanner,
                  label: 'Validate Voucher',
                  color: Colors.orange,
                  onTap: () => widget.onSwitchTab(2), // Switch to Validate tab
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.add_circle_outline,
                  label: 'New Reward',
                  color: Colors.green,
                  onTap: () => widget.onSwitchTab(1), // Switch to Rewards tab
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          // Button to show merchant QR for customers to scan
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_2),
              label: const Text('Show Customer QR'),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (ctx) {
                    return SafeArea(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: MerchantQRWidget(
                            businessId: widget.businessId,
                            businessName: _businessName,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 24),
          // At a Glance Section
          Text('At a Glance',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                _SummaryRow(
                    icon: Icons.card_giftcard,
                    label: 'Active Rewards',
                    value: '$_activeRewardsCount'),
                const Divider(height: 24),
                _SummaryRow(
                    icon: Icons.confirmation_number_outlined,
                    label: 'Vouchers Waiting',
                    value: '${_stats['active'] ?? 0}'),
                const Divider(height: 24),
                _SummaryRow(
                    icon: Icons.check_circle_outline,
                    label: 'Total Redeemed',
                    value: '${_stats['redeemed'] ?? 0}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionCard(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(label,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _SummaryRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// --- EXISTING TABS BELOW (Unchanged logic, just kept for completeness) ---

class _RewardsTab extends StatefulWidget {
  final String businessId;
  const _RewardsTab({required this.businessId});

  @override
  State<_RewardsTab> createState() => _RewardsTabState();
}

class _RewardsTabState extends State<_RewardsTab> {
  late Future<List<Reward>> _rewardsFuture;

  @override
  void initState() {
    super.initState();
    _rewardsFuture = RewardsService.getRewardsForBusiness(widget.businessId);
  }

  Future<void> _refresh() async {
    setState(() {
      _rewardsFuture = RewardsService.getRewardsForBusiness(widget.businessId);
    });
  }

  Future<void> _openRewardEditor({Reward? reward}) async {
    final theme = Theme.of(context);
    final titleController = TextEditingController(text: reward?.title ?? '');
    final descController =
        TextEditingController(text: reward?.description ?? '');
    final pointsController =
        TextEditingController(text: reward?.pointsCost.toString() ?? '');
    DateTime? expiresAt = reward?.expiresAt;
    bool isActive = reward?.isActive ?? true;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: StatefulBuilder(builder: (ctx, setStateModal) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.card_giftcard,
                            color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(reward == null ? 'Create Reward' : 'Edit Reward',
                            style: theme.textTheme.titleLarge),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: pointsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Points Cost',
                        prefixIcon: Icon(Icons.star_rate_rounded,
                            color: theme.colorScheme.primary),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: expiresAt ??
                                    now.add(const Duration(days: 30)),
                                firstDate: now,
                                lastDate:
                                    now.add(const Duration(days: 365 * 3)),
                              );
                              if (picked != null) {
                                setStateModal(() => expiresAt = DateTime(
                                    picked.year, picked.month, picked.day));
                              }
                            },
                            icon: Icon(Icons.event,
                                color: theme.colorScheme.primary),
                            label: Text(expiresAt == null
                                ? 'No Expiry'
                                : 'Expires: ${expiresAt!.toLocal().toString().split(' ').first}'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: isActive,
                              onChanged: (v) =>
                                  setStateModal(() => isActive = v),
                            ),
                            const SizedBox(width: 6),
                            Text(isActive ? 'Active' : 'Inactive'),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final title = titleController.text.trim();
                          final desc = descController.text.trim();
                          final points =
                              int.tryParse(pointsController.text.trim());
                          if (title.isEmpty ||
                              desc.isEmpty ||
                              points == null ||
                              points <= 0) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Please fill all fields correctly')));
                            return;
                          }
                          final now = DateTime.now();
                          if (reward == null) {
                            final newReward = Reward(
                              id: const Uuid().v4(),
                              businessId: widget.businessId,
                              title: title,
                              description: desc,
                              pointsCost: points,
                              imageUrl: null,
                              isActive: isActive,
                              expiresAt: expiresAt,
                              createdAt: now,
                              updatedAt: now,
                            );
                            await RewardsService.addReward(newReward);
                          } else {
                            final updated = reward.copyWith(
                              title: title,
                              description: desc,
                              pointsCost: points,
                              isActive: isActive,
                              expiresAt: expiresAt,
                              updatedAt: now,
                            );
                            await RewardsService.updateReward(updated);
                          }
                          if (context.mounted) Navigator.of(ctx).pop(true);
                        },
                        icon: Icon(Icons.save_outlined,
                            color: Theme.of(context).colorScheme.onPrimary),
                        label: Text('Save',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );

    if (result == true) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<Reward>>(
        future: _rewardsFuture,
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Rewards & Campaigns',
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ),
                    FilledButton.icon(
                      onPressed: () => _openRewardEditor(),
                      style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary),
                      icon:
                          Icon(Icons.add, color: theme.colorScheme.onSecondary),
                      label: Text('New',
                          style: theme.textTheme.labelLarge
                              ?.copyWith(color: theme.colorScheme.onSecondary)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final r = items[index];
                    return InkWell(
                      onTap: () => _openRewardEditor(reward: r),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.08)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.local_offer_outlined,
                                color: theme.colorScheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.title,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(r.description,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.7))),
                                  const SizedBox(height: 6),
                                  Wrap(spacing: 8, runSpacing: 4, children: [
                                    Chip(
                                        label: Text('${r.pointsCost} pts'),
                                        avatar:
                                            const Icon(Icons.star, size: 18)),
                                    if (r.expiresAt != null)
                                      Chip(
                                          label: Text(
                                              'Expires ${r.expiresAt!.toLocal().toString().split(' ').first}'),
                                          avatar: const Icon(Icons.event,
                                              size: 18)),
                                    Chip(
                                        label: Text(
                                            r.isActive ? 'Active' : 'Inactive'),
                                        avatar: Icon(
                                            r.isActive
                                                ? Icons.check_circle
                                                : Icons.pause_circle_filled,
                                            size: 18,
                                            color: r.isActive
                                                ? Colors.green
                                                : Colors.orange)),
                                  ]),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.edit_outlined,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ValidateTab extends StatefulWidget {
  final String businessId;
  const _ValidateTab({required this.businessId});

  @override
  State<_ValidateTab> createState() => _ValidateTabState();
}

class _ValidateTabState extends State<_ValidateTab> {
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _statusMessage;

  Future<void> _validate() async {
    setState(() {
      _loading = true;
      _statusMessage = null;
    });

    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _loading = false;
        _statusMessage = 'Enter voucher code';
      });
      return;
    }

    final voucher = await VoucherService.findVoucherByCodeGlobal(code);
    if (voucher == null) {
      setState(() {
        _loading = false;
        _statusMessage = 'Voucher not found';
      });
      return;
    }

    final reward = await RewardsService.getRewardById(voucher.rewardId);
    if (reward == null || reward.businessId != widget.businessId) {
      setState(() {
        _loading = false;
        _statusMessage = 'Voucher does not belong to this business';
      });
      return;
    }

    // Try redeem
    final success = await VoucherService.redeemVoucherByCodeForBusiness(
        code, widget.businessId);
    setState(() {
      _loading = false;
      _statusMessage = success
          ? 'Redemption validated. Voucher exchanged.'
          : 'Voucher invalid or already used/expired';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Validate Redemption',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Voucher code',
              hintText: 'e.g. AB12CD34',
              prefixIcon: Icon(Icons.qr_code_2_outlined,
                  color: theme.colorScheme.primary),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _validate,
              icon: Icon(Icons.verified_outlined,
                  color: theme.colorScheme.onPrimary),
              label: _loading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: theme.colorScheme.onPrimary))
                  : Text('Confirm Validation',
                      style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_statusMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: theme.colorScheme.onPrimaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(_statusMessage!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AnalyticsTab extends StatefulWidget {
  final String businessId;
  const _AnalyticsTab({required this.businessId});

  @override
  State<_AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<_AnalyticsTab> {
  late Future<Map<String, int>> _voucherStatsFuture;
  late Future<Map<String, dynamic>> _thisMonthFuture;

  @override
  void initState() {
    super.initState();
    _voucherStatsFuture =
        VoucherService.getVoucherStatsForBusiness(widget.businessId);
    _thisMonthFuture =
        TransactionService.getMonthlySummaryForBusiness(widget.businessId);
  }

  Future<void> _refresh() async {
    setState(() {
      _voucherStatsFuture =
          VoucherService.getVoucherStatsForBusiness(widget.businessId);
      _thisMonthFuture =
          TransactionService.getMonthlySummaryForBusiness(widget.businessId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Customer Activity',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          FutureBuilder<Map<String, int>>(
            future: _voucherStatsFuture,
            builder: (context, snap) {
              final stats = snap.data ??
                  {'active': 0, 'redeemed': 0, 'expired': 0, 'total': 0};
              return Row(
                children: [
                  _StatCard(
                      icon: Icons.card_giftcard,
                      label: 'Active',
                      value: stats['active'] ?? 0,
                      color: Colors.green),
                  const SizedBox(width: 12),
                  _StatCard(
                      icon: Icons.verified,
                      label: 'Redeemed',
                      value: stats['redeemed'] ?? 0,
                      color: Colors.blue),
                  const SizedBox(width: 12),
                  _StatCard(
                      icon: Icons.schedule,
                      label: 'Expired',
                      value: stats['expired'] ?? 0,
                      color: Colors.orange),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          FutureBuilder<Map<String, dynamic>>(
            future: _thisMonthFuture,
            builder: (context, snap) {
              final data = snap.data ??
                  {'earnedPoints': 0, 'redeemedPoints': 0, 'netPoints': 0};
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.trending_up,
                            color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text('This Month Summary',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(spacing: 12, runSpacing: 12, children: [
                      _MiniStat(
                          label: 'Earned',
                          value: data['earnedPoints'] ?? 0,
                          icon: Icons.add_circle_outline),
                      _MiniStat(
                          label: 'Redeemed',
                          value: data['redeemedPoints'] ?? 0,
                          icon: Icons.remove_circle_outline),
                      _MiniStat(
                          label: 'Net',
                          value: data['netPoints'] ?? 0,
                          icon: Icons.equalizer),
                    ]),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  const _StatCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 6),
            Text(label,
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            Text('$value',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  const _MiniStat(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onPrimaryContainer),
          const SizedBox(width: 8),
          Text('$label: $value',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
        ],
      ),
    );
  }
}
