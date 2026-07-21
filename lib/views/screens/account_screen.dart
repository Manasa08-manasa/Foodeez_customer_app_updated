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

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: responsivePageInsets(context, top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: app.toHome,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.cardBorder, width: 1.5)),
                    child: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.ink),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('My account', style: AppText.display(size: 20)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: AppColors.avatarBg, shape: BoxShape.circle, border: Border.all(color: AppColors.avatarBorder, width: 2)),
                  alignment: Alignment.center,
                  child: Text(userInitials, style: AppText.display(size: 24, color: AppColors.accent)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userName, style: AppText.display(size: 20)),
                      const SizedBox(height: 2),
                      Text('$userPhone · $userEmail', style: AppText.body(size: 13, weight: FontWeight.w500, color: AppColors.bodyGrey)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: Text('Edit', style: AppText.body(size: 13, weight: FontWeight.w700, color: AppColors.accent)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _Group(
              label: 'Food delivery',
              rows: [
                _RowData(Icons.receipt_long_outlined, 'Your orders', onTap: app.toOrders),
                _RowData(Icons.favorite_border, 'Favourites', onTap: () async {
                  await AppRepository.syncFavorites();
                  if (favoriteRestaurantIds.isNotEmpty) {
                    app.openRest(favoriteRestaurantIds.first);
                  } else {
                    app.toHome();
                  }
                }),
                _RowData(Icons.badge_outlined, 'Address book', onTap: () async {
                  await AppRepository.syncAddresses();
                  app.refreshAccount();
                }),
              ],
            ),
            _Group(
              label: 'Payments & offers',
              rows: [
                _RowData(Icons.credit_card, 'Payments & wallet', onTap: app.toPayment, trailing: '₹$walletBalance'),
                _RowData(Icons.confirmation_number_outlined, 'Coupons & offers', onTap: app.toCoupons),
              ],
            ),
            _Group(
              label: 'More',
              rows: [
                _RowData(Icons.support_agent, 'Help & support', onTap: app.toHelp),
                _RowData(Icons.settings_outlined, 'Settings', onTap: () {
                  AppRepository.syncSessions();
                }),
                _RowData(Icons.logout, 'Log out', onTap: app.logout, danger: true),
              ],
            ),

            const SizedBox(height: 28),
            Center(
              child: Column(
                children: [
                  Opacity(
                    opacity: 0.4,
                    child: const BrandLogo.mark(height: 32),
                  ),
                  const SizedBox(height: 8),
                  Text('TAP · EAT · REPEAT · v1.0',
                      style: AppText.body(size: 11, weight: FontWeight.w700, color: AppColors.lightGreyText, letterSpacing: 2)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RowData {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailing;
  final bool danger;
  _RowData(this.icon, this.label, {required this.onTap, this.trailing, this.danger = false});
}

class _Group extends StatelessWidget {
  final String label;
  final List<_RowData> rows;
  const _Group({required this.label, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 16, decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text(label, style: AppText.display(size: 15)),
            ],
          ),
          const SizedBox(height: 6),
          ...rows.asMap().entries.map((e) {
            final isLast = e.key == rows.length - 1;
            final r = e.value;
            return GestureDetector(
              onTap: r.onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.hairline))),
                child: Row(
                  children: [
                    Icon(r.icon, size: 22, color: r.danger ? AppColors.red : AppColors.midGrey),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(r.label, style: AppText.body(size: 15, weight: FontWeight.w600, color: r.danger ? AppColors.red : AppColors.ink)),
                    ),
                    if (r.trailing != null)
                      Text(r.trailing!, style: AppText.body(size: 13, weight: FontWeight.w700, color: AppColors.green))
                    else
                      const Icon(Icons.chevron_right, size: 20, color: Color(0xFFC6BCC2)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
