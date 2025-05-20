import 'dart:convert';
import 'dart:io';
import 'package:backend/services/rating_service.dart';
import 'package:backend/repositories/rating_repository.dart';
import 'package:backend/repositories/session_repository.dart';
import 'package:backend/repositories/user_repository.dart';


final _ratingService = RatingService(
  RatingRepository(),
  SessionRepository(),
  UserRepository(),
);

Future<void> handleCheckUserRated(HttpRequest request, int userId, int sessionId) async {
  print('[RatingHandler] 🤔 handleCheckUserRated(session=$sessionId, user=$userId)');

  try {
    final hasRated = await _ratingService.hasUserRatedSession(sessionId, userId);
    print('[RatingHandler] ✅ hasRated = $hasRated');

    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({
        'success': true,
        'hasRated': hasRated,
      }))
      ..close();
  } catch (e, stack) {
    print('[RatingHandler] ❌ Error in handleCheckUserRated: $e');
    print(stack);
    request.response
      ..statusCode = HttpStatus.internalServerError
      ..write(jsonEncode({
        'success': false,
        'message': 'Error: $e',
      }))
      ..close();
  }
}
