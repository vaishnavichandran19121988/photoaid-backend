import 'dart:convert';
import 'dart:io';

import 'package:backend/repositories/user_repository.dart';



Future<void> handleGetMe(HttpRequest request, int userId) async {
  try {
    final userRepo = UserRepository();
    final userData = await userRepo.getUserById(userId);

    if (userData == null) {
      request.response
        ..statusCode = 404
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({
          'success': false,
          'message': 'User not found',
        }))
        ..close();
      return;
    }

    request.response
      ..statusCode = 200
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({
        'success': true,
        'user': userData.toJson(),
      }))
      ..close();
  } catch (e) {
    print('Error getting user profile: $e');
    request.response
      ..statusCode = 500
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({
        'success': false,
        'message': 'Error getting user profile: $e',
      }))
      ..close();
  }
}
