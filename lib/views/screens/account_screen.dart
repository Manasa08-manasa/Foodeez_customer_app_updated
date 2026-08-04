import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/app_controller.dart';
import '../../data/app_repository.dart';
import '../../data/mock_data.dart';
import '../../controllers/providers.dart';
import '../../theme.dart';
import '../widgets/brand_logo.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    AppController app,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete account?'),
        content: const Text(
          'Do you want to delete your account? This will sign you out and take you to the login screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await app.deleteAccount();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.paleWarmBg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(22),
                    bottomRight: Radius.circular(22),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'My profile',
                            style: AppText.display(
                              size: 20,
                              color: Colors.white,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: app.toHome,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.home_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              userInitials,
                              style: AppText.display(
                                size: 18,
                                weight: FontWeight.w800,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.display(
                                    size: 15,
                                    color: Colors.white,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  userPhone.isNotEmpty
                                      ? userPhone
                                      : 'No phone added',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.body(
                                    size: 12,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                                Text(
                                  userEmail.isNotEmpty
                                      ? userEmail
                                      : 'No email added',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.body(
                                    size: 11.5,
                                    color: Colors.white.withValues(alpha: 0.75),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () async {
                              final updated = await showDialog<bool>(
                                context: context,
                                builder: (context) =>
                                    const _EditProfileDialog(),
                              );
                              if (updated == true) {
                                await AppRepository.syncProfile();
                                app.refreshAccount();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Edit',
                                style: AppText.body(
                                  size: 12,
                                  color: Colors.white,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick actions',
                      style: AppText.display(size: 14, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.hairline),
                      ),
                      child: Column(
                        children: [
                          _ProfileActionTile(
                            icon: Icons.receipt_long_outlined,
                            label: 'Your orders',
                            subtitle: 'Track recent deliveries',
                            onTap: app.toOrders,
                            showDivider: true,
                          ),
                          _ProfileActionTile(
                            icon: Icons.favorite_border,
                            label: 'Favourites',
                            subtitle: 'Saved restaurants and dishes',
                            onTap: () async {
                              await AppRepository.syncFavorites();
                              if (favoriteRestaurantIds.isNotEmpty) {
                                app.openRest(favoriteRestaurantIds.first);
                              } else {
                                app.toHome();
                              }
                            },
                            showDivider: true,
                          ),
                          _ProfileActionTile(
                            icon: Icons.badge_outlined,
                            label: 'Address book',
                            subtitle: 'Manage delivery addresses',
                            onTap: () async {
                              await AppRepository.syncAddresses();
                              app.push('address-book');
                            },
                            showDivider: true,
                          ),
                          _ProfileActionTile(
                            icon: Icons.credit_card,
                            label: 'Payments & wallet',
                            subtitle: 'View balance and transactions',
                            trailing: '₹$walletBalance',
                            onTap: app.toPayment,
                            showDivider: true,
                          ),
                          _ProfileActionTile(
                            icon: Icons.confirmation_number_outlined,
                            label: 'Coupons & offers',
                            subtitle: 'Apply discounts',
                            onTap: app.toCoupons,
                            showDivider: true,
                          ),
                          _ProfileActionTile(
                            icon: Icons.support_agent,
                            label: 'Help & support',
                            subtitle: 'Need assistance?',
                            onTap: app.toHelp,
                            showDivider: true,
                          ),
                          _ProfileActionTile(
                            icon: Icons.settings_outlined,
                            label: 'Settings',
                            subtitle: 'App preferences',
                            onTap: () {
                              AppRepository.syncSessions();
                            },
                            showDivider: true,
                          ),
                          _ProfileActionTile(
                            icon: Icons.delete_outline,
                            label: 'Delete account',
                            subtitle: 'Remove your account from this device',
                            danger: true,
                            showDivider: true,
                            onTap: () => _confirmDeleteAccount(context, app),
                          ),
                          _ProfileActionTile(
                            icon: Icons.logout,
                            label: 'Log out',
                            subtitle: 'Sign out of your account',
                            danger: true,
                            onTap: app.logout,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: Column(
                        children: [
                          Opacity(
                            opacity: 0.3,
                            child: const BrandLogo.mark(height: 24),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'TAP · EAT · REPEAT · v1.1.2',
                            style: AppText.body(
                              size: 10,
                              weight: FontWeight.w700,
                              color: AppColors.lightGreyText,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog();

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: userName);
    _emailController = TextEditingController(text: userEmail);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await AppRepository.updateProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Edit Profile',
                      style: AppText.display(size: 18, weight: FontWeight.w700),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: const Icon(
                      Icons.close,
                      size: 20,
                      color: AppColors.midGrey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Update your account details',
                style: AppText.body(size: 12.5, color: AppColors.bodyGrey),
              ),
              const SizedBox(height: 14),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.avatarBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.avatarBorder),
                ),
                alignment: Alignment.center,
                child: Text(
                  userInitials,
                  style: AppText.display(
                    size: 22,
                    weight: FontWeight.w800,
                    color: AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildProfileField(
                label: 'Full Name',
                controller: _nameController,
              ),
              const SizedBox(height: 10),
              _buildProfileField(
                label: 'Email Address',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Save Changes',
                          style: AppText.body(
                            size: 14,
                            weight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: AppText.body(
                    size: 13,
                    weight: FontWeight.w600,
                    color: AppColors.midGrey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppText.body(
            size: 10.5,
            weight: FontWeight.w700,
            color: AppColors.bodyGrey,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.avatarBg,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accent),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final String? trailing;
  final bool danger;
  final bool showDivider;

  const _ProfileActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.danger = false,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: danger
                        ? AppColors.red.withValues(alpha: 0.12)
                        : AppColors.avatarBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    color: danger ? AppColors.red : AppColors.ink,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppText.body(
                          size: 13.5,
                          weight: FontWeight.w700,
                          color: danger ? AppColors.red : AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(
                          size: 11.5,
                          color: AppColors.bodyGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      trailing!,
                      style: AppText.body(
                        size: 12.5,
                        weight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: danger ? AppColors.red : AppColors.midGrey,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            indent: 56,
            color: AppColors.hairline,
          ),
      ],
    );
  }
}
