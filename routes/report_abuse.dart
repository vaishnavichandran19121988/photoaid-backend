import 'dart:convert';
import 'dart:io';
import 'package:backend/services/abuse_service.dart';

Future<void> handleReportAbuse(HttpRequest request, int reporterId) async {
  try {
    print('🟠 [handleReportAbuse] Entry - Reporter ID: $reporterId');

    final content = await utf8.decoder.bind(request).join();
    final data = jsonDecode(content) as Map<String, dynamic>;

    // Extract fields
    final reportedUserId = data['reported_user_id'];
    final sessionId = data['session_id'];
    final reason = data['reason'] ?? '';

    print('🟠 [handleReportAbuse] Payload received:');
    print('  - reported_user_id: $reportedUserId');
    print('  - session_id: $sessionId');
    print('  - reason: $reason');

    // Basic validation
    if (reportedUserId == null || sessionId == null) {
      request.response
        ..statusCode = 400
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({
          'success': false,
          'message': 'reported_user_id and session_id are required'
        }))
        ..close();
      return;
    }

    // ✅ Call service layer
    final abuseService = AbuseService();
    final insertedId = await abuseService.createAbuseReport(
      reporterId: reporterId,
      reportedUserId: reportedUserId,
      sessionId: sessionId,
      reason: reason,
    );

    print('✅ [handleReportAbuse] Abuse report inserted successfully with ID: $insertedId');

    request.response
      ..statusCode = 201
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'success': true, 'id': insertedId}))
      ..close();
  } catch (e, st) {
    print('❌ Error in handleReportAbuse: $e\n$st');
    request.response
      ..statusCode = 500
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'success': false, 'message': 'Server error'}))
      ..close();
  }
}
