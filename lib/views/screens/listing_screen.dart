import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/providers.dart';
import '../../core/responsive.dart';
import '../../theme.dart';
import '../widgets/common.dart';

class ListingScreen extends ConsumerWidget {
  const ListingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final visible = app.visibleRestaurants;
    final pad = AppResponsive.of(context).pagePadding;
    final dock = AppResponsive.of(context).dockClearance;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(pad, 2, pad, 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: app.back,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.cardBorder, width: 1.5)),
                    child: const Icon(Icons.arrow_back_ios_new, size: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Restaurants', style: AppText.display(size: 18)),
                    Text('Delivering to Banjara Hills', style: AppText.body(size: 12, weight: FontWeight.w500, color: AppColors.bodyGrey)),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 56,
            child: ListView(
              padding: EdgeInsets.fromLTRB(pad, 6, pad, 12),
              scrollDirection: Axis.horizontal,
              children: [
                FzFilterChip(
                  label: 'Sort',
                  filled: app.sortByRating,
                  leading: Icon(Icons.sort, size: 14, color: app.sortByRating ? Colors.white : null),
                  onTap: app.toggleSortByRating,
                ),
                const SizedBox(width: 9),
                FzFilterChip(
                  label: 'Fast delivery',
                  filled: app.fastDeliveryOnly,
                  onTap: app.toggleFastDelivery,
                ),
                const SizedBox(width: 9),
                FzFilterChip(
                  label: 'Pure Veg',
                  filled: app.vegOnly,
                  leading: app.vegOnly ? null : const VegDot(veg: true),
                  onTap: app.toggleVegOnly,
                ),
                const SizedBox(width: 9),
                FzFilterChip(
                  label: 'Rating 4.0+',
                  filled: app.minRating4,
                  onTap: app.toggleMinRating4,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(pad, 0, pad, dock),
              itemCount: visible.length,
              itemBuilder: (context, i) {
                final r = visible[i];
                final closed = !r.isOpen;
                return GestureDetector(
                  onTap: () => app.openRest(r.id),
                  child: Opacity(
                    opacity: closed ? 0.62 : 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.hairline))),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 106,
                            height: 106,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Grayscale(
                                    enabled: closed,
                                    child: FoodImage(photoKey: r.photoKey, width: 106, height: 106),
                                  ),
                                ),
                                if (closed)
                                  const Positioned(left: 7, bottom: 6, child: ClosedBadge())
                                else
                                  Positioned(
                                    left: 7,
                                    bottom: 6,
                                    child: Text(r.offer, style: AppText.body(size: 10.5, weight: FontWeight.w800, color: AppColors.goldLight)),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(r.name, style: AppText.body(size: 16, weight: FontWeight.w700))),
                                    RatingPill(rating: r.rating),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  closed ? 'Closed now' : r.cuisines,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.body(size: 12.5, weight: FontWeight.w500, color: AppColors.bodyGrey),
                                ),
                                const SizedBox(height: 2),
                                Text('${r.time} · ${r.dist}', style: AppText.body(size: 12.5, weight: FontWeight.w500, color: AppColors.bodyGrey)),
                                const SizedBox(height: 6),
                                Text(r.price, style: AppText.body(size: 12, weight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
