import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../theme.dart';

/// Desaturates its child — used for closed-restaurant states.
class Grayscale extends StatelessWidget {
  final Widget child;
  final bool enabled;
  const Grayscale({super.key, required this.child, this.enabled = true});

  static const _matrix = <double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ];

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(_matrix),
      child: child,
    );
  }
}

/// Small dark "CLOSED" pill overlaid on a restaurant photo.
class ClosedBadge extends StatelessWidget {
  const ClosedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        'CLOSED',
        style: AppText.body(size: 10.5, weight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
      ),
    );
  }
}

/// Sponsored/brand ad card used on Home and Tracking (Swiggy/Zomato-style ad rail).
class PromoAdCard extends StatelessWidget {
  final PromoAd ad;
  final double width;
  final double height;
  const PromoAdCard({super.key, required this.ad, this.width = 220, this.height = 150});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          FoodImage(photoKey: ad.photoKey, width: width, height: height),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  ad.gradient.first.withValues(alpha: 0.15),
                  ad.gradient.last.withValues(alpha: 0.92),
                ],
                stops: const [0.0, 0.65],
              ),
            ),
          ),
          Positioned(
            left: 14,
            top: 12,
            child: Text(
              'AD',
              style: AppText.body(size: 9, weight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.75), letterSpacing: 1),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(ad.title, style: AppText.body(size: 14.5, weight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 3),
                Text(
                  ad.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(size: 11, weight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.88)),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Text(ad.cta, style: AppText.body(size: 11, weight: FontWeight.w800, color: AppColors.accent)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Restaurant/dish photo with a branded gradient fallback if the network
/// image can't load (keeps the UI intact instead of showing a broken icon).
class FoodImage extends StatelessWidget {
  final String photoKey;
  final double? width;
  final double? height;
  final BoxFit fit;

  const FoodImage({
    super.key,
    required this.photoKey,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final requestWidth = (width == null || !width!.isFinite) ? 300.0 : width!;
    return CachedNetworkImage(
      imageUrl: foodImageUrl(photoKey, width: requestWidth.round() * 2),
      width: width,
      height: height,
      fit: fit,
      placeholder: (c, u) => _fallback(),
      errorWidget: (c, u, e) => _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.placeholderPhotoBg, AppColors.accentDeep],
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.restaurant, color: Colors.white38, size: 28),
    );
  }
}

/// Green "4.5 ★" style rating chip.
class RatingPill extends StatelessWidget {
  final double rating;
  final bool outlined;
  const RatingPill({super.key, required this.rating, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$rating',
            style: AppText.body(size: 12, weight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.star, color: Colors.white, size: 11),
        ],
      ),
    );
  }
}

/// Full-width gradient primary CTA button used throughout the app.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? trailingIcon;
  final double? maxWidth;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.trailingIcon,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 17),
          decoration: BoxDecoration(
            gradient: AppColors.accentGradient,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppText.body(size: 16, weight: FontWeight.w700, color: Colors.white),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 6),
                Icon(trailingIcon, color: AppColors.goldLight, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
    if (maxWidth != null) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth!),
        child: button,
      );
    }
    return button;
  }
}

/// Circular white icon button (back arrow, heart, share, etc.) used floating
/// over hero photos.
class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color bg;
  final Color iconColor;
  final double size;

  const CircleIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.bg = Colors.white,
    this.iconColor = AppColors.ink,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg.withValues(alpha: bg == Colors.white ? 0.92 : 1),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: size * 0.5, color: iconColor),
        ),
      ),
    );
  }
}

/// Delivery / Dining Out segmented toggle used on Home, Dining, and Orders.
class DeliveryDiningToggle extends StatelessWidget {
  final bool isDelivery;
  final VoidCallback onDelivery;
  final VoidCallback onDining;

  const DeliveryDiningToggle({
    super.key,
    required this.isDelivery,
    required this.onDelivery,
    required this.onDining,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1ECE8),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Expanded(
            child: _segment(
              label: 'Delivery',
              icon: Icons.two_wheeler,
              active: isDelivery,
              onTap: onDelivery,
            ),
          ),
          Expanded(
            child: _segment(
              label: 'Dining Out',
              icon: Icons.restaurant,
              active: !isDelivery,
              onTap: onDining,
            ),
          ),
        ],
      ),
    );
  }

  Widget _segment({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: active ? AppColors.accent : AppColors.bodyGrey),
            const SizedBox(width: 7),
            Text(
              label,
              style: AppText.body(
                size: 14,
                weight: active ? FontWeight.w800 : FontWeight.w700,
                color: active ? AppColors.accent : AppColors.bodyGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Outlined filter chip (Sort / Filters / Pure Veg / Rating 4.0+ ...).
class FzFilterChip extends StatelessWidget {
  final String label;
  final Widget? leading;
  final bool filled;
  final VoidCallback? onTap;

  const FzFilterChip({
    super.key,
    required this.label,
    this.leading,
    this.filled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: filled ? AppColors.accent : Colors.transparent,
          border: filled ? null : Border.all(color: AppColors.chipBorder, width: 1.5),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 6)],
            Text(
              label,
              style: AppText.body(
                size: 12.5,
                weight: FontWeight.w700,
                color: filled ? Colors.white : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small green square-with-dot (veg) / red variant (non-veg) indicator.
class VegDot extends StatelessWidget {
  final bool veg;
  const VegDot({super.key, required this.veg});

  @override
  Widget build(BuildContext context) {
    final color = veg ? AppColors.vegDot : AppColors.nonVegDot;
    return Container(
      width: 15,
      height: 15,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

/// A rect with a dashed border — Flutter has no built-in for this.
class DashedRect extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final Color fillColor;
  final double radius;
  final EdgeInsets padding;

  const DashedRect({
    super.key,
    required this.child,
    required this.borderColor,
    required this.fillColor,
    this.radius = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(color: borderColor, radius: radius),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: child,
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  _DashedRectPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final dashed = _dashPath(path, dashLength: 5, gapLength: 4);
    canvas.drawPath(
      dashed,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  Path _dashPath(Path source, {required double dashLength, required double gapLength}) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final len = draw ? dashLength : gapLength;
        final next = (distance + len).clamp(0, metric.length).toDouble();
        if (draw) {
          dest.addPath(metric.extractPath(distance, next), ui.Offset.zero);
        }
        distance = next;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

/// Section title used across screens ("What's on your mind?", etc.)
class SectionTitle extends StatelessWidget {
  final String text;
  final EdgeInsets padding;
  const SectionTitle(this.text, {super.key, this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 4)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(text, style: AppText.display(size: 18)),
    );
  }
}
