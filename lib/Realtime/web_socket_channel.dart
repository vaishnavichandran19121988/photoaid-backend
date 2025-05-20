import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:backend/models/chat_message.dart';
import 'package:backend/repositories/chat_repository.dart';

final Map<String, Map<String, WebSocket>> connectedClients = {};

Future<void> handleWebSocketChat(HttpRequest request) async {
  if (!WebSocketTransformer.isUpgradeRequest(request)) {
    request.response
      ..statusCode = HttpStatus.badRequest
      ..write('Not a websocket upgrade request')
      ..close();
    return;
  }

  final ws = await WebSocketTransformer.upgrade(request);
  final clientId = request.uri.queryParameters['userId'];
  final sessionId = request.uri.queryParameters['sessionId'];

  print('🔌 WebSocket connected: user $clientId for session $sessionId');

  // Store ws in a map for broadcasting
  connectedClients[sessionId] ??= {};
  connectedClients[sessionId]![clientId!] = ws;

  ws.listen((data) {
    final decoded = jsonDecode(data);
    final receiverId = decoded['receiverId'];
    final message = decoded['message'];

    // Optionally save to DB
    final chat = ChatMessage(
      id: 0,
      sessionId: int.parse(sessionId!),
      senderId: int.parse(clientId),
      receiverId: int.parse(receiverId),
      content: message,
      sentAt: DateTime.now(),
      isRead: false,
    );
    ChatRepository().insertMessage(chat);

    // Broadcast to receiver if connected
    final receiverSocket = connectedClients[sessionId]?[receiverId];
    if (receiverSocket != null) {
      receiverSocket.add(jsonEncode(chat.toJson()));
    }
  }, onDone: () {
    connectedClients[sessionId]?.remove(clientId);
    print('🔌 WebSocket disconnected: user $clientId');
  });
}
