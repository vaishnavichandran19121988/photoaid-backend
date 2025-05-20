import 'dart:convert';
import 'dart:io';
import 'package:backend/services/session_service.dart';

Future<void> handleTouristHistory(HttpRequest request, int userId) async {
  print('[SessionRoutes] 🟢 handleTouristHistory called by user $userId');

  try {
    final sessions = await SessionService().getPastSessionsForUser(userId);
    final touristHistory = (sessions['sessions'] as List)
        .where((s) => s['requester_id'] == userId)
        .toList();

    request.response
      ..statusCode = 200
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({
        'success': true,
        'sessions': touristHistory,
      }))
      ..close();
  } catch (e, st) {
    print("❌ Exception in handleTouristHistory: $e\n$st");
    request.response
      ..statusCode = 500
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'success': false, 'message': 'Internal server error'}))
      ..close();
  }
}
