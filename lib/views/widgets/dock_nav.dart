import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers.dart';
import '../../core/responsive.dart';
import '../../theme.dart';

class _DockItem {
  final String key;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _DockItem(this.key, this.icon, this.activeIcon, this.label);
}

const _items = [
  _DockItem('home', Icons.home_outlined, Icons.home, 'Home'),
  _DockItem('dining', Icons.restaurant_outlined, Icons.restaurant, 'Dining'),
  _DockItem('orders', Icons.receipt_long_outlined, Icons.receipt_long, 'Orders'),
  _DockItem('account', Icons.person_outline, Icons.person, 'Account'),
];

class DockNav extends ConsumerWidget {
  const DockNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final active = app.activeTab;
    final r = AppResponsive.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final screenW = MediaQuery.sizeOf(context).width;
    final barWidth = r.isWide
        ? math.min(r.contentMaxWidth, screenW) - 28
        : screenW - 28;
    final barHeight = r.isWide ? 72.0 : 68.0;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, 0, 14, bottomInset > 0 ? 6 : 10),
          child: SizedBox(
            width: barWidth.clamp(0, screenW),
            height: barHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.30),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.22),
                        blurRadius: 36,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Row(
                    children: _items.map((item) {
                      final isActive = item.key == active;
                      return Expanded(
                        child: _DockButton(
                          item: item,
                          isActive: isActive,
                          badgeCount: item.key == 'orders' ? app.orderBadgeCount : 0,
                          onTap: () {
                            switch (item.key) {
                              case 'home':
                                app.toHome();
                                break;
                              case 'dining':
                                app.toDining();
                                break;
                              case 'orders':
                                app.toOrders();
                                break;
                              case 'account':
                                app.toAccount();
                                break;
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  final _DockItem item;
  final bool isActive;
  final int badgeCount;
  final VoidCallback onTap;

  const _DockButton({
    required this.item,
    required this.isActive,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: isActive ? 48 : 42,
                height: isActive ? 48 : 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isActive ? AppColors.accentGradient : null,
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  isActive ? item.activeIcon : item.icon,
                  color: isActive ? Colors.white : const Color(0xFF8E8489),
                  size: isActive ? 22 : 22,
                ),
              ),
              if (badgeCount > 0 && !isActive)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    decoration: BoxDecoration(
                      color: AppColors.badgeRed,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
