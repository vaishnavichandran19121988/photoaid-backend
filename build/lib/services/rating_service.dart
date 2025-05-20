import '../models/rating.dart';
import '../models/session.dart';
import '../repositories/rating_repository.dart';
import '../repositories/session_repository.dart';
import '../repositories/user_repository.dart';

/// Service for rating operations
class RatingService {
  final RatingRepository _ratingRepository;
  final SessionRepository _sessionRepository;
  final UserRepository _userRepository;

  RatingService(
      this._ratingRepository, this._sessionRepository, this._userRepository);

  /// Submit a rating for a session
  Future<Rating?> submitRating(int sessionId, int raterId, int ratedUserId,
      int rating, String? comment) async {
    try {
      // 1. Verify the session exists and is completed
      final session = await _sessionRepository.findById(sessionId);
      if (session == null) {
        throw Exception('Session not found');
      }

      // 2. Check that the session is completed (can only rate completed sessions)
      if (session.status != SessionStatus.completed) {
        throw Exception('Cannot rate a session that is not completed');
      }

      // 3. Verify that the rater is a participant in the session
      if (session.requesterId != raterId && session.helperId != raterId) {
        throw Exception('User is not a participant in this session');
      }

      // 4. Verify that the rated user is the other participant in the session
      final otherUserId = session.requesterId == raterId
          ? session.helperId
          : session.requesterId;
      if (otherUserId != ratedUserId) {
        throw Exception('Can only rate the other participant in the session');
      }

      // 5. Validate rating value (1-5)
      if (rating < 1 || rating > 5) {
        throw Exception('Rating must be between 1 and 5');
      }

      // 6. Create the rating
      final ratingModel = Rating(
        sessionId: sessionId,
        raterId: raterId,
        ratedId: ratedUserId,
        rating: rating,
        comment: comment,
      );

      return await _ratingRepository.createRating(ratingModel);
    } catch (e) {
      print('Error submitting rating: $e');
      throw Exception('Failed to submit rating: ${e.toString()}');
    }
  }

  /// Get all ratings for a specific user
  Future<List<Rating>> getUserRatings(int userId) async {
    try {
      return await _ratingRepository.findByRatedUserId(userId);
    } catch (e) {
      print('Error getting user ratings: $e');
      throw Exception('Failed to get user ratings: ${e.toString()}');
    }
  }

  /// Get a user's average rating
  Future<double?> getUserAverageRating(int userId) async {
    try {
      return await _ratingRepository.getUserAverageRating(userId);
    } catch (e) {
      print('Error getting user average rating: $e');
      throw Exception('Failed to get user average rating: ${e.toString()}');
    }
  }

  /// Get rating statistics for a user
  Future<Map<String, dynamic>> getUserRatingStats(int userId) async {
    try {
      return await _ratingRepository.getRatingStats(userId);
    } catch (e) {
      print('Error getting user rating stats: $e');
      throw Exception('Failed to get user rating statistics: ${e.toString()}');
    }
  }

  /// Check if a user has already submitted a rating for a session
  Future<bool> hasUserRatedSession(int sessionId, int raterId) async {
    try {
      // Find the session to determine who was rated
      final session = await _sessionRepository.findById(sessionId);
      if (session == null) {
        throw Exception('Session not found');
      }

      // Determine which user was rated by this rater
      final ratedUserId = session.requesterId == raterId
          ? session.helperId
          : session.requesterId;
      if (ratedUserId == null) {
        // Helper ID can be null in pending sessions
        return false;
      }

      // Check for existing ratings
      final sessionRatings = await _ratingRepository.findBySessionId(sessionId);
      return sessionRatings
          .any((r) => r.raterId == raterId && r.ratedId == ratedUserId);
    } catch (e) {
      print('Error checking if user rated session: $e');
      throw Exception('Failed to check if user rated session: ${e.toString()}');
    }
  }

  /// Get ratings for a specific session
  Future<List<Rating>> getSessionRatings(int sessionId) async {
    try {
      return await _ratingRepository.findBySessionId(sessionId);
    } catch (e) {
      print('Error getting session ratings: $e');
      throw Exception('Failed to get session ratings: ${e.toString()}');
    }
  }
}
