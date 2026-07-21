import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_controller.dart';

/// Single source of truth for app-wide state (navigation stack, cart,
/// bookings, chat, filters, etc). Exposed as a [ChangeNotifierProvider] so
/// the existing `AppController` (Controller layer) can keep using
/// `notifyListeners()` internally while views read/react to it through
/// Riverpod instead of package:provider.
///
/// Views should read it with:
///   final app = ref.watch(appControllerProvider);      // rebuilds on change
///   final app = ref.read(appControllerProvider);        // one-off read/action
final appControllerProvider = ChangeNotifierProvider<AppController>((ref) {
  return AppController();
});
