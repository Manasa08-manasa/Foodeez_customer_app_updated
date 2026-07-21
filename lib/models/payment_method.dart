import 'package:flutter/material.dart';

class PaymentMethod {
  final String id;
  final String group;
  final String name;
  final String? sub;
  final String glyph;
  final Color color;
  final IconData? icon;

  const PaymentMethod({
    required this.id,
    required this.group,
    required this.name,
    this.sub,
    required this.glyph,
    required this.color,
    this.icon,
  });
}
