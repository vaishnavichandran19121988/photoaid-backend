import 'dart:convert';
import 'dart:io';
import 'package:backend/services/session_service.dart';

Future<void> handleIncomingRequests(HttpRequest request, int userId) async {
  print('[SessionRoutes] 🟢 handleIncomingRequests called by user $userId');

  try {
    final result = await SessionService().getActiveSessionsForUser(userId);

    request.response
      ..statusCode = 200
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(result))
      ..close();
  } catch (e, st) {
    print("❌ Exception in handleIncomingRequests: $e\n$st");
    request.response
      ..statusCode = 500
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'success': false, 'message': 'Internal server error'}))
      ..close();
  }
}
