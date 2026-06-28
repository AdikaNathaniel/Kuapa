import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../core/constants/api_constants.dart';

class ChatSocketService {
  ChatSocketService._();
  static final ChatSocketService instance = ChatSocketService._();

  io.Socket? _socket;
  String? _currentUserId;

  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingController  = StreamController<Map<String, dynamic>>.broadcast();
  final _connectedController = StreamController<bool>.broadcast();

  Stream<Map<String, dynamic>> get messageStream   => _messageController.stream;
  Stream<Map<String, dynamic>> get typingStream    => _typingController.stream;
  Stream<bool>                 get connectedStream => _connectedController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void connect(String userId) {
    if (_socket != null && _currentUserId == userId && _socket!.connected) return;

    _currentUserId = userId;
    _socket?.dispose();

    _socket = io.io(
      ApiConstants.wsUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setQuery({'userId': userId})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(2000)
          .build(),
    );

    _socket!
      ..onConnect((_) {
        debugPrint('[Chat] Socket connected');
        _connectedController.add(true);
      })
      ..onDisconnect((_) {
        debugPrint('[Chat] Socket disconnected');
        _connectedController.add(false);
      })
      ..onConnectError((e) => debugPrint('[Chat] Connect error: $e'))
      ..on('new_message', (data) {
        if (data is Map) {
          _messageController.add(Map<String, dynamic>.from(data));
        }
      })
      ..on('user_typing', (data) {
        if (data is Map) {
          _typingController.add(Map<String, dynamic>.from(data));
        }
      });
  }

  void joinConversation(String conversationId) {
    _socket?.emit('join_conversation', {'conversationId': conversationId});
  }

  void sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String content,
  }) {
    _socket?.emit('send_message', {
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
    });
  }

  void sendTyping({
    required String conversationId,
    required String userId,
    required bool isTyping,
  }) {
    _socket?.emit('typing', {
      'conversationId': conversationId,
      'userId': userId,
      'isTyping': isTyping,
    });
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _currentUserId = null;
  }
}
