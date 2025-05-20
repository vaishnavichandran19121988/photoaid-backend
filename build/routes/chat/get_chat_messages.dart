import 'dart:convert';
import 'dart:io';

import 'package:backend/repositories/chat_repository.dart';

Future<void> handleGetChatMessages(HttpRequest request, int userId) async {
  try {
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

    final repo = ChatRepository();
    final messages = await repo.findBySessionId(sessionId);

    request.response
      ..statusCode = 200
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({
        'success': true,
        'messages': messages.map((m) => m.toJson()).toList(),
      }))
      ..close();
  } catch (e, st) {
    print('❌ Error in handleGetChatMessages: $e\n$st');
    request.response
      ..statusCode = 500
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'success': false, 'message': 'Server error'}))
      ..close();
  }
}
