import 'dart:convert';
import 'dart:io';
import 'package:backend/services/session_service.dart';

Future<void> handleCancelSession(HttpRequest request, int userId) async {
  print('[SessionRoutes] 🟢 handleCancelSession called by user $userId');

  try {
    final segments = request.uri.pathSegments;
    final sessionIdStr = segments.length >= 3 ? segments[2] : null;
    final sessionId = int.tryParse(sessionIdStr ?? '');

    if (sessionId == null) {
      request.response
        ..statusCode = 400
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'success': false, 'message': 'Invalid session ID'}))
        ..close();
      return;
    }

    final result = await SessionService().cancelSession(sessionId, userId);

    if (!(result['success'] as bool)) {
      request.response
        ..statusCode = 404
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(result))
        ..close();
      return;
    }

    request.response
      ..statusCode = 200
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(result))
      ..close();
  } catch (e, st) {
    print("❌ Exception in handleCancelSession: $e\n$st");
    request.response
      ..statusCode = 500
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'success': false, 'message': 'Internal server error'}))
      ..close();
  }
}
