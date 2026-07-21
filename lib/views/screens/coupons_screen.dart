import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../controllers/app_controller.dart';
import '../../controllers/providers.dart';
import '../../core/responsive.dart';
import '../../theme.dart';

/// Account-level "browse all coupons" screen — shown independent of any
/// active cart. Foodeez-wide offers are grouped separately from
/// restaurant-issued ones, since a restaurant's own coupon only makes sense
/// once you know which restaurant it's for.
class CouponsScreen extends ConsumerWidget {
  const CouponsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.read(appControllerProvider);
    final globalCoupons = coupons.where((c) => c.scope == CouponScope.global).toList();
    final restaurantCoupons = coupons.where((c) => c.scope == CouponScope.restaurant).toList();

    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            color: Colors.white,
            child: Row(
              children: [
                GestureDetector(
                  onTap: app.back,
                  child: const Icon(Icons.arrow_back, size: 22, color: AppColors.ink),
                ),
                const SizedBox(width: 16),
                Text('Coupons & offers', style: AppText.display(size: 19)),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            color: const Color(0xFFF2EFEC),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              children: [
                Text('FOODEEZ OFFERS', style: AppText.body(size: 12, weight: FontWeight.w700, color: AppColors.bodyGrey, letterSpacing: 1)),
                const SizedBox(height: 10),
                ...globalCoupons.map((c) => _CouponCard(coupon: c, app: app)),
                const SizedBox(height: 22),
                Text('RESTAURANT OFFERS', style: AppText.body(size: 12, weight: FontWeight.w700, color: AppColors.bodyGrey, letterSpacing: 1)),
                const SizedBox(height: 10),
                ...restaurantCoupons.map((c) => _CouponCard(coupon: c, app: app)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CouponCard extends StatelessWidget {
  final Coupon coupon;
  final AppController app;
  const _CouponCard({required this.coupon, required this.app});

  @override
  Widget build(BuildContext context) {
    final restaurantOnly = coupon.scope == CouponScope.restaurant;
    final scopeText = restaurantOnly
        ? 'Valid only at ${coupon.issuedBy}'
        : coupon.restaurantIds.isEmpty
            ? 'Valid at all restaurants'
            : 'Valid at ${coupon.restaurantIds.map((id) => restaurantById(id).name).join(', ')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: AppColors.avatarBg, shape: BoxShape.circle),
                child: const Icon(Icons.local_offer_outlined, size: 16, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(coupon.code, style: AppText.body(size: 14.5, weight: FontWeight.w800)),
                    Text(coupon.title, style: AppText.body(size: 13, weight: FontWeight.w700, color: AppColors.accent)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.avatarBg, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  restaurantOnly ? 'By ${coupon.issuedBy}' : 'Foodeez',
                  style: AppText.body(size: 10, weight: FontWeight.w700, color: AppColors.accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(coupon.subtitle, style: AppText.body(size: 12.5, weight: FontWeight.w500, color: AppColors.ink)),
          const SizedBox(height: 3),
          Text(
            coupon.minOrderValue > 0 ? '$scopeText · min order ₹${coupon.minOrderValue}' : scopeText,
            style: AppText.body(size: 11.5, weight: FontWeight.w500, color: AppColors.bodyGrey),
          ),
          if (restaurantOnly) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => app.openRest(coupon.restaurantIds.first),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.accent, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Order from ${coupon.issuedBy}', style: AppText.body(size: 12.5, weight: FontWeight.w700, color: AppColors.accent)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
