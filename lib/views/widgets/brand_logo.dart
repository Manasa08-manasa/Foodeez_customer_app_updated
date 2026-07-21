import 'package:flutter/material.dart';

/// Brand marks with correct aspect ratios (never squashed).
class BrandLogo extends StatelessWidget {
  const BrandLogo.mark({
    super.key,
    this.height = 120,
    this.glow = false,
  })  : _variant = _BrandVariant.mark,
        width = null,
        blendBackground = null;

  const BrandLogo.full({
    super.key,
    this.width = 260,
    this.glow = false,
  })  : _variant = _BrandVariant.full,
        height = null,
        blendBackground = null;

  const BrandLogo.stack({
    super.key,
    this.height = 220,
    this.glow = false,
  })  : _variant = _BrandVariant.stack,
        width = null,
        blendBackground = null;

  /// Customer sign-in / onboarding logo (`logo_customer.png`).
  const BrandLogo.customer({
    super.key,
    this.width = 220,
    this.glow = false,
    this.blendBackground,
  })  : _variant = _BrandVariant.customer,
        height = null;

  final _BrandVariant _variant;
  final double? width;
  final double? height;
  final bool glow;
  /// When set, wraps the logo so any white PNG background blends with the screen.
  final Color? blendBackground;

  @override
  Widget build(BuildContext context) {
    final asset = switch (_variant) {
      _BrandVariant.mark => 'assets/images/foodeez-f-logo.png',
      _BrandVariant.full => 'assets/images/foodeez_customer_logo.png',
      _BrandVariant.stack => 'assets/images/Foodeez_logo_1.png',
      _BrandVariant.customer => 'assets/images/logo_customer.png',
    };
    final fallback = switch (_variant) {
      _BrandVariant.mark => 'assets/images/foodeez-mark.png',
      _BrandVariant.full => 'assets/images/logo_customer.png',
      _BrandVariant.stack => 'assets/images/foodeez-full.png',
      _BrandVariant.customer => 'assets/images/foodeez-full.png',
    };

    Widget image = Image.asset(
      asset,
      width: width,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, _, _) => Image.asset(
        fallback,
        width: width,
        height: height,
        fit: BoxFit.contain,
      ),
    );

    if (glow) {
      image = Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color(0x66C9A227),
              blurRadius: 28,
              spreadRadius: 2,
            ),
          ],
        ),
        child: image,
      );
    }
    if (blendBackground != null) {
      image = ColoredBox(
        color: blendBackground!,
        child: image,
      );
    }
    return image;
  }
}

enum _BrandVariant { mark, full, stack, customer }
