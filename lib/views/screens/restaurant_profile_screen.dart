import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../controllers/app_controller.dart';
import '../../controllers/providers.dart';
import '../../theme.dart';
import '../widgets/common.dart';

class RestaurantProfileScreen extends ConsumerStatefulWidget {
  const RestaurantProfileScreen({super.key});

  @override
  ConsumerState<RestaurantProfileScreen> createState() => _RestaurantProfileScreenState();
}

class _RestaurantProfileScreenState extends ConsumerState<RestaurantProfileScreen> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    final rest = restaurantById(app.bookingRid);
    final gallery = rest.gallery;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 320,
            child: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemCount: gallery.length,
                  itemBuilder: (context, i) => _MediaTile(
                    media: gallery[i],
                    onTapVideo: () => _openVideoViewer(context, gallery[i]),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x66000000), Colors.transparent, Color(0x33000000)],
                      stops: [0.0, 0.28, 1.0],
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CircleIconButton(icon: Icons.arrow_back_ios_new, onTap: app.back),
                          Row(
                            children: [
                              const CircleIconButton(icon: Icons.favorite_border, iconColor: AppColors.accent),
                              const SizedBox(width: 10),
                              const CircleIconButton(icon: Icons.share, iconColor: AppColors.accent),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_camera_outlined, size: 13, color: Colors.white),
                        const SizedBox(width: 5),
                        Text('${_page + 1}/${gallery.length}', style: AppText.body(size: 11.5, weight: FontWeight.w700, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 16,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(gallery.length, (i) {
                        final active = i == _page;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: active ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: active ? Colors.white : Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(rest.name, style: AppText.display(size: 22, letterSpacing: -0.3))),
                    RatingPill(rating: rest.rating),
                  ],
                ),
                const SizedBox(height: 3),
                Text(rest.cuisines, style: AppText.body(size: 13, weight: FontWeight.w500, color: AppColors.bodyGrey)),
                const SizedBox(height: 3),
                Text('${rest.dist} · ${rest.price}', style: AppText.body(size: 12.5, weight: FontWeight.w500, color: AppColors.bodyGrey)),
                const SizedBox(height: 16),
                DashedRect(
                  borderColor: AppColors.dashedBookingBorder,
                  fillColor: AppColors.dashedBookingBg,
                  child: Row(
                    children: [
                      const Icon(Icons.confirmation_number_outlined, size: 16, color: AppColors.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Flat 25% off on your total bill when you dine out',
                            style: AppText.body(size: 13, weight: FontWeight.w700, color: AppColors.accent)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(label: 'Book a table', onTap: () => app.openBooking(rest.id)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openVideoViewer(BuildContext context, GalleryMedia media) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) => _VideoViewer(media: media),
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  final GalleryMedia media;
  final VoidCallback onTapVideo;
  const _MediaTile({required this.media, required this.onTapVideo});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: media.isVideo ? onTapVideo : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FoodImage(photoKey: media.photoKey, fit: BoxFit.cover),
          if (media.isVideo) ...[
            Container(color: Colors.black.withValues(alpha: 0.25)),
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow, color: AppColors.accent, size: 32),
              ),
            ),
            Positioned(
              left: 14,
              bottom: 40,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(6)),
                child: Text(media.duration ?? '', style: AppText.body(size: 11, weight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VideoViewer extends StatefulWidget {
  final GalleryMedia media;
  const _VideoViewer({required this.media});

  @override
  State<_VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<_VideoViewer> with SingleTickerProviderStateMixin {
  late final AnimationController _progress;
  bool _playing = true;

  @override
  void initState() {
    super.initState();
    final seconds = int.tryParse((widget.media.duration ?? '0:15').split(':').last) ?? 15;
    _progress = AnimationController(vsync: this, duration: Duration(seconds: seconds))..forward();
    _progress.addListener(() {
      if (_progress.isCompleted) setState(() => _playing = false);
    });
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _playing = !_playing;
      if (_playing) {
        if (_progress.isCompleted) _progress.reset();
        _progress.forward();
      } else {
        _progress.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            FoodImage(photoKey: widget.media.photoKey, fit: BoxFit.contain),
            GestureDetector(
              onTap: _toggle,
              behavior: HitTestBehavior.translucent,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _playing ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), shape: BoxShape.circle),
                    child: const Icon(Icons.play_arrow, color: AppColors.accent, size: 38),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: CircleIconButton(icon: Icons.close, bg: Colors.black.withValues(alpha: 0.5), iconColor: Colors.white, onTap: () => Navigator.of(context).pop()),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: AnimatedBuilder(
                animation: _progress,
                builder: (context, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: _progress.value,
                    minHeight: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
