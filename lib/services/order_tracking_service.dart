import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../core/constants/env.dart';
import 'api_config.dart';
import 'token_store.dart';

/// Live order tracking via Socket.IO `/customer-tracking` (website parity).
class OrderTrackingService {
  OrderTrackingService();

  io.Socket? _socket;
  String? _joinedOrderId;

  final _controller = StreamController<OrderTrackingEvent>.broadcast();
  Stream<OrderTrackingEvent> get events => _controller.stream;

  bool get isConnected => _socket?.connected == true;

  Future<void> connectAndJoin(String orderId) async {
    if (orderId.isEmpty) return;
    await _ensureConnected();
    if (_joinedOrderId == orderId && isConnected) return;
    _joinedOrderId = orderId;
    _socket?.emit('join-order', {'orderId': orderId});
    debugPrint('[OrderTracking] join-order $orderId');
  }

  Future<void> _ensureConnected() async {
    if (_socket != null && isConnected) return;

    final origin = ApiConfig.backendOrigin.isNotEmpty
        ? ApiConfig.backendOrigin
        : Env.productionApiBaseUrl.replaceFirst(RegExp(r'/customer/api/v1/?$'), '');
    final socketUrl = '$origin/customer-tracking';

    _socket?.dispose();
    _socket = io.io(
      socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setPath('/socket.io')
          .setQuery({'EIO': '4', 'transport': 'websocket'})
          .disableAutoConnect()
          .build(),
    );

    final ready = Completer<void>();

    _socket!.onConnect((_) {
      debugPrint('[OrderTracking] connected');
      if (TokenStore.isLoggedIn && TokenStore.token != null) {
        _socket!.emit('authenticate', {'token': TokenStore.token});
      }
      if (_joinedOrderId != null) {
        _socket!.emit('join-order', {'orderId': _joinedOrderId});
      }
      if (!ready.isCompleted) ready.complete();
    });

    _socket!.onConnectError((e) {
      debugPrint('[OrderTracking] connect error: $e');
      if (!ready.isCompleted) ready.complete();
    });

    _socket!.on('order:status', (data) {
      final map = _asMap(data);
      if (map == null) return;
      _controller.add(OrderTrackingEvent(
        type: OrderTrackingEventType.status,
        orderId: map['orderId']?.toString(),
        status: (map['status'] ?? map['orderStatus'])?.toString(),
        statusLabel: map['statusLabel']?.toString(),
        raw: map,
      ));
    });

    _socket!.on('rider:location', (data) {
      final map = _asMap(data);
      if (map == null) return;
      _controller.add(OrderTrackingEvent(
        type: OrderTrackingEventType.riderLocation,
        orderId: map['orderId']?.toString(),
        latitude: _toDouble(map['latitude'] ?? map['riderLatitude']),
        longitude: _toDouble(map['longitude'] ?? map['riderLongitude']),
        speed: _toDouble(map['speed'] ?? map['riderSpeed']),
        raw: map,
      ));
    });

    _socket!.on('order:eta', (data) {
      final map = _asMap(data);
      if (map == null) return;
      final eta = map['etaMins'] ?? map['eta'];
      _controller.add(OrderTrackingEvent(
        type: OrderTrackingEventType.eta,
        orderId: map['orderId']?.toString(),
        etaMins: eta is num ? eta.round() : int.tryParse('$eta'),
        raw: map,
      ));
    });

    _socket!.on('order:delay', (data) {
      final map = _asMap(data);
      if (map == null) return;
      _controller.add(OrderTrackingEvent(
        type: OrderTrackingEventType.delay,
        orderId: map['orderId']?.toString(),
        delayMessage: (map['message'] ?? map['delayMessage'])?.toString(),
        raw: map,
      ));
    });

    _socket!.connect();
    await ready.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {},
    );
  }

  void leave() {
    _joinedOrderId = null;
  }

  void dispose() {
    leave();
    _socket?.dispose();
    _socket = null;
    if (!_controller.isClosed) _controller.close();
  }

  static Map<String, dynamic>? _asMap(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  static double? _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v');
  }
}

enum OrderTrackingEventType { status, riderLocation, eta, delay }

class OrderTrackingEvent {
  const OrderTrackingEvent({
    required this.type,
    this.orderId,
    this.status,
    this.statusLabel,
    this.latitude,
    this.longitude,
    this.speed,
    this.etaMins,
    this.delayMessage,
    this.raw,
  });

  final OrderTrackingEventType type;
  final String? orderId;
  final String? status;
  final String? statusLabel;
  final double? latitude;
  final double? longitude;
  final double? speed;
  final int? etaMins;
  final String? delayMessage;
  final Map<String, dynamic>? raw;
}
