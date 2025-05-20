import 'dart:convert';
import 'dart:io';
import 'package:backend/services/auth_service.dart';
import 'package:backend/utils/jwt_utils.dart';

/*
 * Handles profile updates: name, bio, email, and image (base64 or single file field).
 * Simplified: works without MimeMultipartTransformer or external packages.
 */
Future<void> handleUpdateProfile(HttpRequest request) async {
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
      ..statusCode = 401
      ..write(jsonEncode({'success': false, 'message': 'Invalid or expired token'}))
      ..close();
    return;
  }

  try {
    final body = await utf8.decoder.bind(request).join();
    final data = jsonDecode(body);

    final fullName = data['full_name'] as String?;
    final bio = data['bio'] as String?;
    final email = data['email'] as String?;
    String? imagePath;

    // ✅ Handle base64 image upload (optional)
    if (data['profile_image_base64'] != null) {
      final base64Image = data['profile_image_base64'];
      final bytes = base64Decode(base64Image);
      final uploadDir = Directory('uploads/profile_images');
      if (!await uploadDir.exists()) await uploadDir.create(recursive: true);

      final relativePath = 'uploads/profile_images/$userId.jpg';
      final file = File(relativePath);
      await file.writeAsBytes(bytes);

// 🔥 Replace this with your real backend IP/port if not using localhost

      final baseUrl = 'http://192.168.1.23:8080';
      imagePath = '$baseUrl/$relativePath'; // ✅ This is stored in DB and sent to frontend

    }

    final result = await AuthService().updateProfile(
      userId: userId,
      fullName: fullName,
      bio: bio,
      email: email,
      profileImageUrl: imagePath,
    );

    request.response
      ..statusCode = result['success'] ? 200 : 400
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(result))
      ..close();
  } catch (e) {
    print('❌ Error updating profile: $e');
    request.response
      ..statusCode = 500
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'success': false, 'message': 'Server error: $e'}))
      ..close();
  }
}
