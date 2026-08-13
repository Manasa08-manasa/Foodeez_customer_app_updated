import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../controllers/providers.dart';
import '../../core/responsive.dart';
import '../../theme.dart';
import '../widgets/common.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  final Map<String, GlobalKey> _sectionKeys = {};

  void _jumpToSection(String section) {
    Navigator.of(context).pop();
    final key = _sectionKeys[section];
    final ctx = key?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0,
      );
    }
  }

  void _openMenuJumpSheet(List<MapEntry<String, List<MenuItem>>> sections) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(AppResponsive.of(context).pagePadding, 10, AppResponsive.of(context).pagePadding, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.chipBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('Menu', style: AppText.display(size: 18)),
                const SizedBox(height: 6),
                ...sections.map((sec) {
                  return InkWell(
                    onTap: () => _jumpToSection(sec.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.hairline),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            sec.key,
                            style: AppText.body(
                              size: 15,
                              weight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${sec.value.length} items',
                            style: AppText.body(
                              size: 12.5,
                              weight: FontWeight.w500,
                              color: AppColors.bodyGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    final rest = app.restaurant;
    final sections = app.filteredMenuSections;
    for (final sec in sections) {
      _sectionKeys.putIfAbsent(sec.key, () => GlobalKey());
    }

    final closed = !rest.isOpen;
    final description = rest.description.isNotEmpty
        ? rest.description
        : (rest.address.isNotEmpty ? rest.address : '');

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 96),
          child: Grayscale(
            enabled: closed,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 180,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      FoodImage(
                        photoKey: rest.photoKey,
                        width: double.infinity,
                        height: 180,
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x4D000000),
                              Colors.transparent,
                              Color(0x59000000),
                            ],
                            stops: [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),
                      SafeArea(
                        bottom: false,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CircleIconButton(
                                  icon: Icons.arrow_back_ios_new,
                                  onTap: app.back,
                                ),
                                Row(
                                  children: [
                                    CircleIconButton(
                                      icon: app.isFavoriteRestaurant(rest.id)
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      iconColor: AppColors.accent,
                                      onTap: () =>
                                          app.toggleFavoriteRestaurant(rest.id),
                                    ),
                                    const SizedBox(width: 10),
                                    const CircleIconButton(
                                      icon: Icons.share,
                                      iconColor: AppColors.accent,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -26),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.cardBorder),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 30,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rest.name,
                          style: AppText.display(size: 21, letterSpacing: -0.3),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rest.cuisines,
                          style: AppText.body(
                            size: 13,
                            weight: FontWeight.w500,
                            color: AppColors.bodyGrey,
                          ),
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: AppText.body(
                              size: 12.5,
                              weight: FontWeight.w500,
                              color: AppColors.bodyGrey,
                              height: 1.4,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.paleWarmBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              _Stat(
                                top: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      rest.rating > 0
                                          ? rest.rating.toStringAsFixed(1)
                                          : '—',
                                      style: AppText.body(
                                        size: 15,
                                        weight: FontWeight.w800,
                                        color: AppColors.green,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.star_outline,
                                      color: AppColors.green,
                                      size: 14,
                                    ),
                                  ],
                                ),
                                topColor: AppColors.green,
                                bottom: 'Rating',
                              ),
                              const _StatDivider(),
                              _Stat(
                                top: Text(
                                  rest.time,
                                  style: AppText.body(
                                    size: 15,
                                    weight: FontWeight.w800,
                                  ),
                                ),
                                bottom: 'Delivery',
                              ),
                              const _StatDivider(),
                              _Stat(
                                top: Text(
                                  rest.price,
                                  style: AppText.body(
                                    size: 15,
                                    weight: FontWeight.w800,
                                  ),
                                ),
                                bottom: 'For two',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (closed)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1ECE8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.schedule,
                                  color: AppColors.midGrey,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'This restaurant is currently closed',
                                    style: AppText.body(
                                      size: 13,
                                      weight: FontWeight.w700,
                                      color: AppColors.midGrey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (rest.offer.isNotEmpty)
                          DashedRect(
                            borderColor: AppColors.dashedOfferBorder,
                            fillColor: AppColors.dashedOfferBg,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.bolt,
                                  color: AppColors.gold,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    rest.offer,
                                    style: AppText.body(
                                      size: 13,
                                      weight: FontWeight.w700,
                                      color: AppColors.offerTextBrown,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // All / Veg / Non Veg — website parity
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      FzFilterChip(
                        label: 'All',
                        filled: app.menuVegFilter == 'all',
                        onTap: () => app.setMenuVegFilter('all'),
                      ),
                      const SizedBox(width: 8),
                      FzFilterChip(
                        label: 'Veg',
                        filled: app.menuVegFilter == 'veg',
                        leading: const VegDot(veg: true),
                        onTap: () => app.setMenuVegFilter('veg'),
                      ),
                      const SizedBox(width: 8),
                      FzFilterChip(
                        label: 'Non Veg',
                        filled: app.menuVegFilter == 'nonveg',
                        leading: const VegDot(veg: false),
                        onTap: () => app.setMenuVegFilter('nonveg'),
                      ),
                    ],
                  ),
                ),

                // Category chips from API sections
                if (sections.isNotEmpty)
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      scrollDirection: Axis.horizontal,
                      itemCount: sections.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final name = sections[i].key;
                        return FzFilterChip(
                          label: name,
                          filled: false,
                          onTap: () {
                            final key = _sectionKeys[name];
                            final ctx = key?.currentContext;
                            if (ctx != null) {
                              Scrollable.ensureVisible(
                                ctx,
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeInOut,
                                alignment: 0.05,
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),

                if (app.menuLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    ),
                  )
                else if (sections.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 40,
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.restaurant_menu_outlined,
                            size: 40,
                            color: Color(0xFFD9CEC6),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            app.menuVegFilter == 'all'
                                ? 'No menu items found'
                                : 'No items match this filter',
                            style: AppText.body(
                              size: 13.5,
                              weight: FontWeight.w600,
                              color: AppColors.bodyGrey,
                            ),
                          ),
                          if (app.menuVegFilter != 'all') ...[
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () => app.setMenuVegFilter('all'),
                              child: Text(
                                'Show all',
                                style: AppText.body(
                                  size: 13,
                                  weight: FontWeight.w700,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                else
                  Transform.translate(
                    offset: const Offset(0, -8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: sections.map((sec) {
                        return Column(
                          key: _sectionKeys[sec.key],
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                              child: Text(
                                sec.key,
                                style: AppText.display(size: 16),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                children: sec.value
                                    .map(
                                      (it) => _MenuItemRow(
                                        item: it,
                                        disabled: closed || it.isOutOfStock,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (!closed && app.hasCart)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: GestureDetector(
              onTap: app.toCart,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.45),
                      blurRadius: 30,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${app.cartCount} item · ₹${app.grandTotal}',
                          style: AppText.body(
                            size: 14,
                            weight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'plus taxes',
                          style: AppText.body(
                            size: 11,
                            weight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'View Cart',
                          style: AppText.body(
                            size: 15,
                            weight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.goldLight,
                          size: 18,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (sections.isNotEmpty)
          Positioned(
            right: 16,
            bottom: app.hasCart ? 88 : 20,
            child: GestureDetector(
              onTap: () => _openMenuJumpSheet(sections),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.menu_book_outlined,
                      size: 16,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'MENU',
                      style: AppText.body(
                        size: 12.5,
                        weight: FontWeight.w800,
                        color: AppColors.accent,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final Widget top;
  final String bottom;
  final Color topColor;
  const _Stat({
    required this.top,
    required this.bottom,
    this.topColor = AppColors.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          DefaultTextStyle(
            style: AppText.body(
              size: 15,
              weight: FontWeight.w800,
              color: topColor,
            ),
            child: top,
          ),
          Text(
            bottom,
            style: AppText.body(
              size: 10.5,
              weight: FontWeight.w500,
              color: AppColors.bodyGrey,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 30, color: AppColors.chipBorder);
}

class _MenuItemRow extends ConsumerWidget {
  final MenuItem item;
  final bool disabled;
  const _MenuItemRow({required this.item, this.disabled = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final qty = app.qtyOf(item.id);
    final outOfStock = item.isOutOfStock;

    return Opacity(
      opacity: outOfStock ? 0.55 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.hairline)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      VegDot(veg: item.veg),
                      if (item.bestseller) ...[
                        const SizedBox(width: 7),
                        const Icon(
                          Icons.star,
                          size: 11,
                          color: AppColors.offerTextBrown,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'BESTSELLER',
                          style: AppText.body(
                            size: 10,
                            weight: FontWeight.w800,
                            color: AppColors.offerTextBrown,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                      if (outOfStock) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1ECE8),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'OUT OF STOCK',
                            style: AppText.body(
                              size: 9.5,
                              weight: FontWeight.w800,
                              color: AppColors.bodyGrey,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.name,
                    style: AppText.body(size: 15.5, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '₹${item.price}',
                    style: AppText.body(size: 14, weight: FontWeight.w700),
                  ),
                  if (item.ratingsCount.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_outline,
                          color: AppColors.green,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item.rating}',
                          style: AppText.body(
                            size: 11.5,
                            weight: FontWeight.w600,
                            color: AppColors.green,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${item.ratingsCount})',
                          style: AppText.body(
                            size: 11.5,
                            weight: FontWeight.w500,
                            color: AppColors.bodyGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (item.desc.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.desc,
                      style: AppText.body(
                        size: 12.5,
                        weight: FontWeight.w500,
                        color: AppColors.bodyGrey,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 118,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: FoodImage(
                      photoKey: item.photoKey,
                      width: 118,
                      height: 100,
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -16),
                    child: outOfStock
                        ? const _OutOfStockPill()
                        : (disabled
                            ? const _ClosedPill()
                            : (qty > 0
                                ? _Stepper(item: item, qty: qty)
                                : _AddButton(item: item))),
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

class _OutOfStockPill extends StatelessWidget {
  const _OutOfStockPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1ECE8),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.chipBorder, width: 1.5),
      ),
      child: Text(
        'OUT OF STOCK',
        style: AppText.body(
          size: 10.5,
          weight: FontWeight.w800,
          color: AppColors.bodyGrey,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _ClosedPill extends StatelessWidget {
  const _ClosedPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1ECE8),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.chipBorder, width: 1.5),
      ),
      child: Text(
        'CLOSED',
        style: AppText.body(
          size: 11.5,
          weight: FontWeight.w800,
          color: AppColors.bodyGrey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _AddButton extends ConsumerWidget {
  final MenuItem item;
  const _AddButton({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.read(appControllerProvider);
    return GestureDetector(
      onTap: () => app.add(item.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.accent, width: 1.5),
          borderRadius: BorderRadius.circular(11),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.2),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ADD',
              style: AppText.body(
                size: 14,
                weight: FontWeight.w800,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '+',
              style: AppText.body(
                size: 14,
                weight: FontWeight.w800,
                color: AppColors.gold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends ConsumerWidget {
  final MenuItem item;
  final int qty;
  const _Stepper({required this.item, required this.qty});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.read(appControllerProvider);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.accent, width: 1.5),
        borderRadius: BorderRadius.circular(11),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => app.sub(item.id),
            child: SizedBox(
              width: 34,
              height: 34,
              child: Center(
                child: Text(
                  '−',
                  style: AppText.body(
                    size: 20,
                    weight: FontWeight.w800,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 26,
            child: Center(
              child: Text(
                '$qty',
                style: AppText.body(
                  size: 15,
                  weight: FontWeight.w800,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => app.add(item.id),
            child: SizedBox(
              width: 34,
              height: 34,
              child: Center(
                child: Text(
                  '+',
                  style: AppText.body(
                    size: 20,
                    weight: FontWeight.w800,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
