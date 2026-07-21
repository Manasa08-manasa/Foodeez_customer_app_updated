import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';

/// Opens Razorpay checkout using `keyId` + `razorpayOrderId` from the backend
/// (`POST /customer/payments/initiate`) — same flow as the customer website.
class RazorpayCheckout {
  RazorpayCheckout._();

  static Razorpay? _razorpay;
  static Completer<Map<String, String>>? _completer;

  static Future<Map<String, String>> open({
    required String keyId,
    required int amount,
    required String currency,
    required String razorpayOrderId,
    String? name,
    String? email,
    String? contact,
    String? description,
  }) async {
    _dispose();
    _razorpay = Razorpay();
    _completer = Completer<Map<String, String>>();

    void completeSuccess(PaymentSuccessResponse response) {
      if (_completer == null || _completer!.isCompleted) return;
      _completer!.complete({
        'paymentId': response.paymentId ?? '',
        'orderId': response.orderId ?? razorpayOrderId,
        'signature': response.signature ?? '',
      });
    }

    void completeError(Object error) {
      if (_completer == null || _completer!.isCompleted) return;
      _completer!.completeError(error);
    }

    _razorpay!
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, completeSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
        final msg = response.message ?? 'Payment failed';
        if (response.code == Razorpay.PAYMENT_CANCELLED) {
          completeError(Exception('Payment cancelled'));
        } else {
          completeError(Exception(msg));
        }
      })
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {});

    final options = <String, dynamic>{
      'key': keyId,
      'amount': amount,
      'currency': currency,
      'order_id': razorpayOrderId,
      'name': name ?? 'FooDeeZ',
      if (description != null && description.isNotEmpty) 'description': description,
      'theme': {'color': '#6E2A4D'},
      'prefill': {
        if (name != null && name.isNotEmpty) 'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
        if (contact != null && contact.isNotEmpty) 'contact': contact,
      },
    };

    _razorpay!.open(options);
    return _completer!.future.whenComplete(_dispose);
  }

  static void _dispose() {
    _razorpay?.clear();
    _razorpay = null;
    _completer = null;
  }
}
