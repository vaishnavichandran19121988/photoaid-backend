import 'package:backend/repositories/user_repository.dart';
import 'package:backend/repositories/session_repository.dart';
import 'package:backend/repositories/rating_repository.dart';
import 'package:backend/models/user.dart';

class AdminService {
  final _userRepo = UserRepository();
  final _sessionRepo = SessionRepository();
  final _ratingRepo = RatingRepository();

  // ✅ Get dashboard summary counts
  Future<Map<String, int>> getSummary() async {
    print('[AdminService] 🔍 [SUMMARY] Pulling total counts...');
    final totalUsers = await _userRepo.countUsers();
    final totalSessions = await _sessionRepo.countSessions();
    final totalRatings = await _ratingRepo.countRatings();

    print('[AdminService] ✅ [SUMMARY RESULT] Users=$totalUsers, Sessions=$totalSessions, Ratings=$totalRatings');

    return {
      'total_users': totalUsers,
      'total_sessions': totalSessions,
      'total_ratings': totalRatings,
    };
  }

  // ✅ Get recent users list
  Future<List<User>> getRecentUsers(int limit) async {
    print('[AdminService] 🔍 [RECENT USERS] Requested limit=$limit');
    final users = await _userRepo.getRecentUsers(limit);
    print('[AdminService] ✅ [RECENT USERS RESULT] Found ${users.length} users');
    for (final user in users) {
      print('   - User ID=${user.id}, Username=${user.username}, Email=${user.email}');
    }
    return users;
  }

  // ✅ Delete user
  Future<bool> deleteUser(int userId) async {
    print('[AdminService] 🗑 [DELETE] Requested delete for User ID=$userId');
    final success = await _userRepo.deleteUser(userId);
    print(success ? '[AdminService] ✅ [DELETE RESULT] User deleted successfully' : '[AdminService] ❌ [DELETE RESULT] Failed to delete user');
    return success;
  }

  // ✅ Update user details (admin override)
  Future<bool> updateUserDetails({
    required int userId,
    String? fullName,
    String? email,
    String? bio,
  }) async {
    print('[AdminService] ✏ [UPDATE] Incoming data for User ID=$userId:');
    print('   FullName=$fullName, Email=$email, Bio=$bio');

    final success = await _userRepo.updateUserByAdmin(
      userId: userId,
      fullName: fullName,
      email: email,
      bio: bio,
    );

    print(success ? '[AdminService] ✅ [UPDATE RESULT] User updated successfully' : '[AdminService] ❌ [UPDATE RESULT] Failed to update user');
    return success;
  }
}
