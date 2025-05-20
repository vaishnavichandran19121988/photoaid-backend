import 'dart:convert';
import 'dart:io';

import 'package:backend/services/session_service.dart';

Future<void> handleGetSessionById(HttpRequest request, int userId) async {
  final sessionId = int.tryParse(request.uri.pathSegments.last);

  if (sessionId == null) {
    request.response
      ..statusCode = HttpStatus.badRequest
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'success': false, 'message': 'Invalid session ID'}))
      ..close();
    return;
  }

  final session = await SessionService().findById(sessionId);

  if (session == null) {
    request.response
      ..statusCode = HttpStatus.notFound
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'success': false, 'message': 'Session not found'}))
      ..close();
    return;
  }

  request.response
    ..statusCode = HttpStatus.ok
    ..headers.contentType = ContentType.json
    ..write(jsonEncode({
      'success': true,
      'message': 'Session found',
      'session': session.toJson(), // ✅ Fix applied here
    }))
    ..close();
}
