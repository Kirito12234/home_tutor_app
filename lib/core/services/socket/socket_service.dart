import 'dart:convert';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../api/api_endpoints.dart';
import '../hive/hive_service.dart';

class SocketService {
  SocketService._internal();

  static final SocketService _instance = SocketService._internal();

  factory SocketService() => _instance;

  io.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  void connect() {
    if (_socket != null) {
      if (isConnected) {
        return;
      }
      _socket?.connect();
      return;
    }

    final socket = io.io(
      socketBaseUrl(),
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableReconnection()
          .setReconnectionAttempts(20)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setTimeout(20000)
          .disableAutoConnect()
          .build(),
    );
    _socket = socket;

    socket.on('connect', (_) {
      final userId = _currentUserId;
      if (userId != null && userId.isNotEmpty) {
        socket.emit('join', {'userId': userId});
      }
    });

    socket.connect();
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }

  void joinUser() {
    final userId = _currentUserId;
    if (userId != null && userId.isNotEmpty) {
      _socket?.emit('join', {'userId': userId});
    }
  }

  void joinThread(String threadId) {
    if (threadId.isEmpty) {
      return;
    }
    _socket?.emit('joinThread', {'threadId': threadId});
  }

  void leaveThread(String threadId) {
    if (threadId.isEmpty) {
      return;
    }
    _socket?.emit('leaveThread', {'threadId': threadId});
  }

  void onMessageNew(void Function(dynamic payload) handler) {
    _socket?.on('message:new', handler);
  }

  void offMessageNew([void Function(dynamic payload)? handler]) {
    _socket?.off('message:new', handler);
  }

  void onThreadNew(void Function(dynamic payload) handler) {
    _socket?.on('thread:new', handler);
  }

  void offThreadNew([void Function(dynamic payload)? handler]) {
    _socket?.off('thread:new', handler);
  }

  void onNotificationNew(void Function(dynamic payload) handler) {
    _socket?.on('notification:new', handler);
  }

  void offNotificationNew([void Function(dynamic payload)? handler]) {
    _socket?.off('notification:new', handler);
  }

  String? get _currentUserId {
    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      return null;
    }
    final parts = token.split('.');
    if (parts.length < 2) {
      return null;
    }
    try {
      final payload = base64Url.decode(base64Url.normalize(parts[1]));
      final decoded = jsonDecode(utf8.decode(payload));
      if (decoded is Map<String, dynamic>) {
        final id = decoded['id'] ?? decoded['_id'] ?? decoded['userId'];
        return id?.toString();
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}


