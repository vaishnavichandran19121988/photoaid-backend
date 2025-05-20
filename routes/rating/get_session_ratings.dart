import 'dart:convert';
import 'dart:io';
import 'package:backend/services/rating_service.dart';
import 'package:backend/services/rating_service.dart';
import 'package:backend/repositories/rating_repository.dart';
import 'package:backend/repositories/session_repository.dart';
import 'package:backend/repositories/user_repository.dart';

final _ratingService = RatingService(
  RatingRepository(),
  SessionRepository(),
  UserRepository(),
);

Future<void> handleGetSessionRatings(HttpRequest request, int sessionId) async {
  print('[RatingHandler] 📦 handleGetSessionRatings(sessionId=$sessionId)');

  try {
    final ratings = await _ratingService.getSessionRatings(sessionId);
    print('[RatingHandler] ✅ Found ${ratings.length} rating(s) for session');

    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({
        'success': true,
        'ratings': ratings.map((r) => r.toJson()).toList(),
      }))
      ..close();
  } catch (e, stack) {
    print('[RatingHandler] ❌ Error in handleGetSessionRatings: $e');
    print(stack);
    request.response
      ..statusCode = HttpStatus.internalServerError
      ..write(jsonEncode({'success': false, 'message': 'Error: $e'}))
      ..close();
  }
}
