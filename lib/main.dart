import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'controllers/providers.dart';
import 'core/responsive.dart';
import 'theme.dart';
import 'views/widgets/dock_nav.dart';

import 'views/screens/splash_screen.dart';
import 'views/screens/onboarding_screen.dart';
import 'views/screens/home_screen.dart';
import 'views/screens/search_screen.dart';
import 'views/screens/listing_screen.dart';
import 'views/screens/menu_screen.dart';
import 'views/screens/cart_screen.dart';
import 'views/screens/payment_screen.dart';
import 'views/screens/tracking_screen.dart';
import 'views/screens/orders_screen.dart';
import 'views/screens/dining_screen.dart';
import 'views/screens/booking_screen.dart';
import 'views/screens/booking_confirmed_screen.dart';
import 'views/screens/account_screen.dart';
import 'views/screens/address_book_screen.dart';
import 'views/screens/select_location_screen.dart';
import 'views/screens/help_screen.dart';
import 'views/screens/chat_screen.dart';
import 'views/screens/restaurant_profile_screen.dart';
import 'views/screens/coupons_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  // ProviderScope replaces package:provider's root widget — it's what makes
  // every `ref.watch(...)` / `ref.read(...)` call in the app possible.
  runApp(const ProviderScope(child: FoodeezApp()));
}

class FoodeezApp extends StatelessWidget {
  const FoodeezApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FooDeeZ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          primary: AppColors.accent,
        ),
        fontFamily: 'Plus Jakarta Sans',
        splashFactory: InkRipple.splashFactory,
      ),
      builder: (context, child) {
        // Keep text readable on tablets without over-scaling.
        final media = MediaQuery.of(context);
        final scale = media.textScaler.clamp(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.15,
        );
        return MediaQuery(
          data: media.copyWith(textScaler: scale),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const AppShell(),
    );
  }
}

/// The app's single-screen router/view-swapper. Watches the controller's
/// navigation stack and renders whichever screen (View) is on top, mirroring
/// the original prototype's `Component` state machine.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const _screens = {
    'splash': SplashScreen(),
    'onboarding': OnboardingScreen(),
    'home': HomeScreen(),
    'search': SearchScreen(),
    'list': ListingScreen(),
    'menu': MenuScreen(),
    'cart': CartScreen(),
    'payment': PaymentScreen(),
    'tracking': TrackingScreen(),
    'orders': OrdersScreen(),
    'dining': DiningScreen(),
    'booking': BookingScreen(),
    'booking-done': BookingConfirmedScreen(),
    'account': AccountScreen(),
    'address-book': AddressBookScreen(),
    'select-location': SelectLocationScreen(),
    'help': HelpScreen(),
    'chat': ChatScreen(),
    'profile': RestaurantProfileScreen(),
    'coupons': CouponsScreen(),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final isSplash = app.screen == 'splash';
    final isWide = AppResponsive.of(context).isWide;

    // Create screen dynamically for select-location based on context
    Widget screen;
    if (app.screen == 'select-location') {
      screen = SelectLocationScreen(forHomeLocation: app.selectLocationForHome);
    } else {
      screen = _screens[app.screen] ?? const HomeScreen();
    }

    return PopScope(
      // Custom stack is not a Flutter Navigator route — intercept OS back.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Allow real Navigator overlays (dialogs / bottom sheets) to close first.
        final nav = Navigator.of(context);
        if (nav.canPop()) {
          nav.pop();
          return;
        }
        final shouldExit = app.handleSystemBack();
        if (shouldExit) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: !isSplash,
        backgroundColor: isSplash
            ? const Color(0xFF2A0E1C)
            : (isWide ? AppColors.paleWarmBg : Colors.white),
        extendBody: true,
        body: Stack(
          children: [
            Positioned.fill(
              child: ResponsiveBody(
                fullBleed: isSplash,
                child: ColoredBox(
                  color: isSplash ? Colors.transparent : Colors.white,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    // Default layoutBuilder centers children with loose constraints,
                    // which shrinks+centers any screen whose content is shorter than
                    // the viewport (e.g. a short list) instead of filling it — force
                    // every screen to fill the full available area instead.
                    layoutBuilder: (currentChild, previousChildren) => Stack(
                      fit: StackFit.expand,
                      children: [
                        ...previousChildren,
                        ?currentChild,
                      ],
                    ),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.03),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(key: ValueKey(app.screen), child: screen),
                  ),
                ),
              ),
            ),
            if (app.showTabBar)
              const Positioned(left: 0, right: 0, bottom: 0, child: DockNav()),
            if (app.hasCart && app.screen != 'cart' && app.screen != 'menu' && app.screen != 'select-location' && app.screen != 'splash' && app.screen != 'onboarding')
              Positioned(
                left: 16,
                right: 16,
                bottom: app.showTabBar ? MediaQuery.paddingOf(context).bottom + 92 : 20,
                child: GestureDetector(
                  onTap: app.toCart,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.30),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${app.cartCount} item${app.cartCount > 1 ? 's' : ''} · ₹${app.grandTotal}',
                              style: AppText.body(size: 14, weight: FontWeight.w800, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'View cart',
                              style: AppText.body(size: 12, weight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.90)),
                            ),
                          ],
                        ),
                        const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 22),
                      ],
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
