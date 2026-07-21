import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock_data.dart';
import '../../controllers/app_controller.dart';
import '../../controllers/providers.dart';
import '../../core/responsive.dart';
import '../../theme.dart';

class PaymentScreen extends ConsumerWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final isBooking = app.paymentContext == 'booking';

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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isBooking ? 'Table reservation fee' : 'Payment options', style: AppText.display(size: 18)),
                    Text(
                      isBooking
                          ? 'Refundable booking fee · ₹$bookingFee'
                          : 'Total ₹${app.grandTotal} · Savings ₹${app.discount}',
                      style: AppText.body(size: 12, weight: FontWeight.w600, color: AppColors.bodyGrey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...paymentGroupOrder.map((group) {
                    final items = paymentMethods.where((p) => p.group == group).toList();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(group.toUpperCase(), style: AppText.body(size: 12, weight: FontWeight.w700, color: AppColors.bodyGrey, letterSpacing: 1)),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(14)),
                            child: Column(
                              children: items.asMap().entries.map((e) {
                                final isLast = e.key == items.length - 1;
                                final m = e.value;
                                final selected = app.selectedPay == m.id;
                                return GestureDetector(
                                  onTap: () => app.choosePay(m.id),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.hairline)),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(color: m.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                                          alignment: Alignment.center,
                                          child: m.icon != null
                                              ? Icon(m.icon, color: m.color, size: 20)
                                              : Text(m.glyph, style: AppText.body(size: 16, weight: FontWeight.w800, color: m.color)),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(m.name, style: AppText.body(size: 14, weight: FontWeight.w700)),
                                              if (m.sub != null)
                                                Text(m.sub!, style: AppText.body(size: 11.5, weight: FontWeight.w500, color: AppColors.bodyGrey)),
                                            ],
                                          ),
                                        ),
                                        selected
                                            ? const Icon(Icons.check_circle, color: AppColors.green, size: 22)
                                            : Container(
                                                width: 20,
                                                height: 20,
                                                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.chipBorder, width: 2)),
                                              ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_outline, size: 14, color: AppColors.lightGreyText),
                        const SizedBox(width: 6),
                        Text('100% secure payments · powered by Foodeez Pay',
                            style: AppText.body(size: 11.5, weight: FontWeight.w600, color: AppColors.lightGreyText)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
