import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../controllers/providers.dart';
import '../../core/responsive.dart';
import '../../theme.dart';
import '../widgets/common.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  List<Restaurant> _results = const [];
  bool _searching = false;
  String _query = '';

  Future<void> _runSearch(String q) async {
    final query = q.trim();
    if (query.isEmpty) {
      setState(() {
        _query = '';
        _results = const [];
      });
      return;
    }
    setState(() {
      _searching = true;
      _query = query;
    });
    final app = ref.read(appControllerProvider);
    final hits = await app.searchRestaurants(query);
    if (!mounted) return;
    setState(() {
      _results = hits;
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    final recent = popularDishNames.isNotEmpty
        ? popularDishNames.take(6).toList()
        : const ['Biryani', 'Cold coffee', 'Paradise'];
    final trending = trendingRestaurantIds.isNotEmpty
        ? restaurants.where((r) => trendingRestaurantIds.contains(r.id)).toList()
        : restaurants;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: responsivePageInsets(context, top: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: app.back,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.cardBorder, width: 1.5)),
                    child: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.ink),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text('Search', style: AppText.display(size: 20))),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F4F0),
                border: Border.all(color: AppColors.cardBorder, width: 1.5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppColors.accent, size: 19),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      autofocus: false,
                      style: AppText.body(size: 14.5, weight: FontWeight.w600),
                      textInputAction: TextInputAction.search,
                      onSubmitted: _runSearch,
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Restaurant name or a dish',
                        hintStyle: AppText.body(size: 14.5, weight: FontWeight.w600),
                      ),
                    ),
                  ),
                  if (_searching)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            if (_query.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                _results.isEmpty ? 'No results for “$_query”' : 'Results for “$_query”',
                style: AppText.display(size: 15),
              ),
              const SizedBox(height: 10),
              ..._results.map((r) => _RestaurantHit(
                    restaurant: r,
                    onTap: () => app.openRest(r.id),
                  )),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 4),
            Text('Recent searches', style: AppText.display(size: 15)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: recent.map((s) {
                return GestureDetector(
                  onTap: () => _runSearch(s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.chipBorder, width: 1.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.history, size: 13, color: AppColors.bodyGrey),
                        const SizedBox(width: 6),
                        Text(s, style: AppText.body(size: 13, weight: FontWeight.w600, color: AppColors.midGrey)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text('Popular cuisines', style: AppText.display(size: 15)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: AppResponsive.of(context).gridColumns(phone: 2, tablet: 3, large: 4),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.6,
              children: categories.map((c) {
                return GestureDetector(
                  onTap: () => _runSearch(c.name),
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.cardBorder),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FoodImage(photoKey: c.photoKey, width: 46, height: 46),
                        ),
                        const SizedBox(width: 12),
                        Flexible(child: Text(c.name, style: AppText.body(size: 13.5, weight: FontWeight.w700))),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.local_fire_department, color: AppColors.accent, size: 17),
                const SizedBox(width: 7),
                Text('Trending near you', style: AppText.display(size: 15)),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              children: trending.map((r) {
                return GestureDetector(
                  onTap: () => app.openRest(r.id),
                  child: Opacity(
                    opacity: r.isOpen ? 1 : 0.6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.hairline))),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: FoodImage(photoKey: r.photoKey, width: 52, height: 52),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.name, style: AppText.body(size: 14.5, weight: FontWeight.w700)),
                                Text(r.cuisines,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.body(size: 12, weight: FontWeight.w500, color: AppColors.bodyGrey)),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_outline, size: 12.5, color: AppColors.accent),
                              const SizedBox(width: 4),
                              Text(r.rating.toStringAsFixed(1),
                                  style: AppText.body(size: 12.5, weight: FontWeight.w700, color: AppColors.accent)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestaurantHit extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;
  const _RestaurantHit({required this.restaurant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: FoodImage(photoKey: restaurant.photoKey, width: 48, height: 48),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(restaurant.name, style: AppText.body(size: 14, weight: FontWeight.w700)),
                  Text(restaurant.cuisines,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(size: 12, weight: FontWeight.w500, color: AppColors.bodyGrey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
