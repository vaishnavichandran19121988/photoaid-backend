import 'dart:convert';
import 'dart:io';
import 'package:backend/utils/jwt_utils.dart';





Future<void> handleUploadProfileImage(HttpRequest request) async {
  final authHeader = request.headers.value('authorization');
  if (authHeader == null || !authHeader.startsWith('Bearer ')) {
    request.response
      ..statusCode = 401
      ..write(jsonEncode({'success': false, 'message': 'Missing or invalid token'}))
      ..close();
    return;
  }

  final token = authHeader.substring(7);
  final userId = JwtUtils.getUserIdFromToken(token);
  if (userId == null) {
    request.response
      ..statusCode = 403
      ..write(jsonEncode({'success': false, 'message': 'Invalid or expired token'}))
      ..close();
    return;
  }

  try {
    final content = await utf8.decoder.bind(request).join();
    final data = jsonDecode(content);
    final imageBase64 = data['imageBase64'];

    if (imageBase64 == null) {
      request.response
        ..statusCode = 400
        ..write(jsonEncode({'success': false, 'message': 'Missing imageBase64'}))
        ..close();
      return;
    }

    final imageBytes = base64Decode(imageBase64);
    final filePath = 'uploads/profile_images/$userId.jpg';

    final uploadDir = Directory('uploads/profile_images');
if (!await uploadDir.exists()) {
  await uploadDir.create(recursive: true);
}
    final file = File(filePath);
    await file.writeAsBytes(imageBytes);

 final imageUrl = 'https://fulfilling-creation-production.up.railway.app/$filePath';



    request.response
      ..statusCode = 200
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'success': true, 'imageUrl': imageUrl}))
      ..close();
  } catch (e) {
    request.response
      ..statusCode = 500
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'success': false, 'message': 'Server error: $e'}))
      ..close();
  }
}
