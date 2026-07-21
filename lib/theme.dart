import 'package:flutter/material.dart';

/// Foodeez brand palette — hex values sourced verbatim from the design prototype.
class AppColors {
  AppColors._();

  static const accent = Color(0xFF6E2A4D);
  static const accentLight = Color(0xFF8A3A66);
  static const accentDeep = Color(0xFF4E1D37);

  static const gold = Color(0xFFC9A227);
  static const goldLight = Color(0xFFF6D77E);

  static const green = Color(0xFF1F8A3B);
  static const greenDarkText = Color(0xFF137A37);
  static const greenPaleBg = Color(0xFFEAF6EE);
  static const vegDot = Color(0xFF128A4B);
  static const nonVegDot = Color(0xFFC0392B);

  static const red = Color(0xFFC0392B);
  static const badgeRed = Color(0xFFF0413F);

  static const ink = Color(0xFF1E1A1D);
  static const bodyGrey = Color(0xFF8A8189);
  static const lightGreyText = Color(0xFFB4A9AE);
  static const faintGreyText = Color(0xFFA79DA3);
  static const midGrey = Color(0xFF4A4247);

  static const hairline = Color(0xFFF1ECE8);
  static const cardBorder = Color(0xFFEFEAE6);
  static const chipBorder = Color(0xFFE4DCE0);

  static const dashedOfferBorder = Color(0xFFE5C489);
  static const dashedOfferBg = Color(0xFFFDF7EA);
  static const dashedBookingBorder = Color(0xFFD9B8CC);
  static const dashedBookingBg = Color(0xFFF6EEF3);
  static const offerTextBrown = Color(0xFFB4692E);

  static const avatarBg = Color(0xFFF6EEF3);
  static const avatarBorder = Color(0xFFE8D3E0);

  static const paleWarmBg = Color(0xFFF7F4F0);

  /// Customer portal sign-in background (matches website `bg-[#f7f2ea]`).
  static const customerPortalBg = Color(0xFFF7F2EA);
  static const onboardingGradTop = customerPortalBg;
  static const onboardingKicker = Color(0xFF853761);

  static const categoryGradTop = Color(0xFFFBF0DC);
  static const categoryGradBottom = Color(0xFFF3E0C2);
  static const categoryBorder = Color(0xFFEEDFC8);

  static const mapBgTop = Color(0xFFE8EFE6);
  static const mapBgBottom = Color(0xFFDDE7E9);
  static const mapBlockFill = Color(0xFFE6ECE4);
  static const mapGrid = Color(0xFFD3DAD0);
  static const mapBuildings = Color(0xFFDCE3D8);

  static const placeholderPhotoBg = Color(0xFF3A2416);

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentLight, accent],
  );
}

/// Text style helpers — 'Bricolage Grotesque' for display/headings,
/// 'Plus Jakarta Sans' for body/UI text.
class AppText {
  AppText._();

  static TextStyle display({
    required double size,
    FontWeight weight = FontWeight.w800,
    Color color = AppColors.ink,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'Bricolage Grotesque',
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle body({
    required double size,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.ink,
    double? letterSpacing,
    double? height,
    FontStyle? style,
  }) {
    return TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      fontStyle: style,
    );
  }
}
