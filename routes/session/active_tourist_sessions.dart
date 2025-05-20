import 'dart:convert';
import 'dart:io';
import 'package:backend/services/session_service.dart';

Future<void> handleActiveTouristSessions(HttpRequest request, int userId) async {
  print('[SessionRoutes] 🟢 handleActiveTouristSessions called by user $userId');

  try {
    final sessions = await SessionService().getActiveSessionsForUser(userId);
    final touristSessions = (sessions['sessions'] as List)
        .where((s) => s['requester_id'] == userId)
        .toList();

    request.response
      ..statusCode = 200
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({
        'success': true,
        'sessions': touristSessions,
      }))
      ..close();
  } catch (e, st) {
    print("❌ Exception in handleActiveTouristSessions: $e\n$st");
    request.response
      ..statusCode = 500
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'success': false, 'message': 'Internal server error'}))
      ..close();
  }
}
