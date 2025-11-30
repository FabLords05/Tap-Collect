import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'dart:convert'; // For JSON formatting and base64Decode
import 'package:image_picker/image_picker.dart';
import 'package:grove_rewards/services/auth_service.dart';
import 'package:grove_rewards/services/api_service.dart';
import 'package:grove_rewards/services/points_service.dart';
import 'package:grove_rewards/services/voucher_service.dart'; // Added back
import 'package:grove_rewards/services/app_logger.dart'; // Added back
import 'package:grove_rewards/screens/auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Map<String, int> _pointsSummary = {};
  Map<String, int> _voucherStats = {};

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      // Fetching all detailed stats
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

  // --- HELPER FOR PHOTOS ---
  ImageProvider? _getAvatarImage(String? avatar) {
    if (avatar == null || avatar.isEmpty) return null;
    if (avatar.startsWith('http')) {
      return NetworkImage(avatar);
    }
    try {
      return MemoryImage(base64Decode(avatar));
    } catch (e) {
      return null;
    }
  }

  // --- UPLOAD AVATAR LOGIC ---
  Future<void> _pickAndUploadAvatar() async {
    final user = AuthService.currentUser;
    if (user == null) return;

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 70,
    );

    if (image == null) return;

    // Show loading indicator
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    navigator.push(DialogRoute<void>(
        context: context,
        builder: (c) => const Center(child: CircularProgressIndicator())));

    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final avatarPath =
          await ApiService.uploadAvatar(user.id, image.name, base64Image);

      navigator.pop(); // Dismiss loading

      if (avatarPath != null) {
        final updatedUser = user.copyWith(avatar: avatarPath);
        await AuthService.updateCurrentUser(updatedUser);

        setState(() {}); // Refresh UI to show new image
        messenger.showSnackBar(
          const SnackBar(content: Text('Avatar updated successfully!')),
        );
      } else {
        throw Exception("Upload failed");
      }
    } catch (e) {
      navigator.pop(); // Dismiss loading on error
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to upload image. Server error.')),
      );
    }
  }

  // --- EDIT PROFILE LOGIC ---
  void _showEditProfileDialog() {
    final theme = Theme.of(context);
    final user = AuthService.currentUser;
    final nameController = TextEditingController(text: user?.name ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Profile'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isEmpty) return;

              Navigator.pop(context);
              _updateProfileField(name: newName);
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

  Future<void> _updateProfileField({String? name}) async {
    final user = AuthService.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      bool success = await ApiService.updateUser(user.id, {
        if (name != null) 'name': name,
      });

      if (success) {
        final updatedUser = user.copyWith(name: name);
        await AuthService.updateCurrentUser(updatedUser);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update profile.')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- EXPORT DATA LOGIC ---
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
      Navigator.of(context).pop(); // Dismiss loading

      if (data == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to export data')));
        return;
      }

      final jsonString = JsonEncoder.withIndent('  ').convert(data);
      await Clipboard.setData(ClipboardData(text: jsonString));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account data copied to clipboard')),
      );
    } catch (e, st) {
      Navigator.of(context).pop();
      AppLogger.error('Export account error: $e', e, st);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred exporting data')));
    }
  }

  // --- DELETE ACCOUNT LOGIC ---
  Future<void> _confirmDeleteAccount() async {
    final exportConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Export Data'),
        content: const Text(
            'Would you like to export your account data before deletion?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No')),
          ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes')),
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
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    final user = AuthService.currentUser;
    if (user == null) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    navigator.push(DialogRoute<void>(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    ));

    try {
      final success = await ApiService.deleteUser(user.id);
      navigator.pop();

      if (success) {
        await AuthService.logout();
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
              content: Text('Failed to delete account. Please try again.'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e, st) {
      navigator.pop();
      AppLogger.error('Delete account error: $e', e, st);
      messenger.showSnackBar(
        const SnackBar(
            content: Text('An error occurred. Please try again later.'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = AuthService.currentUser;

    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: _isLoading && _pointsSummary.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- PROFILE CARD ---
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primaryContainer,
                            theme.colorScheme.primaryContainer.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _pickAndUploadAvatar,
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: theme.colorScheme.primary,
                                  backgroundImage: _getAvatarImage(user.avatar),
                                  child: _getAvatarImage(user.avatar) == null
                                      ? Text(
                                          user.name.isNotEmpty
                                              ? user.name[0].toUpperCase()
                                              : 'U',
                                          style: TextStyle(
                                              fontSize: 32,
                                              color:
                                                  theme.colorScheme.onPrimary),
                                        )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.secondary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.camera_alt,
                                        size: 14,
                                        color: theme.colorScheme.onSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        user.name,
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18),
                                      onPressed: _showEditProfileDialog,
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.6),
                                    )
                                  ],
                                ),
                                Text(
                                  user.email,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Points: ${_pointsSummary['currentBalance'] ?? 0}',
                                    style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // --- STATS SECTION ---
                    Text(
                      'Your Stats',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

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

                    // --- GENERAL SETTINGS ---
                    Text('Settings',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    _buildSettingsItem(
                      context,
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: 'Manage notification preferences',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Notification settings coming soon!')),
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
                              content: Text('Privacy policy coming soon!')),
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
                              content: Text('Help & support coming soon!')),
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
                            child: Icon(Icons.nfc,
                                color: theme.colorScheme.onPrimary),
                          ),
                          children: [
                            const Text(
                                'A modern NFC-enabled loyalty points system for small businesses.'),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // --- ACCOUNT SETTINGS ---
                    Text('Account',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    _buildSettingsItem(
                      context,
                      icon: Icons.copy_all,
                      title: 'Export Data',
                      subtitle: 'Copy account data to clipboard',
                      onTap: _exportAccountData,
                    ),

                    _buildSettingsItem(
                      context,
                      icon: Icons.delete_outline,
                      title: 'Delete Account',
                      subtitle: 'Permanently remove your data',
                      onTap: _confirmDeleteAccount,
                    ),

                    const SizedBox(height: 32),

                    // Logout
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: const Text('Logout',
                            style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
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
              color: theme.colorScheme.onSurface.withOpacity(0.7),
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
            color: theme.colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}
