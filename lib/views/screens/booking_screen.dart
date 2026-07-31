import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock_data.dart';
import '../../controllers/app_controller.dart';
import '../../controllers/providers.dart';
import '../../core/responsive.dart';
import '../../theme.dart';
import '../widgets/common.dart';

class BookingScreen extends ConsumerWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final rest = restaurantById(app.bookingRid);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 154,
            child: Stack(
              fit: StackFit.expand,
              children: [
                FoodImage(
                  photoKey: rest.photoKey,
                  width: double.infinity,
                  height: 154,
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x4D000000), Colors.transparent],
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: CircleIconButton(
                        icon: Icons.arrow_back_ios_new,
                        onTap: app.back,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rest.name, style: AppText.display(size: 21)),
                const SizedBox(height: 2),
                Text(
                  '${rest.cuisines} · ${rest.dist}',
                  style: AppText.body(
                    size: 13,
                    weight: FontWeight.w500,
                    color: AppColors.bodyGrey,
                  ),
                ),
                const SizedBox(height: 22),

                Text('Number of guests', style: AppText.display(size: 15)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.chipBorder, width: 1.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _circleBtn(
                        icon: Icons.remove,
                        filled: false,
                        onTap: app.decG,
                      ),
                      Text(
                        '${app.bGuests} ${app.bGuests == 1 ? 'guest' : 'guests'}',
                        style: AppText.body(size: 15, weight: FontWeight.w700),
                      ),
                      _circleBtn(
                        icon: Icons.add,
                        filled: true,
                        onTap: app.incG,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Up to ${app.bookingMaxGuests} guests per reservation',
                  style: AppText.body(
                    size: 11.5,
                    weight: FontWeight.w500,
                    color: AppColors.bodyGrey,
                  ),
                ),
                const SizedBox(height: 22),

                Text('Select date', style: AppText.display(size: 15)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: bookingDates.length,
                    separatorBuilder: (context, _) => const SizedBox(width: 9),
                    itemBuilder: (context, i) => _Chip(
                      label: bookingDates[i],
                      selected: app.bDateIdx == i,
                      onTap: () => app.setBDate(i),
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                Text('Select time', style: AppText.display(size: 15)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: List.generate(
                    bookingTimes.length,
                    (i) => _Chip(
                      label: bookingTimes[i],
                      selected: app.bTimeIdx == i,
                      onTap: () => app.setBTime(i),
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                DashedRect(
                  borderColor: AppColors.dashedBookingBorder,
                  fillColor: AppColors.dashedBookingBg,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.confirmation_number_outlined,
                        size: 16,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Flat 25% off on your total bill when you dine out',
                          style: AppText.body(
                            size: 13,
                            weight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.paleWarmBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Booking fee',
                            style: AppText.body(
                              size: 14,
                              weight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '₹$bookingFee',
                            style: AppText.body(
                              size: 14,
                              weight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fully refundable if you cancel at least 3 hours before your slot',
                        style: AppText.body(
                          size: 12,
                          weight: FontWeight.w500,
                          color: AppColors.bodyGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Pay ₹$bookingFee & Reserve',
                  onTap: app.goToBookingPayment,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn({
    required IconData icon,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? AppColors.accent : Colors.transparent,
          border: filled
              ? null
              : Border.all(color: AppColors.accent, width: 1.5),
        ),
        child: Icon(
          icon,
          size: 18,
          color: filled ? Colors.white : AppColors.accent,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.white,
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.chipBorder,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          label,
          style: AppText.body(
            size: 13,
            weight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }
}
