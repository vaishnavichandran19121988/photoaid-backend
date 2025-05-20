import 'dart:convert';
import 'dart:io';
import 'package:backend/services/session_service.dart';

final _sessionService = SessionService();

Future<void> handleGetFullSessionById(HttpRequest request, int userId) async {
  final path = request.uri.path;
  final sessionId = int.tryParse(path.split('/')[3]); // /api/sessions/:id/full

  if (sessionId == null) {
    request.response
      ..statusCode = HttpStatus.badRequest
      ..write(jsonEncode({'success': false, 'message': 'Invalid session ID'}))
      ..close();
    return;
  }

  final session = await _sessionService.findByIdWithUsers(sessionId);

  if (session == null) {
    request.response
      ..statusCode = HttpStatus.notFound
      ..write(jsonEncode({'success': false, 'message': 'Session not found'}))
      ..close();
    return;
  }

  request.response
    ..statusCode = HttpStatus.ok
    ..headers.contentType = ContentType.json
    ..write(jsonEncode({
      'success': true,
      'session': session.toJson(includeUsers: true) // ✅ Include full user info
    }))
    ..close();
}
