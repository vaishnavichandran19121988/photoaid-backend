import 'dart:convert';
import 'dart:io';
import 'package:backend/utils/jwt_utils.dart';
import 'package:backend/services/gcs_service.dart';

Future<void> handleUploadProfileImage(HttpRequest request) async {
  print('[UploadProfileImage] Incoming request: ${request.method} ${request.uri}');

  final authHeader = request.headers.value('authorization');
  if (authHeader == null || !authHeader.startsWith('Bearer ')) {
    print('[UploadProfileImage] Missing or invalid token');
    request.response
      ..statusCode = 401
      ..write(jsonEncode({'success': false, 'message': 'Missing or invalid token'}))
      ..close();
    return;
  }

  final token = authHeader.substring(7);
  final userId = JwtUtils.getUserIdFromToken(token);
  if (userId == null) {
    print('[UploadProfileImage] Invalid or expired token');
    request.response
      ..statusCode = 403
      ..write(jsonEncode({'success': false, 'message': 'Invalid or expired token'}))
      ..close();
    return;
  }

  try {
    final content = await utf8.decoder.bind(request).join();
    print('[UploadProfileImage] Request body: $content');
    final data = jsonDecode(content);
    final imageBase64 = data['imageBase64'];

    if (imageBase64 == null) {
      print('[UploadProfileImage] Missing imageBase64 in request');
      request.response
        ..statusCode = 400
        ..write(jsonEncode({'success': false, 'message': 'Missing imageBase64'}))
        ..close();
      return;
    }

    final imageBytes = base64Decode(imageBase64);
    String userIdStr = userId.toString();
    print('[UploadProfileImage] Uploading image for user: $userIdStr');

    final imageUrl = await uploadProfileImageToGCS(imageBytes, userIdStr);

    print('[UploadProfileImage] Image uploaded. Public URL: $imageUrl');

    request.response
      ..statusCode = 200
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'success': true, 'imageUrl': imageUrl}))
      ..close();
  } catch (e, stack) {
    print('[UploadProfileImage] ERROR: $e\n$stack');
    request.response
      ..statusCode = 500
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'success': false, 'message': 'Server error: $e'}))
      ..close();
  }
}
