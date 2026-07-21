import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../controllers/providers.dart';
import '../../core/responsive.dart';
import '../../services/api_config.dart';
import '../../theme.dart';
import '../widgets/common.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final openRestaurants = restaurants.where((r) => r.isOpen).toList();
    final banners = openRestaurants.take(4).toList();
    final visible = app.visibleRestaurants;
    final pad = AppResponsive.of(context).pagePadding;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: AppResponsive.of(context).dockClearance),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // header
            Padding(
              padding: EdgeInsets.fromLTRB(pad, 6, pad, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: app.refreshLocationAndNearby,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('Home', style: AppText.display(size: 17)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.accent),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ApiConfig.locationReady
                                    ? ApiConfig.locationLabel
                                    : shortAddress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.body(size: 12.5, weight: FontWeight.w500, color: AppColors.bodyGrey),
                              ),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: app.toAccount,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.avatarBg,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.avatarBorder, width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(userInitials, style: AppText.body(size: 15, weight: FontWeight.w800, color: AppColors.accent)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DeliveryDiningToggle(
                    isDelivery: true,
                    onDelivery: () {},
                    onDining: app.toDining,
                  ),
                ],
              ),
            ),

            // search bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: pad),
              child: GestureDetector(
                onTap: app.toSearch,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.cardBorder, width: 1.5),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: AppColors.accentDeep.withValues(alpha: 0.15), blurRadius: 28, offset: const Offset(0, 12))],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: AppColors.accent, size: 19),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text('Search "biryani", "pizza"…', style: AppText.body(size: 14.5, weight: FontWeight.w500, color: AppColors.lightGreyText)),
                      ),
                      const Icon(Icons.mic_none, color: AppColors.accent, size: 18),
                    ],
                  ),
                ),
              ),
            ),

            // banners
            SizedBox(
              height: 168,
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(pad, 18, pad, 8),
                scrollDirection: Axis.horizontal,
                itemCount: banners.length,
                separatorBuilder: (context, _) => const SizedBox(width: 14),
                itemBuilder: (context, i) => _BannerCard(restaurant: banners[i]),
              ),
            ),

            const SectionTitle('Sponsored', padding: EdgeInsets.fromLTRB(20, 4, 20, 4)),
            SizedBox(
              height: 178,
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(pad, 8, pad, 12),
                scrollDirection: Axis.horizontal,
                itemCount: promoAds.length,
                separatorBuilder: (context, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) => PromoAdCard(ad: promoAds[i], width: 240),
              ),
            ),

            const SectionTitle("What's on your mind?"),
            SizedBox(
              height: 134,
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(pad, 12, pad, 18),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (context, _) => const SizedBox(width: 15),
                itemBuilder: (context, i) => _CategoryTile(category: categories[i], onTap: app.toList),
              ),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(pad, 6, pad, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Top picks near you', style: AppText.display(size: 18)),
                  GestureDetector(
                    onTap: app.toList,
                    child: Text('See all →', style: AppText.body(size: 13, weight: FontWeight.w700, color: AppColors.accent)),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 250,
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(pad, 12, pad, 20),
                scrollDirection: Axis.horizontal,
                itemCount: openRestaurants.length,
                separatorBuilder: (context, _) => const SizedBox(width: 14),
                itemBuilder: (context, i) => _TopPickCard(restaurant: openRestaurants[i], onTap: () => app.openRest(openRestaurants[i].id)),
              ),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(pad, 8, pad, 2),
              child: Text('${visible.length} restaurants around you', style: AppText.display(size: 18)),
            ),
            SizedBox(
              height: 60,
              child: ListView(
                padding: EdgeInsets.fromLTRB(pad, 8, pad, 8),
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

            if (visible.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: pad, vertical: 30),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.search_off, size: 40, color: Color(0xFFD9CEC6)),
                      const SizedBox(height: 10),
                      Text('No restaurants match these filters', style: AppText.body(size: 13.5, weight: FontWeight.w600, color: AppColors.bodyGrey)),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: EdgeInsets.symmetric(horizontal: pad),
                child: Column(
                  children: visible.map((r) => _RestaurantRow(restaurant: r, onTap: () => app.openRest(r.id))).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BannerCard extends ConsumerWidget {
  final Restaurant restaurant;
  const _BannerCard({required this.restaurant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.read(appControllerProvider);
    return GestureDetector(
      onTap: () => app.openRest(restaurant.id),
      child: Container(
        width: 288,
        height: 152,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColors.accentDeep.withValues(alpha: 0.25), blurRadius: 28, offset: const Offset(0, 14))],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            FoodImage(photoKey: restaurant.photoKey, width: 288, height: 152),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x1F0A0408), Color(0xD7140A0E)],
                  stops: [0.28, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 14,
              top: 13,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(20)),
                child: Text(restaurant.offer, style: AppText.body(size: 11, weight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3)),
              ),
            ),
            Positioned(
              left: 15,
              right: 15,
              bottom: 13,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(restaurant.name, style: AppText.display(size: 20, color: Colors.white, letterSpacing: -0.3)),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      RatingPill(rating: restaurant.rating),
                      const SizedBox(width: 8),
                      Text(restaurant.time, style: AppText.body(size: 12, weight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.92))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;
  const _CategoryTile({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 66,
        child: Column(
          children: [
            Container(
              width: 66,
              height: 66,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.categoryBorder),
              ),
              child: FoodImage(photoKey: category.photoKey, width: 66, height: 66),
            ),
            const SizedBox(height: 7),
            Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: AppText.body(size: 11.5, weight: FontWeight.w600, color: AppColors.midGrey, height: 1.15),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopPickCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;
  const _TopPickCard({required this.restaurant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 194,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 124,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: FoodImage(photoKey: restaurant.photoKey, width: 194, height: 124),
                  ),
                  Positioned(
                    left: 9,
                    bottom: 9,
                    child: Text(restaurant.offer, style: AppText.body(size: 13, weight: FontWeight.w800, color: AppColors.goldLight)),
                  ),
                  Positioned(
                    right: 9,
                    top: 9,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), shape: BoxShape.circle),
                      child: const Icon(Icons.favorite_border, size: 15, color: AppColors.accent),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(height: 42,child: Text(restaurant.name,maxLines: 2,overflow: TextOverflow.ellipsis,style: AppText.body(size: 15,weight: FontWeight.w700,),),),
            const SizedBox(height: 3),
            Row(
              children: [
                RatingPill(rating: restaurant.rating),
                const SizedBox(width: 8),
                Text(restaurant.time, style: AppText.body(size: 12, weight: FontWeight.w600, color: const Color(0xFF6C636A))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RestaurantRow extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;
  const _RestaurantRow({required this.restaurant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final closed = !restaurant.isOpen;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: closed ? 0.62 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.hairline))),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Grayscale(
                        enabled: closed,
                        child: FoodImage(photoKey: restaurant.photoKey, width: 100, height: 100),
                      ),
                    ),
                    if (closed)
                      const Positioned(left: 6, bottom: 6, child: ClosedBadge()),
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
                        Expanded(child: Text(restaurant.name, style: AppText.body(size: 16, weight: FontWeight.w700))),
                        RatingPill(rating: restaurant.rating),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(restaurant.cuisines, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: AppText.body(size: 12.5, weight: FontWeight.w500, color: AppColors.bodyGrey)),
                    const SizedBox(height: 2),
                    Text('${restaurant.time} · ${restaurant.price}', style: AppText.body(size: 12.5, weight: FontWeight.w500, color: AppColors.bodyGrey)),
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.only(top: 8),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Color(0xFFE9E1DC), width: 1, style: BorderStyle.solid)),
                      ),
                      child: closed
                          ? Row(
                              children: [
                                const Icon(Icons.schedule, size: 14, color: AppColors.bodyGrey),
                                const SizedBox(width: 6),
                                Text('Closed now', style: AppText.body(size: 12, weight: FontWeight.w700, color: AppColors.bodyGrey)),
                              ],
                            )
                          : Row(
                              children: [
                                const Icon(Icons.bolt, size: 14, color: AppColors.gold),
                                const SizedBox(width: 6),
                                Text(restaurant.offer, style: AppText.body(size: 12, weight: FontWeight.w700, color: AppColors.offerTextBrown)),
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
