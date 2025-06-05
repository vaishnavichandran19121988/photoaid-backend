import 'package:backend/repositories/user_repository.dart';
import 'package:backend/repositories/session_repository.dart';
import 'package:backend/repositories/rating_repository.dart';
import 'package:backend/models/user.dart';
import 'package:backend/database/database.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:backend/utils/password_utils.dart';



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

Future<bool> deleteUser(int userId) async {
  print('[AdminService] 🗑 [DELETE] Requested delete for User ID=$userId');
  try {
    return await withDb((session) async {
      await session.execute('BEGIN');  // Transaction start

      // 1️⃣ Delete dependent ratings first (because they reference sessions)
      await session.execute(
        pg.Sql.named('DELETE FROM ratings WHERE rater_id = @id OR rated_id = @id OR session_id IN (SELECT id FROM sessions WHERE tourist_id = @id OR helper_id = @id)'),
        parameters: {'id': userId},
      );

      // 2️⃣ Delete dependent sessions
      await session.execute(
        pg.Sql.named('DELETE FROM sessions WHERE tourist_id = @id OR helper_id = @id'),
        parameters: {'id': userId},
      );

      // 3️⃣ Delete dependent chat messages
      await session.execute(
        pg.Sql.named('DELETE FROM chat_messages WHERE sender_id = @id OR receiver_id = @id'),
        parameters: {'id': userId},
      );

      // 4️⃣ Finally delete user
      final result = await session.execute(
        pg.Sql.named('DELETE FROM users WHERE id = @id'),
        parameters: {'id': userId},
      );

      await session.execute('COMMIT');
      final affectedRows = result.affectedRows ?? 0;
      print('[AdminService] ✅ User deleted successfully');
      return affectedRows > 0;
    });
  } catch (e) {
    print('[AdminService] ❌ Delete failed: $e');
    return false;
  }
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

  Future<int> countRatings() async {
  try {
    return await withDb((session) async {
      final result = await session.execute('SELECT COUNT(*) AS count FROM ratings');
      final row = result.first.toColumnMap();
      return row['count'] as int;
    });
  } catch (e) {
    print('Error counting ratings: $e');
    return 0;
  }
}
// ✅ New: Register Admin User
Future<Map<String, dynamic>> registerAdmin({
  required String username,
  required String email,
  required String password,
  String? fullName,
}) async {
  try {
    // Business rule: only allow email ending with photoaid.com
    if (!email.endsWith('@photoaid.com')) {
      return {
        'success': false,
        'message': 'Only emails ending with @photoaid.com allowed for admin registration',
      };
    }

    // Check if already exists
    final existing = await _userRepo.findByEmailOrUsername(email, username);
    if (existing != null) {
      return {
        'success': false,
        'message': 'Username or email already exists',
      };
    }

    // Use centralized utils now
    final salt = PasswordUtils.generateSalt();
    final hashedPassword = PasswordUtils.hashPassword(password, salt);

    // Insert admin using repository layer
    final newAdmin = await _userRepo.insertAdmin(
      username: username,
      email: email,
      hashedPassword: hashedPassword,
      salt: salt,
      fullName: fullName ?? username,
    );

    if (newAdmin == null) {
      return {
        'success': false,
        'message': 'Failed to create admin user',
      };
    }

    return {
      'success': true,
      'user': newAdmin.toJson(),
    };
  } catch (e) {
    print('[AdminService] ❌ Error in registerAdmin: $e');
    return {
      'success': false,
      'message': 'Server error: ${e.toString()}',
    };
  }
}

}
