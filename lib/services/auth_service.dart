import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:backend/repositories/user_repository.dart';
import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:backend/database/database.dart';
import 'package:backend/models/user.dart';
import 'package:postgres/postgres.dart' as pg;


class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // ✅ REGISTER
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      print('[AuthService] 🔵 register() STARTED');
      print('[AuthService] Input → username=$username, email=$email');

      return await withDb((pg.Session session) async {
        print('[AuthService] 💡 Checking for existing user...');
        final existingUsers = await session.execute(
          pg.Sql.named(
              'SELECT id FROM users WHERE username = @username OR email = @email'),
          parameters: {
            'username': username,
            'email': email,
          },
        );

        print('[AuthService] 🔍 Found ${existingUsers.length} matching users');
        if (existingUsers.isNotEmpty) {
          print('[AuthService] ⚠️ User already exists');
          return {
            'success': false,
            'message': 'User with this username or email already exists',
          };
        }

        final salt = _generateSalt();
        final hashedPassword = _hashPassword(password, salt);

        print('[AuthService] 🧂 Salt: $salt');
        print('[AuthService] 🔐 Hashed Password: $hashedPassword');

        print('[AuthService] 📝 Inserting user into DB...');
        final result = await session.execute(
          pg.Sql.named('''
   INSERT INTO users (
  username, email, password_hash, salt, full_name,
  is_available, created_at, updated_at
) VALUES (
  @username, @email, @password_hash, @salt, @full_name,
  false, NOW(), NOW()
)
    RETURNING *
  '''),
          parameters: {
            'username': username,
            'email': email,
            'password_hash': hashedPassword,
            'salt': salt,
            'full_name': fullName ?? username,
          },
        );


        if (result.isEmpty) {
          print('[AuthService] ❌ Insert failed');
          return {
            'success': false,
            'message': 'Failed to create user',
          };
        }

        final user = User.fromDatabaseRow(result.first.toColumnMap());
        final token = _generateToken(user.id);
        print('[AuthService] ✅ User created with ID: ${user.id}');
        print('[AuthService] 🪪 JWT: $token');

        return {
          'success': true,
          'message': 'User registered successfully',
          'user': user.toJson(),
          'token': token,
        };
      });
    } catch (e, st) {
      print('[AuthService] ❌ Exception during register: $e');
      print(st);
      return {
        'success': false,
        'message': 'Registration failed: ${e.toString()}',
      };
    }
  }
  Future<Map<String, dynamic>> updateProfile({
    required int userId,
    String? fullName,
    String? email,
    String? bio,
    String? profileImageUrl,
  }) async {
    try {
      final success = await UserRepository().updateUserProfile(
        userId: userId,
        fullName: fullName,
        email: email,
        bio: bio,
        profileImageUrl: profileImageUrl,
      );

      if (!success) {
        return {
          'success': false,
          'message': 'Failed to update user profile',
        };
      }

      final updatedUser = await UserRepository().getUserById(userId);
      if (updatedUser == null) {
        return {
          'success': false,
          'message': 'User not found after update',
        };
      }

      return {
        'success': true,
        'message': 'Profile updated successfully',
        'user': updatedUser.toJson(),
      };
    } catch (e) {
      print('❌ Error in updateProfile: $e');
      return {
        'success': false,
        'message': 'Server error: ${e.toString()}',
      };
    }
  }


  // ✅ LOGIN
  Future<Map<String, dynamic>> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    try {
      print('[AuthService] 🔵 login() STARTED with $usernameOrEmail');

      return await withDb((pg.Session session) async {
        final result = await session.execute(
          pg.Sql.named('''
    SELECT * FROM users
    WHERE username = @username_or_email OR email = @username_or_email
  '''),
          parameters: {
            'username_or_email': usernameOrEmail,
          },
        );

        print('[AuthService] 🔍 Users found: ${result.length}');
        if (result.isEmpty) {
          return {
            'success': false,
            'message': 'User not found',
          };
        }

        final userData = result.first.toColumnMap();
        final storedHash = userData['password_hash'] as String;
        final salt = userData['salt'] as String;
        final inputHash = _hashPassword(password, salt);

        print('[AuthService] 🔐 Comparing hashes...');
        print('[AuthService] storedHash: $storedHash');
        print('[AuthService] inputHash:  $inputHash');

        if (inputHash != storedHash) {
          return {
            'success': false,
            'message': 'Invalid password',
          };
        }

        final user = User.fromDatabaseRow(userData);
        final token = _generateToken(user.id);
        print('[AuthService] ✅ Login success for user ID: ${user.id}');

        return {
          'success': true,
          'message': 'Login successful',
          'user': user.toJson(),
          'token': token,
        };
      });
    } catch (e) {
      print('[AuthService] ❌ Exception during login: $e');
      return {
        'success': false,
        'message': 'Login failed: ${e.toString()}',
      };
    }
  }

  // ✅ VERIFY
  Future<Map<String, dynamic>> verifyToken(String token) async {
    try {
      print('[AuthService] 🔐 Verifying JWT...');

      final jwt = JWT.verify(token, SecretKey(_getJwtSecret()));
      final userId = jwt.payload['userId'];
      print('[AuthService] 🧠 Payload userId: $userId');

      if (userId == null) {
        return {
          'success': false,
          'message': 'Invalid token payload',
        };
      }

      return await withDb((pg.Session session) async {
        final result = await session.execute(
          pg.Sql.named('SELECT * FROM users WHERE id = @id'),
          parameters: {'id': userId},
        );

        if (result.isEmpty) {
          return {
            'success': false,
            'message': 'User not found',
          };
        }

        final user = User.fromDatabaseRow(result.first.toColumnMap());
        print('[AuthService] ✅ Token verified for user ID: ${user.id}');

        return {
          'success': true,
          'message': 'Token verified',
          'user': user.toJson(),
        };
      });
    } catch (e) {
      print('[AuthService] ❌ Token verification failed: $e');
      return {
        'success': false,
        'message': 'Token verification failed: ${e.toString()}',
      };
    }
  }

  // --- Utilities ---
  String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Encode(saltBytes);
  }

  String _hashPassword(String password, String salt) {
    final codec = Utf8Codec();
    final key = codec.encode(password);
    final saltBytes = codec.encode(salt);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(saltBytes);
    return digest.toString();
  }

  String _generateToken(int userId) {
    final jwt = JWT({
      'userId': userId,
      'exp':
      DateTime.now().add(Duration(days: 30)).millisecondsSinceEpoch ~/ 1000,
    });

    return jwt.sign(SecretKey(_getJwtSecret()));
  }

  String _getJwtSecret() {
    return Platform.environment['JWT_SECRET'] ?? 'photoaid_default_secret_key';
  }

  Future<Map<String, dynamic>> toggleHelperStatus(
      int userId, bool isHelper) async {
    try {
      print('[AuthService] 🧠 Calling UserRepository.updateAvailability...');

      final success = await UserRepository().updateAvailability(
        userId: userId,
        isAvailable: isHelper,
      );

      if (!success) {
        return {
          'success': false,
          'message': 'Failed to update helper status',
        };
      }

      final user = await UserRepository().getUserById(userId);
      if (user == null) {
        return {
          'success': false,
          'message': 'User not found after updating status',
        };
      }

      return {
        'success': true,
        'message': 'Helper status updated',
        'user': user.toJson(),
      };
    } catch (e) {
      print('[AuthService] ❌ Error in toggleHelperStatus: $e');
      return {
        'success': false,
        'message': 'Error updating helper status: ${e.toString()}',
      };
    }
  }

  /*
 * Updates the user profile with optional fields.
 * Supports changes to full name, profile image, bio, and email.
 * Returns a success message and the updated user object if completed.
 */


  Future<Map<String, dynamic>> getUserProfile(int userId) async {
    try {
      final user = await UserRepository().getUserById(userId);
      if (user == null) {
        return {
          'success': false,
          'message': 'User not found',
        };
      }

      return {
        'success': true,
        'user': user.toJson(),
      };
    } catch (e) {
      print('❌ Error in getUserProfile: $e');
      return {
        'success': false,
        'message': 'Server error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> adminLogin({
  required String usernameOrEmail,
  required String password,
}) async {
  try {
    return await withDb((pg.Session session) async {
      final result = await session.execute(
        pg.Sql.named('''
          SELECT * FROM users
          WHERE username = @username_or_email OR email = @username_or_email
        '''),
        parameters: {
          'username_or_email': usernameOrEmail,
        },
      );

      if (result.isEmpty) {
        return {'success': false, 'message': 'User not found'};
      }

      final userData = result.first.toColumnMap();
      final storedHash = userData['password_hash'] as String;
      final salt = userData['salt'] as String;
      print('[AdminLogin] 🔐 Stored salt from DB: $salt');
      print('[AdminLogin] 🔐 Stored hash from DB: $storedHash');

      final inputHash = _hashAdminPassword(password, salt);

      print('[AdminLogin] 🔐 Input password: $password');
      print('[AdminLogin] 🔐 Calculated inputHash: $inputHash');


      if (inputHash != storedHash) {
        return {'success': false, 'message': 'Invalid password'};
      }

      final role = userData['role'] as String;
      if (role != 'admin') {
        return {'success': false, 'message': 'Only admin users allowed'};
      }

      final user = User.fromDatabaseRow(userData);
      final token = _generateToken(user.id);

      return {
        'success': true,
        'message': 'Admin login successful',
        'user': user.toJson(),
        'token': token,
      };
    });
  } catch (e) {
    print('[AdminLogin] Exception: $e');
    return {'success': false, 'message': 'Login failed: ${e.toString()}'};
  }
}


  String _hashAdminPassword(String password, String salt) {
  final key = utf8.encode(password);
  final saltBytes = base64Decode(salt);
  final hmac = Hmac(sha256, key);
  final digest = hmac.convert(saltBytes);
  return digest.toString();
}

}

