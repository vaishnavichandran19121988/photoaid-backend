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

Future<void> handleGetUserRatingStats(HttpRequest request, int userId) async {
  print('[RatingHandler] 📊 handleGetUserRatingStats(userId=$userId)');

  try {
    final stats = await _ratingService.getUserRatingStats(userId);

    print('[RatingHandler] ✅ Stats fetched: avg=${stats['average']}, count=${stats['count']}');

    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({
        'success': true,
        'stats': stats,
      }))
      ..close();
  } catch (e, stack) {
    print('[RatingHandler] ❌ Error in handleGetUserRatingStats: $e');
    print(stack);
    request.response
      ..statusCode = HttpStatus.internalServerError
      ..write(jsonEncode({'success': false, 'message': 'Error: $e'}))
      ..close();
  }
}
