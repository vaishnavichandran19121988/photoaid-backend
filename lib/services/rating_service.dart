import '../models/rating.dart';
import '../models/session.dart';
import '../repositories/rating_repository.dart';
import '../repositories/session_repository.dart';
import '../repositories/user_repository.dart';

class RatingService {
  final RatingRepository _ratingRepository;
  final SessionRepository _sessionRepository;
  final UserRepository _userRepository;

  RatingService(
      this._ratingRepository, this._sessionRepository, this._userRepository);

  /// Submit a rating for a session
  Future<Rating?> submitRating(int sessionId, int raterId, int ratedUserId,
      int rating, String? comment) async {
    print('[RatingService] ➕ submitRating called: sessionId=$sessionId, raterId=$raterId, ratedUserId=$ratedUserId, rating=$rating');
    try {
      // 1. Verify session
      final session = await _sessionRepository.findById(sessionId);
      print('[RatingService] 🔍 Loaded session: $session');
      if (session == null) throw Exception('Session not found');

      // 2. Must be completed
      if (session.status != SessionStatus.completed) {
        print('[RatingService] ❌ Session not completed');
        throw Exception('Cannot rate a session that is not completed');
      }

      // 3. Rater must be participant
      if (session.requesterId != raterId && session.helperId != raterId) {
        print('[RatingService] ❌ User not a participant');
        throw Exception('User is not a participant in this session');
      }

      // 4. Rated user must be other participant
      final otherUserId = session.requesterId == raterId
          ? session.helperId
          : session.requesterId;
      if (otherUserId != ratedUserId) {
        print('[RatingService] ❌ Rated user is not the other participant');
        throw Exception('Can only rate the other participant in the session');
      }

      // 5. Rating value check
      if (rating < 1 || rating > 5) {
        print('[RatingService] ❌ Invalid rating value: $rating');
        throw Exception('Rating must be between 1 and 5');
      }

      // 6. Create rating
      final ratingModel = Rating(
        sessionId: sessionId,
        raterId: raterId,
        ratedId: ratedUserId,
        rating: rating,
        comment: comment,
      );

      print('[RatingService] 💾 Creating rating...');
      final savedRating = await _ratingRepository.createRating(ratingModel);
      print('[RatingService] ✅ Rating saved: ${savedRating?.toJson()}');

      print('[RatingService] 🔄 Updating user summary...');
      await _ratingRepository.updateUserRatingSummary(ratedUserId);
      print('[RatingService] ✅ User rating summary updated');

      return savedRating;
    } catch (e, stack) {
      print('[RatingService] ❌ Error in submitRating: $e');
      print(stack);
      throw Exception('Failed to submit rating: ${e.toString()}');
    }
  }

  /// Get all ratings received by a user
  Future<List<Rating>> getUserRatings(int userId) async {
    print('[RatingService] 📥 getUserRatings($userId)');
    try {
      return await _ratingRepository.findByRatedUserId(userId);
    } catch (e) {
      print('[RatingService] ❌ Error in getUserRatings: $e');
      throw Exception('Failed to get user ratings: ${e.toString()}');
    }
  }

  /// Get average rating
  Future<double?> getUserAverageRating(int userId) async {
    print('[RatingService] 📊 getUserAverageRating($userId)');
    try {
      return await _ratingRepository.getUserAverageRating(userId);
    } catch (e) {
      print('[RatingService] ❌ Error in getUserAverageRating: $e');
      throw Exception('Failed to get user average rating: ${e.toString()}');
    }
  }

  /// Get detailed stats
  Future<Map<String, dynamic>> getUserRatingStats(int userId) async {
    print('[RatingService] 📈 getUserRatingStats($userId)');
    try {
      return await _ratingRepository.getRatingStats(userId);
    } catch (e) {
      print('[RatingService] ❌ Error in getUserRatingStats: $e');
      throw Exception('Failed to get user rating statistics: ${e.toString()}');
    }
  }

  /// Has this user rated this session?
  Future<bool> hasUserRatedSession(int sessionId, int raterId) async {
    print('[RatingService] 🔍 hasUserRatedSession(session=$sessionId, rater=$raterId)');
    try {
      final session = await _sessionRepository.findById(sessionId);
      if (session == null) return false;

      final ratedUserId = session.requesterId == raterId
          ? session.helperId
          : session.requesterId;
      if (ratedUserId == null) return false;

      final ratings = await _ratingRepository.findBySessionId(sessionId);
      final alreadyRated = ratings.any((r) =>
      r.raterId == raterId && r.ratedId == ratedUserId);

      print('[RatingService] ✅ alreadyRated = $alreadyRated');
      return alreadyRated;
    } catch (e) {
      print('[RatingService] ❌ Error in hasUserRatedSession: $e');
      throw Exception('Failed to check if user rated session: ${e.toString()}');
    }
  }

  /// Ratings on a session
  Future<List<Rating>> getSessionRatings(int sessionId) async {
    print('[RatingService] 📥 getSessionRatings($sessionId)');
    try {
      return await _ratingRepository.findBySessionId(sessionId);
    } catch (e) {
      print('[RatingService] ❌ Error in getSessionRatings: $e');
      throw Exception('Failed to get session ratings: ${e.toString()}');
    }
  }
}
