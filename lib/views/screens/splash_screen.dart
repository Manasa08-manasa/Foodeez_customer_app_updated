import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers.dart';
import '../../core/responsive.dart';
import '../../theme.dart';
import '../widgets/brand_logo.dart';

/// Customer Focus Ring splash — matches
/// `Splash - Customer Focus Ring (standalone).html` variant G.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _bg1 = Color(0xFF4A1630);
  static const _bg2 = Color(0xFF2A0E1C);
  static const _bg3 = Color(0xFF150710);
  static const _goldA = Color(0xFFF0D48A);
  static const _goldB = Color(0xFFB8862F);
  static const _accent = Color(0xFFE8C767);

  late final AnimationController _ctrl;
  Timer? _navTimer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _bg3,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..forward();

    _navTimer = Timer(const Duration(milliseconds: 2600), _goNext);
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _goNext() {
    if (!mounted || _navigated) return;
    final app = ref.read(appControllerProvider);
    if (app.isHydrating) {
      _navTimer = Timer(const Duration(milliseconds: 200), _goNext);
      return;
    }
    _navigated = true;
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    if (app.isLoggedIn) {
      app.toHome();
    } else {
      app.setTab('onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive.of(context);
    final logoSize = r.isTablet ? 200.0 : 156.0;
    final ringSize = r.isTablet ? 340.0 : 268.0;
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _bg2,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-0.2, -1),
              end: Alignment(0.2, 1),
              colors: [_bg1, _bg2, _bg3],
              stops: [0.0, 0.62, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Soft gold glow behind the mark
              Center(
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, _) {
                    final t = Curves.easeInOut.transform(
                      ((_ctrl.value * 2) % 1.0),
                    );
                    final glow = 0.14 + 0.08 * math.sin(t * math.pi);
                    return Container(
                      width: ringSize * 1.45,
                      height: ringSize * 1.45,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _goldA.withValues(alpha: glow),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.66],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Vignette
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.15),
                      radius: 1.1,
                      colors: [Colors.transparent, Color(0x6B000000)],
                      stops: [0.4, 1.0],
                    ),
                  ),
                ),
              ),

              // Dot grain
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.35,
                    child: CustomPaint(painter: _DotGrainPainter()),
                  ),
                ),
              ),

              SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: ringSize,
                        height: ringSize,
                        child: AnimatedBuilder(
                          animation: _ctrl,
                          builder: (context, child) {
                            final focus = Curves.easeOutCubic.transform(
                              ((_ctrl.value - 0.05).clamp(0.0, 0.35) / 0.35),
                            );
                            final blur = (1 - focus) * 10;
                            final scale = 1.18 - (0.18 * focus);
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                CustomPaint(
                                  size: Size(ringSize, ringSize),
                                  painter: _FocusRingPainter(
                                    progress: Curves.easeInOut.transform(
                                      ((_ctrl.value - 0.08).clamp(0.0, 0.55) /
                                          0.55),
                                    ),
                                    trackColor: Colors.white.withValues(
                                      alpha: 0.08,
                                    ),
                                    ringColor: _goldA,
                                  ),
                                ),
                                ImageFiltered(
                                  imageFilter: ImageFilter.blur(
                                    sigmaX: blur,
                                    sigmaY: blur,
                                  ),
                                  child: Opacity(
                                    opacity: focus.clamp(0.0, 1.0),
                                    child: Transform.scale(
                                      scale: scale,
                                      child: child,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                          child: BrandLogo.stack(height: logoSize),
                        ),
                      ),
                      SizedBox(height: r.isTablet ? 28 : 22),
                      AnimatedBuilder(
                        animation: _ctrl,
                        builder: (context, child) {
                          final t = Curves.easeOut.transform(
                            ((_ctrl.value - 0.35).clamp(0.0, 0.4) / 0.4),
                          );
                          return Opacity(
                            opacity: t,
                            child: Transform.translate(
                              offset: Offset(0, 12 * (1 - t)),
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          'TAP · EAT · REPEAT',
                          style: AppText.body(
                            size: r.isTablet ? 15 : 13,
                            weight: FontWeight.w600,
                            color: _accent,
                            letterSpacing: 5.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),
                      AnimatedBuilder(
                        animation: _ctrl,
                        builder: (context, _) {
                          final fill = Curves.easeInOut.transform(
                            ((_ctrl.value - 0.2).clamp(0.0, 0.75) / 0.75),
                          );
                          return SizedBox(
                            width: r.isTablet ? 180 : 140,
                            height: 3,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: Stack(
                                children: [
                                  Container(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: fill,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [_goldA, _goldB],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
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

class _FocusRingPainter extends CustomPainter {
  _FocusRingPainter({
    required this.progress,
    required this.trackColor,
    required this.ringColor,
  });

  final double progress;
  final Color trackColor;
  final Color ringColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 4;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, track);

    final ring = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    // Start at top (-90°) like the HTML SVG rotate(-90deg)
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, ring);
  }

  @override
  bool shouldRepaint(covariant _FocusRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.ringColor != ringColor ||
      oldDelegate.trackColor != trackColor;
}

class _DotGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x33F0D48A);
    const step = 20.0;
    for (var y = 0.0; y < size.height; y += step) {
      for (var x = 0.0; x < size.width; x += step) {
        canvas.drawCircle(Offset(x + 1.3, y + 1.3), 1.3, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
