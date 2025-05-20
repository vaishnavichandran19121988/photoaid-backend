import 'dart:convert';
import 'dart:io';
import 'package:backend/services/session_service.dart';

Future<void> handleHelperHistory(HttpRequest request, int userId) async {
  print('[SessionRoutes] 🟢 handleHelperHistory called by user $userId');

  try {
    final sessions = await SessionService().getPastSessionsForUser(userId);
    final helperHistory = (sessions['sessions'] as List)
        .where((s) => s['helper_id'] == userId)
        .toList();

    request.response
      ..statusCode = 200
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({
        'success': true,
        'sessions': helperHistory,
      }))
      ..close();
  } catch (e, st) {
    print("❌ Exception in handleHelperHistory: $e\n$st");
    request.response
      ..statusCode = 500
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'success': false, 'message': 'Internal server error'}))
      ..close();
  }
}
