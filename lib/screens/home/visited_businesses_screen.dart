import 'package:flutter/material.dart';
import 'package:grove_rewards/services/business_activation_service.dart';
import 'package:grove_rewards/services/storage_service.dart';
import 'package:grove_rewards/models/merchant.dart';

class VisitedBusinessesScreen extends StatefulWidget {
  const VisitedBusinessesScreen({super.key});

  @override
  State<VisitedBusinessesScreen> createState() =>
      _VisitedBusinessesScreenState();
}

class _VisitedBusinessesScreenState extends State<VisitedBusinessesScreen> {
  List<Merchant> _visitedBusinesses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVisitedBusinesses();
  }

  Future<void> _loadVisitedBusinesses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final activatedIds = BusinessActivationService.getActivatedBusinesses();
      final merchants = await StorageService.loadList('merchants');

      final visited = merchants
          .map((json) => Merchant.fromJson(json))
          .where((merchant) => activatedIds.contains(merchant.businessId))
          .toList();

      if (mounted) {
        setState(() {
          _visitedBusinesses = visited;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('My Visited Businesses'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _visitedBusinesses.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.store_outlined,
                          size: 80,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No Visited Businesses Yet',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Start scanning QR codes at businesses to see them here!',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _visitedBusinesses.length,
                  itemBuilder: (context, index) {
                    final business = _visitedBusinesses[index];
                    return _buildBusinessCard(context, business);
                  },
                ),
    );
  }

  Widget _buildBusinessCard(BuildContext context, Merchant merchant) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to business detail page
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('View details for ${merchant.name}'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  merchant.name.isNotEmpty
                      ? merchant.name[0].toUpperCase()
                      : 'B',
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
                  children: [
                    Text(
                      merchant.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Activated',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
