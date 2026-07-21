import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock_data.dart';
import '../../controllers/app_controller.dart';
import '../../controllers/providers.dart';
import '../../theme.dart';
import '../widgets/common.dart';

class BookingConfirmedScreen extends ConsumerWidget {
  const BookingConfirmedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final booking = app.lastBooking ?? app.bookings.first;
    final rest = restaurantById(booking.restaurantId);

    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(center: Alignment.topCenter, radius: 1.2, colors: [Color(0xFFFBF3E9), Colors.white]),
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: GestureDetector(
                    onTap: app.back,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.cardBorder, width: 1.5), color: Colors.white),
                      child: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.ink),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: Colors.white, size: 44),
                ),
                const SizedBox(height: 22),
                Text('Table booked!', style: AppText.display(size: 24)),
                const SizedBox(height: 10),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: AppText.body(size: 14, weight: FontWeight.w500, color: AppColors.bodyGrey),
                    children: [
                      const TextSpan(text: 'Your table at '),
                      TextSpan(text: rest.name, style: AppText.body(size: 14, weight: FontWeight.w800, color: AppColors.ink)),
                      TextSpan(text: ' for ${booking.guests} is confirmed. Show this at the restaurant to avail your offer.'),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('BOOKING ID', style: AppText.body(size: 11, weight: FontWeight.w500, color: AppColors.bodyGrey)),
                                Text('#${booking.id}', style: AppText.display(size: 15)),
                              ],
                            ),
                            const Icon(Icons.confirmation_number_outlined, color: AppColors.accent),
                          ],
                        ),
                        if (booking.feePaid > 0) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(height: 1, color: AppColors.hairline),
                          ),
                          Text('Booking fee paid', style: AppText.body(size: 12.5, weight: FontWeight.w600, color: AppColors.bodyGrey)),
                          const SizedBox(height: 2),
                          Text(
                            '₹${booking.feePaid} · ${paymentMethodById(booking.paymentMethodId).name}',
                            style: AppText.body(size: 12.5, weight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Fully refundable if you cancel 3+ hours before your slot',
                            style: AppText.body(size: 11, weight: FontWeight.w500, color: AppColors.faintGreyText),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(label: 'Done', onTap: app.toDining, maxWidth: 280),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
