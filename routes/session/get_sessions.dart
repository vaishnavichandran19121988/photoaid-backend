import 'dart:convert';
import 'dart:io';
import 'package:backend/services/session_service.dart';

Future<void> handleGetSessions(HttpRequest request, int userId) async {
  print('[SessionRoutes] 🟢 handleGetSessions called by user $userId');

  try {
    final result = await SessionService().getSessionsByUserId(userId);
    final sessions = result['sessions'];

    print('📥 [Backend] Fetching sessions for userId=$userId');
    print('🔍 Found ${sessions.length} total sessions');

    request.response
      ..statusCode = 200
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(result))
      ..close();
  } catch (e, st) {
    print("❌ Exception in handleGetSessions: $e\n$st");
    request.response
      ..statusCode = 500
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'success': false, 'message': 'Internal server error'}))
      ..close();
  }
}
