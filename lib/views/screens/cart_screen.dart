import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../controllers/app_controller.dart';
import '../../controllers/providers.dart';
import '../../core/responsive.dart';
import '../../theme.dart';
import '../widgets/common.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final rest = app.restaurant;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(AppResponsive.of(context).pagePadding, 6, AppResponsive.of(context).pagePadding, 14),
            decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppColors.hairline))),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rest.name, style: AppText.display(size: 18)),
                      Text('Delivery to Home · ${rest.time}', style: AppText.body(size: 12, weight: FontWeight.w500, color: AppColors.bodyGrey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: app.cartEmpty ? const _EmptyCart() : _CartBody(app: app),
          ),
        ],
      ),
    );
  }
}

class _EmptyCart extends ConsumerWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.read(appControllerProvider);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 64, color: Color(0xFFD9CEC6)),
            const SizedBox(height: 16),
            Text('Your cart is empty', style: AppText.display(size: 18)),
            const SizedBox(height: 6),
            Text('Add items from a restaurant to get started', textAlign: TextAlign.center,
                style: AppText.body(size: 13, weight: FontWeight.w500, color: AppColors.bodyGrey)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: app.toHome,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Browse restaurants', style: AppText.body(size: 14, weight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartBody extends ConsumerStatefulWidget {
  final AppController app;
  const _CartBody({required this.app});

  @override
  ConsumerState<_CartBody> createState() => _CartBodyState();
}

class _CartBodyState extends ConsumerState<_CartBody> {
  AppController get app => widget.app;

  Future<void> _checkout() async {
    await app.placeOrder();
    if (!mounted) return;
    final err = app.checkoutError;
    if (err != null && err.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lines = app.cartLines;
    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(AppResponsive.of(context).pagePadding, 16, AppResponsive.of(context).pagePadding, 130),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    ...lines.map((l) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          child: Row(
                            children: [
                              ClipRRect(borderRadius: BorderRadius.circular(10), child: FoodImage(photoKey: l.key.photoKey, width: 44, height: 44)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l.key.name, style: AppText.body(size: 14, weight: FontWeight.w700)),
                                    Text('₹${l.key.price}', style: AppText.body(size: 12, weight: FontWeight.w500, color: AppColors.bodyGrey)),
                                  ],
                                ),
                              ),
                              _MiniStepper(id: l.key.id, qty: l.value),
                              const SizedBox(width: 12),
                              Text('₹${l.key.price * l.value}', style: AppText.body(size: 14, weight: FontWeight.w800)),
                            ],
                          ),
                        )),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: GestureDetector(
                        onTap: app.back,
                        child: Text('＋ Add more items', style: AppText.body(size: 13, weight: FontWeight.w700, color: AppColors.accent)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _CouponBanner(app: app),
              const SizedBox(height: 16),
              // Delivery speed options removed as per design request.
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('To Pay', style: AppText.display(size: 14)),
                    const SizedBox(height: 10),
                    _BillRow('Item total', '₹${app.itemsTotal}'),
                    _BillRow('Coupon discount', '−₹${app.discount}', valueColor: AppColors.green),
                    _BillRow('Delivery fee', app.deliveryFee == 0 ? 'FREE' : '₹${app.deliveryFee}'),
                    _BillRow('Taxes & charges', '₹${app.taxes}'),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: _DashedDivider(),
                    ),
                    _BillRow('To pay', '₹${app.grandTotal}', bold: true),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Cancellation policy: Orders are non-refundable once placed. Please double-check your items and address.',
                style: AppText.body(size: 12, weight: FontWeight.w500, color: AppColors.faintGreyText),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(AppResponsive.of(context).pagePadding, 12, AppResponsive.of(context).pagePadding, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(top: BorderSide(color: AppColors.cardBorder)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -6))],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: app.toPayment,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('PAY USING', style: AppText.body(size: 10.5, weight: FontWeight.w700, color: AppColors.bodyGrey, letterSpacing: 0.5)),
                          const Icon(Icons.keyboard_arrow_down, size: 14, color: AppColors.bodyGrey),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(_paymentLabel(app.selectedPay), style: AppText.body(size: 13.5, weight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: PrimaryButton(
                    label: app.isPlacingOrder
                        ? 'Placing order…'
                        : (app.selectedPay == 'cod'
                            ? 'Place order · ₹${app.grandTotal}'
                            : 'Pay ₹${app.grandTotal}'),
                    trailingIcon:
                        app.isPlacingOrder ? null : Icons.chevron_right,
                    onTap: app.isPlacingOrder ? () {} : _checkout,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _paymentLabel(String id) {
    switch (id) {
      case 'foodeez-upi':
        return 'Foodeez UPI';
      case 'gpay':
        return 'Google Pay';
      case 'phonepe':
        return 'PhonePe UPI';
      case 'paytm':
        return 'Paytm UPI';
      case 'foodeez-wallet':
        return 'Foodeez Wallet';
      case 'amazonpay':
        return 'Amazon Pay';
      case 'visa':
        return 'Visa •••• 4291';
      case 'lazypay':
        return 'LazyPay';
      case 'netbanking':
        return 'Netbanking';
      case 'cod':
        return 'Cash on Delivery';
      default:
        return 'Select';
    }
  }
}

class _CouponBanner extends StatelessWidget {
  final AppController app;
  const _CouponBanner({required this.app});

  @override
  Widget build(BuildContext context) {
    final applied = app.appliedCoupon;
    return GestureDetector(
      onTap: () => _openCouponSheet(context, app),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(16)),
        child: Row(
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
                  Text(
                    applied != null ? 'Saved ₹${app.discount} with ${applied.code}' : 'Apply a coupon',
                    style: AppText.body(size: 14, weight: FontWeight.w700),
                  ),
                  Text(
                    applied != null ? '${applied.issuedBy} · View all coupons ›' : 'View coupons for this restaurant ›',
                    style: AppText.body(size: 12, weight: FontWeight.w500, color: AppColors.bodyGrey),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: applied != null ? Colors.transparent : AppColors.accent,
                border: applied != null ? Border.all(color: AppColors.green, width: 1.5) : null,
                borderRadius: BorderRadius.circular(20),
              ),
              child: applied != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('APPLIED', style: AppText.body(size: 12, weight: FontWeight.w800, color: AppColors.green)),
                        const SizedBox(width: 4),
                        const Icon(Icons.check_circle_outline, size: 14, color: AppColors.green),
                      ],
                    )
                  : Text('VIEW', style: AppText.body(size: 12, weight: FontWeight.w800, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

void _openCouponSheet(BuildContext context, AppController app) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetContext) => _CouponSheet(app: app),
  );
}

class _CouponSheet extends StatelessWidget {
  final AppController app;
  const _CouponSheet({required this.app});

  @override
  Widget build(BuildContext context) {
    // Only coupons valid for THIS restaurant ever show up here — either
    // issued by the restaurant itself, or a Foodeez-wide offer that covers
    // it. A coupon scoped to a different restaurant never appears.
    final available = app.couponsForCurrentRestaurant;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(AppResponsive.of(context).pagePadding, 16, AppResponsive.of(context).pagePadding, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Coupons for ${app.restaurant.name}', style: AppText.display(size: 17)),
                GestureDetector(onTap: () => Navigator.of(context).pop(), child: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 4),
            Text('Restaurant offers and Foodeez-wide coupons valid here', style: AppText.body(size: 12.5, weight: FontWeight.w500, color: AppColors.bodyGrey)),
            const SizedBox(height: 16),
            if (available.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No coupons available for this restaurant right now', style: AppText.body(size: 13, weight: FontWeight.w500, color: AppColors.bodyGrey)),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: available.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _CouponTile(app: app, coupon: available[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CouponTile extends StatelessWidget {
  final AppController app;
  final Coupon coupon;
  const _CouponTile({required this.app, required this.coupon});

  @override
  Widget build(BuildContext context) {
    final eligible = coupon.meetsMinOrder(app.itemsTotal);
    final applied = app.appliedCouponCode == coupon.code;
    final restaurantOnly = coupon.scope == CouponScope.restaurant;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: applied ? AppColors.green : AppColors.cardBorder, width: applied ? 1.5 : 1),
        borderRadius: BorderRadius.circular(14),
        color: eligible ? Colors.white : const Color(0xFFFAFAFA),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(coupon.code, style: AppText.body(size: 14.5, weight: FontWeight.w800, color: eligible ? AppColors.ink : AppColors.bodyGrey)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.avatarBg, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  restaurantOnly ? 'By ${coupon.issuedBy}' : 'Foodeez offer',
                  style: AppText.body(size: 10, weight: FontWeight.w700, color: AppColors.accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(coupon.title, style: AppText.body(size: 13.5, weight: FontWeight.w700, color: eligible ? AppColors.ink : AppColors.bodyGrey)),
          Text(coupon.subtitle, style: AppText.body(size: 12, weight: FontWeight.w500, color: AppColors.bodyGrey)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: eligible
                ? OutlinedButton(
                    onPressed: () {
                      if (applied) {
                        app.removeCoupon();
                      } else {
                        app.applyCoupon(coupon.code);
                      }
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: applied ? Colors.transparent : AppColors.accent,
                      side: BorderSide(color: applied ? AppColors.green : AppColors.accent, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      applied ? 'REMOVE' : 'APPLY',
                      style: AppText.body(size: 12.5, weight: FontWeight.w800, color: applied ? AppColors.green : Colors.white),
                    ),
                  )
                : Text(
                    'Add ₹${coupon.minOrderValue - app.itemsTotal} more to unlock',
                    style: AppText.body(size: 12, weight: FontWeight.w700, color: AppColors.bodyGrey),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MiniStepper extends ConsumerWidget {
  final String id;
  final int qty;
  const _MiniStepper({required this.id, required this.qty});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.read(appControllerProvider);
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.accent, width: 1.5), borderRadius: BorderRadius.circular(9)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(onTap: () => app.sub(id), child: SizedBox(width: 30, height: 30, child: Center(child: Text('−', style: AppText.body(size: 16, weight: FontWeight.w800, color: AppColors.accent))))),
          SizedBox(width: 22, child: Center(child: Text('$qty', style: AppText.body(size: 13, weight: FontWeight.w800, color: AppColors.accent)))),
          GestureDetector(onTap: () => app.add(id), child: SizedBox(width: 30, height: 30, child: Center(child: Text('+', style: AppText.body(size: 16, weight: FontWeight.w800, color: AppColors.accent))))),
        ],
      ),
    );
  }
}

class _DeliverySpeedOption extends StatelessWidget {
  final String label;
  final String caption;
  final bool selected;
  final VoidCallback onTap;
  const _DeliverySpeedOption({required this.label, required this.caption, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.white,
          border: Border.all(color: selected ? AppColors.accent : AppColors.chipBorder, width: 1.5),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.body(size: 14, weight: FontWeight.w800, color: selected ? Colors.white : AppColors.ink)),
            Text(caption, style: AppText.body(size: 11, weight: FontWeight.w500, color: selected ? Colors.white.withValues(alpha: 0.85) : AppColors.bodyGrey)),
          ],
        ),
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;
  const _BillRow(this.label, this.value, {this.valueColor, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: bold ? AppText.body(size: 16, weight: FontWeight.w800) : AppText.body(size: 13, weight: FontWeight.w500)),
          Text(value, style: bold
              ? AppText.body(size: 16, weight: FontWeight.w800)
              : AppText.body(size: 13, weight: FontWeight.w600, color: valueColor ?? AppColors.ink)),
        ],
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: LayoutBuilder(builder: (context, constraints) {
        final count = (constraints.maxWidth / 8).floor();
        return Row(
          children: List.generate(count, (i) => Expanded(
              child: Container(height: 1, color: i.isEven ? AppColors.chipBorder : Colors.transparent))),
        );
      }),
    );
  }
}
