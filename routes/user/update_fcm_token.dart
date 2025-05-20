// routes/user/update_fcm_token.dart
import 'dart:convert';
import 'dart:io';
import 'package:backend/repositories/user_repository.dart';

/// Handles updating the helper's FCM token
Future<void> handleUpdateFcmToken(HttpRequest request, int userId) async {
  try {
    final body = await utf8.decoder.bind(request).join();
    final data = jsonDecode(body) as Map<String, dynamic>;
    final token = data['fcm_token'] as String?;

    if (token == null || token.isEmpty) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'success': false, 'message': 'Missing fcm_token'}))
        ..close();
      return;
    }

    // Update the token in the DB
    await UserRepository().updateFcmToken(userId, token);

    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'success': true, 'message': 'FCM token updated'}))
      ..close();
  } catch (e, st) {
    print('❌ Error in handleUpdateFcmToken: $e\n$st');
    request.response
      ..statusCode = HttpStatus.internalServerError
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'success': false, 'message': 'Internal server error'}))
      ..close();
  }
}
