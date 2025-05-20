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

Future<void> handleSubmitRating(HttpRequest request, int raterId) async {
  try {
    print('[RatingHandler] 📥 Incoming rating submission');

    final content = await utf8.decoder.bind(request).join();
    final data = jsonDecode(content);

    final sessionId = data['sessionId'] as int?;
    final ratedUserId = data['ratedUserId'] as int?;
    final score = (data['score'] as num?)?.toInt(); // ✅ fixes double to int cast

    final comment = data['comment'] as String?;

    print('[RatingHandler] 🧾 Parsed: sessionId=$sessionId, ratedUserId=$ratedUserId, score=$score');

    // Basic validation
    if (sessionId == null || ratedUserId == null || score == null) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write(jsonEncode({
          'success': false,
          'message': 'Missing required fields',
        }))
        ..close();
      return;
    }

    final rating = await _ratingService.submitRating(
      sessionId,
      raterId,
      ratedUserId,
      score,
      comment,
    );

    if (rating == null) {
      print('[RatingHandler] ❌ Failed to save rating');
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write(jsonEncode({'success': false, 'message': 'Could not save rating'}))
        ..close();
      return;
    }

    print('[RatingHandler] ✅ Rating saved with ID: ${rating.id}');

    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({
        'success': true,
        'message': 'Rating submitted',
        'rating': rating.toJson(),
      }))
      ..close();
  } catch (e, stack) {
    print('[RatingHandler] ❌ Error in handleSubmitRating: $e');
    print(stack);
    request.response
      ..statusCode = HttpStatus.internalServerError
      ..write(jsonEncode({'success': false, 'message': 'Error: $e'}))
      ..close();
  }
}
