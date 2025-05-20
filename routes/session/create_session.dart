import 'dart:convert';
import 'dart:io';
import 'package:backend/models/session.dart';
import 'package:backend/services/session_service.dart';

Future<void> handleCreateSession(HttpRequest request, int userId) async {
  print('[SessionRoutes] 🟢 handleCreateSession called by user $userId');

  try {
    final body = await utf8.decoder.bind(request).join();
    print("📥 Raw request body: $body"); // <== Add this
    final data = jsonDecode(body) as Map<String, dynamic>;
    print("📦 Parsed JSON: $data"); // <== Add this

    final session = Session(
      requesterId: data['requester_id'] as int,
      helperId: data['helper_id'] as int?,
      status: SessionStatus.pending,
      locationLat: (data['location_lat'] as num).toDouble(),
      locationLng: (data['location_lng'] as num).toDouble(),
      description: data['description'] as String?,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      completedAt: null,
    );

    final result = await SessionService().createSession(session);
    print("🧱 Creating Session with:");
    print("  requesterId: ${session.requesterId}");
    print("  helperId: ${session.helperId}");

    print('🔁 Backend result to send: $result');
    request.response
      ..statusCode = result['success'] ? 201 : 400
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(result))
      ..close();
  } catch (e, st) {
    print("❌ Exception in handleCreateSession: $e\n$st");
    request.response
      ..statusCode = 500
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'success': false, 'message': 'Internal server error'}))
      ..close();
  }
}
