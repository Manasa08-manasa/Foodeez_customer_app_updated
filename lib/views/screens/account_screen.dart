import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/app_repository.dart';
import '../../data/mock_data.dart';
import '../../controllers/providers.dart';
import '../../core/responsive.dart';
import '../../theme.dart';
import '../widgets/brand_logo.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
  

    return Scaffold(
      backgroundColor: AppColors.paleWarmBg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('My profile', style: AppText.display(size: 24, color: Colors.white, weight: FontWeight.w700)),
                        ),
                        GestureDetector(
                          onTap: app.toHome,
                          child: const Icon(Icons.home_outlined, color: Colors.white, size: 24),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white30, width: 1.5),
                            ),
                            alignment: Alignment.center,
                            child: Text(userInitials, style: AppText.display(size: 26, weight: FontWeight.w800, color: AppColors.accent)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(userName, style: AppText.display(size: 18, color: Colors.white, weight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                Text(userPhone.isNotEmpty ? userPhone : 'No phone added', style: AppText.body(size: 13, color: Colors.white.withOpacity(0.92))),
                                const SizedBox(height: 4),
                                Text(userEmail.isNotEmpty ? userEmail : 'No email added', style: AppText.body(size: 13, color: Colors.white.withOpacity(0.8))),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final updated = await showDialog<bool>(
                                context: context,
                                builder: (context) => const _EditProfileDialog(),
                              );
                              if (updated == true) {
                                await AppRepository.syncProfile();
                                app.refreshAccount();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text('Edit', style: AppText.body(size: 13, color: Colors.white, weight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
            
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quick actions', style: AppText.display(size: 16, weight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    _ProfileActionTile(
                      icon: Icons.receipt_long_outlined,
                      label: 'Your orders',
                      subtitle: 'Track recent deliveries',
                      onTap: app.toOrders,
                    ),
                    const SizedBox(height: 12),
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
                    ),
                    const SizedBox(height: 12),
                    _ProfileActionTile(
                      icon: Icons.badge_outlined,
                      label: 'Address book',
                      subtitle: 'Manage delivery addresses',
                      onTap: () async {
                        await AppRepository.syncAddresses();
                        app.push('address-book');
                      },
                    ),
                    const SizedBox(height: 12),
                    _ProfileActionTile(
                      icon: Icons.credit_card,
                      label: 'Payments & wallet',
                      subtitle: 'View balance and transactions',
                      trailing: '₹$walletBalance',
                      onTap: app.toPayment,
                    ),
                    const SizedBox(height: 12),
                    _ProfileActionTile(
                      icon: Icons.confirmation_number_outlined,
                      label: 'Coupons & offers',
                      subtitle: 'Apply discounts',
                      onTap: app.toCoupons,
                    ),
                    const SizedBox(height: 12),
                    _ProfileActionTile(
                      icon: Icons.support_agent,
                      label: 'Help & support',
                      subtitle: 'Need assistance?',
                      onTap: app.toHelp,
                    ),
                    const SizedBox(height: 12),
                    _ProfileActionTile(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      subtitle: 'App preferences',
                      onTap: () {
                        AppRepository.syncSessions();
                      },
                    ),
                    const SizedBox(height: 12),
                    _ProfileActionTile(
                      icon: Icons.logout,
                      label: 'Log out',
                      subtitle: 'Sign out of your account',
                      danger: true,
                      onTap: app.logout,
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          Opacity(opacity: 0.35, child: const BrandLogo.mark(height: 32)),
                          const SizedBox(height: 8),
                          Text('TAP · EAT · REPEAT · v1.0', style: AppText.body(size: 11, weight: FontWeight.w700, color: AppColors.lightGreyText, letterSpacing: 2)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Edit Profile', style: AppText.display(size: 22, weight: FontWeight.w700)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: const Icon(Icons.close, size: 22, color: AppColors.midGrey),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Personalize your dining experience',
                style: AppText.body(size: 13, color: AppColors.bodyGrey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: AppColors.avatarBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.avatarBorder, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(userInitials, style: AppText.display(size: 28, weight: FontWeight.w800, color: AppColors.accent)),
              ),
              const SizedBox(height: 24),
              _buildProfileField(label: 'Full Name', controller: _nameController),
              const SizedBox(height: 14),
              _buildProfileField(label: 'Email Address', controller: _emailController, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Save Changes', style: AppText.body(size: 15, weight: FontWeight.w700, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: AppText.body(size: 14, weight: FontWeight.w700, color: AppColors.midGrey)),
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
        Text(label.toUpperCase(), style: AppText.body(size: 11, weight: FontWeight.w700, color: AppColors.bodyGrey, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.avatarBg,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: AppColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: AppColors.accent),
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

  const _ProfileActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: danger ? AppColors.red.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: danger ? AppColors.red.withOpacity(0.14) : AppColors.avatarBg,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: danger ? AppColors.red : AppColors.ink, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppText.body(size: 15, weight: FontWeight.w700, color: danger ? AppColors.red : AppColors.ink)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppText.body(size: 13, color: AppColors.bodyGrey)),
                ],
              ),
            ),
            if (trailing != null)
              Text(trailing!, style: AppText.body(size: 13, weight: FontWeight.w700, color: AppColors.ink))
            else
              Icon(Icons.chevron_right, color: danger ? AppColors.red : AppColors.midGrey, size: 20),
          ],
        ),
      ),
    );
  }
}
