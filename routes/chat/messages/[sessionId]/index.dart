import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';

import '../../../services/chat_service.dart';
import '../../../repositories/chat_repository.dart';
import '../../../repositories/session_repository.dart';
import '../../../repositories/user_repository.dart';

Future<Response> onRequest(RequestContext context, String sessionIdParam) async {
  try {
    // 🔐 Extract user ID from Authorization header
    final authHeader = context.request.headers['Authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response.json(statusCode: 401, body: {'error': 'Missing auth token'});
    }

    final token = authHeader.replaceFirst('Bearer ', '');
    final parts = token.split('.');
    if (parts.length != 3) {
      return Response.json(statusCode: 400, body: {'error': 'Invalid token format'});
    }

    final payloadBase64 = base64.normalize(parts[1]);
    final payloadJson = utf8.decode(base64Url.decode(payloadBase64));
    final payload = jsonDecode(payloadJson);
    final userId = payload['userId'];
    if (userId == null) {
      return Response.json(statusCode: 401, body: {'error': 'Invalid token payload'});
    }

    // 🔍 Parse session ID
    final sessionId = int.tryParse(sessionIdParam);
    if (sessionId == null) {
      return Response.json(statusCode: 400, body: {'error': 'Invalid sessionId'});
    }

    // 🛠️ Load service & get messages
    final chatService = ChatService(
      ChatRepository(),
      SessionRepository(),
      UserRepository(),
    );

    final messages = await chatService.getSessionMessages(sessionId, userId);

    return Response.json(
      statusCode: 200,
      body: {
        'messages': messages.map((m) => m.toJson()).toList(),
      },
    );
  } catch (e) {
    print('❌ Error in GET /chat/messages/$sessionIdParam: $e');
    return Response.json(
      statusCode: 500,
      body: {'error': 'Failed to load messages', 'details': e.toString()},
    );
  }
}

