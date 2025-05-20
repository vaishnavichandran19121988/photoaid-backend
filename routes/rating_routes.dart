import 'dart:io';
import 'rating/submit_rating.dart';
import 'rating/get_user_ratings.dart';
import 'rating/get_user_stats.dart';
import 'rating/get_session_ratings.dart';
import 'rating/check_user_rated.dart';

class RatingRoutes {
  Future<bool> handleRequest(HttpRequest request, int userId) async {
    final path = request.uri.path;
    final method = request.method;

    print('[RatingRoutes] 🔍 $method $path');

    // POST /api/ratings
    if (path == '/api/ratings' && method == 'POST') {
      await handleSubmitRating(request, userId);
      return true;
    }

    // GET /api/ratings/user/:id
    final userRatingMatch = RegExp(r'^/api/ratings/user/(\d+)$').firstMatch(path);
    if (userRatingMatch != null && method == 'GET') {
      final id = int.parse(userRatingMatch.group(1)!);
      await handleGetUserRatings(request, id);
      return true;
    }

    // GET /api/ratings/user/:id/stats
    final statsMatch = RegExp(r'^/api/ratings/user/(\d+)/stats$').firstMatch(path);
    if (statsMatch != null && method == 'GET') {
      final id = int.parse(statsMatch.group(1)!);
      await handleGetUserRatingStats(request, id);
      return true;
    }

    // GET /api/ratings/session/:id
    final sessionMatch = RegExp(r'^/api/ratings/session/(\d+)$').firstMatch(path);
    if (sessionMatch != null && method == 'GET') {
      final id = int.parse(sessionMatch.group(1)!);
      await handleGetSessionRatings(request, id);
      return true;
    }

    // GET /api/ratings/session/:id/check
    final checkMatch = RegExp(r'^/api/ratings/session/(\d+)/check$').firstMatch(path);
    if (checkMatch != null && method == 'GET') {
      final id = int.parse(checkMatch.group(1)!);
      await handleCheckUserRated(request, userId, id);
      return true;
    }

    print('[RatingRoutes] ❌ No matching route.');
    return false;
  }
}
