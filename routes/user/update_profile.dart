import 'dart:convert';
import 'dart:io';
import 'package:backend/services/auth_service.dart';
import 'package:backend/utils/jwt_utils.dart';


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
    final profileImageUrl = data['profile_image_url'] as String?;

    final result = await AuthService().updateProfile(
      userId: userId,
      fullName: fullName,
      bio: bio,
      email: email,
      profileImageUrl: profileImageUrl, // use URL from upload step
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
