import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/constants/env.dart';
import '../models/chat_message.dart';
import 'token_store.dart';

enum SupportChatEventType {
  connected,
  authenticated,
  sessionStarted,
  messageReceived,
  error,
  closed,
}

class SupportChatEvent {
  const SupportChatEvent({
    required this.type,
    this.sessionId,
    this.messages,
    this.message,
    this.error,
    this.helplineNumber,
  });

  final SupportChatEventType type;
  final String? sessionId;
  final List<ChatMessage>? messages;
  final ChatMessage? message;
  final String? error;
  final String? helplineNumber;
}

class SupportChatService {
  SupportChatService();

  final StreamController<SupportChatEvent> _controller = StreamController.broadcast();
  Stream<SupportChatEvent> get events => _controller.stream;

  io.Socket? _socket;
  bool _connected = false;
  bool _authenticated = false;
  Completer<String>? _sessionCompleter;
  Completer<void>? _connectCompleter;
  Completer<void>? _authCompleter;

  bool get isConnected => _connected;
  bool get isAuthenticated => _authenticated;

  Future<void> connect() async {
    if (_socket != null && _connected) return;
    final completer = Completer<void>();
    _connectCompleter = completer;

    final uri = Env.productionApiBaseUrl.replaceFirst(RegExp(r'/customer/api/v1/?$'), '');
    final socketUrl = '$uri/customer-support-chat';

    _socket = io.io(
      socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setPath('/socket.io')
          .setQuery({'EIO': '4', 'transport': 'websocket'})
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      _connected = true;
      _controller.add(const SupportChatEvent(type: SupportChatEventType.connected));
      _connectCompleter?.complete();
      _connectCompleter = null;
      if (TokenStore.isLoggedIn && TokenStore.token != null) {
        _socket!.emit('authenticate', {'token': TokenStore.token});
      } else {
        _controller.add(const SupportChatEvent(
          type: SupportChatEventType.error,
          error: 'Please sign in to access support chat.',
        ));
      }
    });

    _socket!.onConnectError((data) {
      _controller.add(SupportChatEvent(
        type: SupportChatEventType.error,
        error: 'Unable to connect to support chat: $data',
      ));
      _connectCompleter?.completeError(Exception('connect_error'));
      _connectCompleter = null;
    });

    _socket!.on('authenticated', (_) {
      _authenticated = true;
      _authCompleter?.complete();
      _authCompleter = null;
      _controller.add(const SupportChatEvent(type: SupportChatEventType.authenticated));
    });

    _socket!.on('auth-error', (data) {
      final message = data is Map ? data['message']?.toString() : null;
      _controller.add(SupportChatEvent(type: SupportChatEventType.error, error: message ?? 'Authentication failed.'));
      _authCompleter?.completeError(Exception(message ?? 'Authentication failed.'));
      _authCompleter = null;
    });

    _socket!.on('session-started', (data) {
      final payload = data is Map ? data : const {};
      final sessionId = payload['sessionId']?.toString();
      final messages = (payload['messages'] as List?)
          ?.map((item) => _mapMessage(item, fromCustomer: false))
          .whereType<ChatMessage>()
          .toList();
      if (sessionId != null) {
        _sessionCompleter?.complete(sessionId);
        _sessionCompleter = null;
      }
      _controller.add(SupportChatEvent(
        type: SupportChatEventType.sessionStarted,
        sessionId: sessionId,
        messages: messages ?? <ChatMessage>[],
      ));
    });

    _socket!.on('message', (data) {
      final payload = data is Map ? data : const {};
      final message = payload['message'];
      if (message is Map) {
        final mapped = _mapMessage(message, fromCustomer: false);
        if (mapped != null) {
          _controller.add(SupportChatEvent(type: SupportChatEventType.messageReceived, message: mapped));
        }
      }
    });

    _socket!.on('escalated', (data) {
      final payload = data is Map ? data : const {};
      _controller.add(SupportChatEvent(
        type: SupportChatEventType.messageReceived,
        message: ChatMessage(
          text: 'We have escalated this chat to a support specialist. Please call ${payload['helplineNumber'] ?? 'our helpline'} if you need urgent help.',
          fromCustomer: false,
          time: _formatTime(DateTime.now()),
        ),
      ));
    });

    _socket!.on('chat-error', (data) {
      final payload = data is Map ? data : const {};
      final message = payload['message']?.toString() ?? 'Chat request failed.';
      _controller.add(SupportChatEvent(type: SupportChatEventType.error, error: message));
    });

    _socket!.onDisconnect((_) {
      _connected = false;
      _authenticated = false;
      _controller.add(const SupportChatEvent(type: SupportChatEventType.closed));
    });

    _socket!.connect();
    await completer.future.timeout(const Duration(seconds: 10));
  }

  Future<String> startSession({String? orderId}) async {
    if (!_connected) await connect();
    if (!_authenticated) {
      if (!TokenStore.isLoggedIn || TokenStore.token == null || TokenStore.token!.isEmpty) {
        throw Exception('Please sign in to access support chat.');
      }
      final authCompleter = Completer<void>();
      _authCompleter = authCompleter;
      _socket!.emit('authenticate', {'token': TokenStore.token});
      await authCompleter.future.timeout(const Duration(seconds: 8));
    }

    final sessionCompleter = Completer<String>();
    _sessionCompleter = sessionCompleter;
    _socket!.emit('start-session', {'orderId': orderId});
    return sessionCompleter.future.timeout(const Duration(seconds: 10));
  }

  Future<void> sendMessage(String sessionId, String text) async {
    if (!_connected || !_authenticated) await startSession(orderId: null);
    _socket!.emit('send-message', {'sessionId': sessionId, 'message': text});
  }

  Future<void> closeSession(String sessionId) async {
    if (!_connected || !_authenticated) return;
    _socket!.emit('close-session', {'sessionId': sessionId});
  }

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _controller.close();
  }

  ChatMessage? _mapMessage(dynamic payload, {required bool fromCustomer}) {
    if (payload is! Map) return null;
    final sender = payload['sender']?.toString().toUpperCase();
    final messageText = payload['message']?.toString();
    if (messageText == null || messageText.isEmpty) return null;
    final rawTime = payload['createdAt']?.toString();
    final time = rawTime == null ? _formatTime(DateTime.now()) : _formatTime(DateTime.parse(rawTime));
    return ChatMessage(
      text: messageText,
      fromCustomer: sender == 'CUSTOMER' || fromCustomer,
      time: time,
    );
  }

  String _formatTime(DateTime value) {
    final h = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final m = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $suffix';
  }
}
