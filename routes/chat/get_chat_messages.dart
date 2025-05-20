import 'dart:convert';
import 'dart:io';

import 'package:backend/repositories/chat_repository.dart';
import 'package:backend/repositories/session_repository.dart';
import 'package:backend/repositories/user_repository.dart';
import 'package:backend/services/chat_service.dart';


Future<void> handleGetChatMessages(HttpRequest request, int userId) async {
  try {
    // Extract session ID from the path
    final uri = request.uri;
    final match = RegExp(r'^/api/chat/messages/(\d+)$').firstMatch(uri.path);
    if (match == null) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'error': 'Invalid session path'}))
        ..close();
      return;
    }

    final sessionId = int.parse(match.group(1)!);

    final chatService = ChatService(
      ChatRepository(),
      SessionRepository(),
      UserRepository(),
    );

    final messages = await chatService.getSessionMessages(sessionId, userId);

    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({
        'messages': messages.map((m) => m.toJson()).toList(),
      }))
      ..close();
  } catch (e) {
    request.response
      ..statusCode = HttpStatus.internalServerError
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({
        'error': 'Failed to fetch messages',
        'details': e.toString(),
      }))
      ..close();
  }
}
