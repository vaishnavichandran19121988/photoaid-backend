import 'dart:convert';
import 'dart:io';
import 'package:backend/services/auth_service.dart';
import 'package:backend/utils/jwt_utils.dart';

Future<void> handleGetUserProfile(HttpRequest request) async {
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

  final result = await AuthService().getUserProfile(userId);
  request.response
    ..statusCode = result['success'] ? 200 : 404
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(result))
    ..close();
}
