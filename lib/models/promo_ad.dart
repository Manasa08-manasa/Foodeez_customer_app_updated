import 'package:flutter/material.dart';

class PromoAd {
  final String title;
  final String subtitle;
  final String cta;
  final List<Color> gradient;
  final String photoKey;

  const PromoAd({
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.gradient,
    required this.photoKey,
  });
}
