import 'package:flutter/material.dart';
import 'package:grove_rewards/services/auth_service.dart';
import 'package:grove_rewards/services/api_service.dart';
import 'package:grove_rewards/services/app_logger.dart';
import 'package:grove_rewards/services/points_service.dart';
import 'package:grove_rewards/services/voucher_service.dart';
import 'package:grove_rewards/screens/auth/login_screen.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, int> _pointsSummary = {};
  Map<String, int> _voucherStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final pointsSummary = await PointsService.getPointsSummary();
      final voucherStats = await VoucherService.getVoucherStats();

      if (mounted) {
        setState(() {
          _pointsSummary = pointsSummary;
          _voucherStats = voucherStats;
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

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showEditProfileDialog() {
    final theme = Theme.of(context);
    final user = AuthService.currentUser;
    final nameController = TextEditingController(text: user?.name ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              final updatedUser = await AuthService.updateProfile(
                name: nameController.text.trim(),
              );

              if (updatedUser != null) {
                setState(() {}); // Refresh the UI
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    // ask about export before deletion
    final exportConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Export Data'),
        content: const Text('Would you like to export your account data before deletion?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Yes')),
        ],
      ),
    );

    if (exportConfirmed == true) {
      await _exportAccountData();
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account'),
        content: const Text(
          'This action is irreversible. Are you sure you want to permanently delete your account and all associated data?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteAccount();
    }
  }

  Future<void> _exportAccountData() async {
    final user = AuthService.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final data = await ApiService.exportUserData(user.id);
      Navigator.of(context).pop();
      if (data == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to export data')));
        return;
      }

      final jsonString = JsonEncoder.withIndent('  ').convert(data);
      // Copy to clipboard as a simple export option
      await Clipboard.setData(ClipboardData(text: jsonString));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account data copied to clipboard')));
    } catch (e) {
      Navigator.of(context).pop();
      AppLogger.error('Export account error: $e', e, StackTrace.current);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('An error occurred exporting data')));
    }
  }

  Future<void> _deleteAccount() async {
    final user = AuthService.currentUser;
    if (user == null) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // Show progress
    navigator.push(DialogRoute<void>(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    ));

    try {
      final success = await ApiService.deleteUser(user.id);
      navigator.pop(); // dismiss progress

      if (success) {
        await AuthService.logout();
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('Failed to delete account. Please try again.'), backgroundColor: Colors.red),
        );
      }
    } catch (e, st) {
      navigator.pop();
      AppLogger.error('Delete account error: $e', e, st);
      messenger.showSnackBar(
        const SnackBar(content: Text('An error occurred. Please try again later.'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final user = AuthService.currentUser;
    if (user == null) return;

    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 80);
    if (xfile == null) return;

    // Read bytes and encode base64
    final bytes = await xfile.readAsBytes();
    final b64 = base64Encode(bytes);

    // Show progress
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    navigator.push(DialogRoute<void>(context: context, builder: (c) => const Center(child: CircularProgressIndicator())));

    try {
      final avatarPath = await ApiService.uploadAvatar(user.id, xfile.name, b64);
      navigator.pop();
      if (avatarPath != null) {
        // Update local user record with new avatar path
        final updatedUser = user.copyWith(avatar: avatarPath, updatedAt: DateTime.now());
        await AuthService.updateCurrentUser(updatedUser);
        setState(() {});
        messenger.showSnackBar(const SnackBar(content: Text('Avatar updated')));
      } else {
        messenger.showSnackBar(const SnackBar(content: Text('Failed to upload avatar')));
      }
    } catch (e, st) {
      navigator.pop();
      AppLogger.error('Avatar upload error: $e', e, st);
      messenger.showSnackBar(const SnackBar(content: Text('Error uploading avatar')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = AuthService.currentUser;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Profile',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 32),

              // User Info Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                                GestureDetector(
                                  onTap: _pickAndUploadAvatar,
                                  child: CircleAvatar(
                                    radius: 40,
                                    backgroundColor: theme.colorScheme.primary,
                                    child: user?.avatar != null && user!.avatar!.isNotEmpty && Uri.tryParse(user.avatar!)?.hasAbsolutePath == true
                                        ? ClipOval(
                                            child: Image.network(
                                              user.avatar!,
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Text(
                                                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                                style: theme.textTheme.headlineMedium?.copyWith(
                                                  color: theme.colorScheme.onPrimary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          )
                                        : Text(
                                            user?.name.isNotEmpty == true
                                                ? user!.name[0].toUpperCase()
                                                : 'U',
                                            style: theme.textTheme.headlineMedium?.copyWith(
                                              color: theme.colorScheme.onPrimary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'User',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? 'No email',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Member since ${user?.createdAt.year ?? 'Unknown'}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _showEditProfileDialog,
                      icon: Icon(
                        Icons.edit,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Stats Section
              Text(
                'Your Stats',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: Icons.stars,
                        title: 'Points Earned',
                        value: '${_pointsSummary['totalEarned'] ?? 0}',
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: Icons.redeem,
                        title: 'Points Redeemed',
                        value: '${_pointsSummary['totalRedeemed'] ?? 0}',
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 16),

              if (!_isLoading)
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: Icons.confirmation_num,
                        title: 'Vouchers',
                        value: '${_voucherStats['total'] ?? 0}',
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: Icons.account_balance_wallet,
                        title: 'Current Balance',
                        value: '${_pointsSummary['currentBalance'] ?? 0}',
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 32),

              // Settings Section
              Text(
                'Settings',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              _buildSettingsItem(
                context,
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Manage notification preferences',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notification settings coming soon!'),
                    ),
                  );
                },
              ),

              _buildSettingsItem(
                context,
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                subtitle: 'Read our privacy policy',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Privacy policy coming soon!'),
                    ),
                  );
                },
              ),

              _buildSettingsItem(
                context,
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle: 'Get help with the app',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Help & support coming soon!'),
                    ),
                  );
                },
              ),

              _buildSettingsItem(
                context,
                icon: Icons.info_outline,
                title: 'About',
                subtitle: 'App version and information',
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Tap&Collect',
                    applicationVersion: '1.0.0',
                    applicationIcon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.nfc,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    children: [
                      const Text(
                          'A modern NFC-enabled loyalty points system for small businesses.'),
                    ],
                  );
                },
              ),

              const SizedBox(height: 8),

              _buildSettingsItem(
                context,
                icon: Icons.delete_outline,
                title: 'Delete Account',
                subtitle: 'Permanently delete your account and data',
                onTap: _confirmDeleteAccount,
              ),

              const SizedBox(height: 32),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: _logout,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Logout',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
