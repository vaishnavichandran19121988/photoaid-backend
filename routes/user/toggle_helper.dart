import 'dart:convert';
import 'dart:io';
import 'package:backend/repositories/user_repository.dart';

Future<void> handleToggleHelper(HttpRequest request, int userId) async {
  try {
    final content = await utf8.decoder.bind(request).join();
    final data = jsonDecode(content) as Map<String, dynamic>;

    final isAvailable = data['is_available'];
    if (isAvailable == null || isAvailable is! bool) {
      request.response
        ..statusCode = 400
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({
          'success': false,
          'message': 'Missing or invalid is_available field',
        }))
        ..close();
      return;
    }

    final userRepo = UserRepository();
    final success = await userRepo.updateAvailability(
      userId: userId,
      isAvailable: isAvailable,
    );

    if (!success) {
      request.response
        ..statusCode = 500
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({
          'success': false,
          'message': 'Failed to update availability',
        }))
        ..close();
      return;
    }

    // ✅ Fetch and return full updated user object
    final user = await userRepo.getUserById(userId);

    request.response
      ..statusCode = 200
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({
        'success': true,
        'user': user?.toJson(), // This is critical for the frontend!
      }))
      ..close();
  } catch (e) {
    print('❌ Error in handleToggleHelper: $e');
    request.response
      ..statusCode = 500
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({
        'success': false,
        'message': 'Internal server error',
        'error': e.toString(),
      }))
      ..close();
  }
}
