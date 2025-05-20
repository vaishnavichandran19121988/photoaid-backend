import 'dart:convert';
import 'dart:io';
import 'package:backend/repositories/chat_repository.dart';
import 'package:backend/models/chat_message.dart';

Future<void> handleSendChatMessage(HttpRequest request, int senderId) async {
  try {
    // Extract session ID from URI
    final segments = request.uri.pathSegments;
    final sessionIdStr = segments.length >= 4 ? segments[3] : null;
    final sessionId = int.tryParse(sessionIdStr ?? '');

    if (sessionId == null) {
      request.response
        ..statusCode = 400
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'success': false, 'message': 'Invalid session ID'}))
        ..close();
      return;
    }

    final content = await utf8.decoder.bind(request).join();
    final data = jsonDecode(content) as Map<String, dynamic>;

    final receiverId = data['receiver_id'];
    final message = data['message'];

    if (receiverId == null || message == null || message.trim().isEmpty) {
      request.response
        ..statusCode = 400
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({
          'success': false,
          'message': 'receiver_id and non-empty message are required'
        }))
        ..close();
      return;
    }

    final chat = ChatMessage(
      id: 0,
      sessionId: sessionId,
      senderId: senderId,
      receiverId: receiverId,
      content: message.trim(),
      sentAt: DateTime.now(),
      isRead: false,
    );

    final repo = ChatRepository();
    final saved = await repo.insertMessage(chat);

    if (saved == null) {
      request.response
        ..statusCode = 500
        ..headers.contentType = ContentType.json
        ..write(
            jsonEncode({'success': false, 'message': 'Failed to save message'}))
        ..close();
      return;
    }

    request.response
      ..statusCode = 201
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'success': true, 'message': saved.toJson()}))
      ..close();
  } catch (e, st) {
    print('❌ Error in handleSendChatMessage: $e\n$st');
    request.response
      ..statusCode = 500
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'success': false, 'message': 'Server error'}))
      ..close();
  }
}
