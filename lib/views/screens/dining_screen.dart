import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock_data.dart';
import '../../controllers/providers.dart';
import '../../core/responsive.dart';
import '../../theme.dart';
import '../widgets/common.dart';

class DiningScreen extends ConsumerWidget {
  const DiningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final pad = AppResponsive.of(context).pagePadding;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: responsivePageInsets(context, top: 6),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dining Out', style: AppText.display(size: 17)),
                      Text('Table booking & great offers', style: AppText.body(size: 12.5, weight: FontWeight.w500, color: AppColors.bodyGrey)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: app.toAccount,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: AppColors.avatarBg, shape: BoxShape.circle, border: Border.all(color: AppColors.avatarBorder, width: 1.5)),
                    alignment: Alignment.center,
                    child: Text(userInitials, style: AppText.body(size: 15, weight: FontWeight.w800, color: AppColors.accent)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DeliveryDiningToggle(isDelivery: false, onDelivery: app.toHome, onDining: () {}),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(pad),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.accentLight, AppColors.accent], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Flat 25% OFF', style: AppText.display(size: 22, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text('on your total bill · dine out at 8,000+ restaurants nearby',
                      style: AppText.body(size: 13, weight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.95))),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Book a table nearby', style: AppText.display(size: 18)),
            const SizedBox(height: 12),
            ...restaurants.map((r) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => app.openProfile(r.id),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(borderRadius: BorderRadius.circular(16), child: FoodImage(photoKey: r.photoKey)),
                                if (r.videoThumbnailKey != null)
                                  Positioned(
                                    right: 6,
                                    bottom: 6,
                                    child: Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), shape: BoxShape.circle),
                                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 13),
                                    ),
                                  ),
                                Positioned(
                                  left: 6,
                                  top: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(6)),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.photo_camera_outlined, size: 10, color: Colors.white),
                                        const SizedBox(width: 3),
                                        Text('${r.gallery.length}', style: AppText.body(size: 9.5, weight: FontWeight.w700, color: Colors.white)),
                                      ],
                                    ),
                                  ),
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
                                Text(r.cuisines, maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: AppText.body(size: 12.5, weight: FontWeight.w500, color: AppColors.bodyGrey)),
                                const SizedBox(height: 2),
                                Text('${r.dist} · ${r.price}', style: AppText.body(size: 12.5, weight: FontWeight.w500, color: AppColors.bodyGrey)),
                                const SizedBox(height: 8),
                                DashedRect(
                                  borderColor: AppColors.dashedBookingBorder,
                                  fillColor: AppColors.dashedBookingBg,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  radius: 9,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.confirmation_number_outlined, size: 13, color: AppColors.accent),
                                      const SizedBox(width: 6),
                                      Text('25% OFF on total bill', style: AppText.body(size: 11, weight: FontWeight.w700, color: AppColors.accent)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => app.openBooking(r.id),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.accent, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Book a table', style: AppText.body(size: 13.5, weight: FontWeight.w700, color: AppColors.accent)),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
