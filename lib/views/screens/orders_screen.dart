import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock_data.dart';
import '../../controllers/app_controller.dart';
import '../../controllers/providers.dart';
import '../../core/responsive.dart';
import '../../theme.dart';
import '../widgets/common.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: responsivePageInsets(context, top: 8),
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
                Expanded(child: Text('Your orders', style: AppText.display(size: 20))),
              ],
            ),
            const SizedBox(height: 2),
            Text('Track live orders, table bookings & reorder favourites',
                style: AppText.body(size: 12.5, weight: FontWeight.w500, color: AppColors.bodyGrey)),
            const SizedBox(height: 16),
            DeliveryDiningToggle(
              isDelivery: app.ordersTab == 'delivery',
              onDelivery: app.setOrdersDelivery,
              onDining: app.setOrdersDining,
            ),
            const SizedBox(height: 20),
            if (app.ordersTab == 'delivery') _DeliveryTab(app: app) else _DiningTab(app: app),
          ],
        ),
      ),
    );
  }
}

class _DeliveryTab extends StatelessWidget {
  final AppController app;
  const _DeliveryTab({required this.app});

  @override
  Widget build(BuildContext context) {
    final rest = app.restaurant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (app.hasCart) ...[
          Text('ACTIVE', style: AppText.body(size: 12, weight: FontWeight.w700, color: AppColors.bodyGrey, letterSpacing: 1)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => app.push('tracking'),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: const BoxDecoration(gradient: AppColors.accentGradient),
                    child: Row(
                      children: [
                        Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFFB9F0C8), shape: BoxShape.circle)),
                        const SizedBox(width: 7),
                        Text('ON THE WAY · 12 MIN', style: AppText.body(size: 12, weight: FontWeight.w800, color: Colors.white)),
                        const Spacer(),
                        Text('Track ›', style: AppText.body(size: 12, weight: FontWeight.w700, color: AppColors.goldLight)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(borderRadius: BorderRadius.circular(12), child: FoodImage(photoKey: rest.photoKey, width: 56, height: 56)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(rest.name, style: AppText.body(size: 15, weight: FontWeight.w700)),
                              Text('Chicken Dum Biryani, Gulab Jamun', maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: AppText.body(size: 12, weight: FontWeight.w500, color: AppColors.bodyGrey)),
                              Text('₹${app.grandTotal}', style: AppText.body(size: 12.5, weight: FontWeight.w700)),
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
          const SizedBox(height: 22),
        ],
        Text('PAST ORDERS', style: AppText.body(size: 12, weight: FontWeight.w700, color: AppColors.bodyGrey, letterSpacing: 1)),
        const SizedBox(height: 10),
        ...pastOrders.map((o) {
          final r = restaurantById(o.restaurantId);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(borderRadius: BorderRadius.circular(12), child: FoodImage(photoKey: r.photoKey, width: 52, height: 52)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.name, style: AppText.body(size: 14.5, weight: FontWeight.w700)),
                          Text(o.items, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: AppText.body(size: 12, weight: FontWeight.w500, color: AppColors.bodyGrey)),
                          Text('${o.when} · ₹${o.total}', style: AppText.body(size: 12, weight: FontWeight.w500, color: AppColors.bodyGrey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => app.reorderPastOrder(o.id),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.accent, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('Reorder', style: AppText.body(size: 13, weight: FontWeight.w700, color: AppColors.accent)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => app.ratePastOrder(o.id, rating: o.rating > 0 ? o.rating : 5),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.chipBorder, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Rate · ', style: AppText.body(size: 13, weight: FontWeight.w700, color: AppColors.midGrey)),
                        const Icon(Icons.star_outline, size: 13, color: AppColors.midGrey),
                        const SizedBox(width: 4),
                        Text('${o.rating}', style: AppText.body(size: 13, weight: FontWeight.w700, color: AppColors.midGrey)),
                      ],
                    ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _DiningTab extends StatelessWidget {
  final AppController app;
  const _DiningTab({required this.app});

  @override
  Widget build(BuildContext context) {
    if (app.bookings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today_outlined, size: 56, color: Color(0xFFD9CEC6)),
              const SizedBox(height: 16),
              Text('No table bookings yet', style: AppText.display(size: 17)),
              const SizedBox(height: 6),
              Text('Book a table from Dining Out to see it here', textAlign: TextAlign.center,
                  style: AppText.body(size: 13, weight: FontWeight.w500, color: AppColors.bodyGrey)),
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: app.toDining,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.accent, width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Explore dining out', style: AppText.body(size: 13.5, weight: FontWeight.w700, color: AppColors.accent)),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('UPCOMING', style: AppText.body(size: 12, weight: FontWeight.w700, color: AppColors.bodyGrey, letterSpacing: 1)),
        const SizedBox(height: 10),
        ...app.bookings.map((b) {
          final r = restaurantById(b.restaurantId);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(borderRadius: BorderRadius.circular(12), child: FoodImage(photoKey: r.photoKey, width: 52, height: 52)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.name, style: AppText.body(size: 14.5, weight: FontWeight.w700)),
                            Text(r.cuisines, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: AppText.body(size: 12, weight: FontWeight.w500, color: AppColors.bodyGrey)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 12, color: AppColors.accent),
                                const SizedBox(width: 5),
                                Text('${b.when} · ${b.guests}', style: AppText.body(size: 11.5, weight: FontWeight.w700, color: AppColors.accent)),
                              ],
                            ),
                            if (b.feePaid > 0) ...[
                              const SizedBox(height: 3),
                              Text('Booking fee ₹${b.feePaid} paid', style: AppText.body(size: 11, weight: FontWeight.w600, color: AppColors.bodyGrey)),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.greenPaleBg, borderRadius: BorderRadius.circular(8)),
                        child: Text('CONFIRMED', style: AppText.body(size: 10, weight: FontWeight.w800, color: AppColors.greenDarkText)),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  color: const Color(0xFFFBF6FA),
                  child: Row(
                    children: [
                      const Icon(Icons.confirmation_number_outlined, size: 15, color: AppColors.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Flat 25% off on your total bill · Booking ${b.id}',
                            style: AppText.body(size: 11.5, weight: FontWeight.w700, color: AppColors.accent)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
