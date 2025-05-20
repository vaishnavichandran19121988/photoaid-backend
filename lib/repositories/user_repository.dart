import 'package:backend/database/database.dart';
import 'package:backend/models/user.dart';
import 'package:postgres/postgres.dart' as pg;

class UserRepository {
  static final UserRepository _instance = UserRepository._internal();
  factory UserRepository() => _instance;
  UserRepository._internal();

  Future<User?> getUserById(int id) async {
    try {
      return await withDb((session) async {
        final result = await session.execute(
          pg.Sql.named('SELECT * FROM users WHERE id = @id'),
          parameters: {'id': id},
        );
        return result.isEmpty ? null : User.fromDatabaseRow(result.first.toColumnMap());
      });
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  Future<User?> findById(int id) async => getUserById(id);

  Future<User?> insertUser({
    required String username,
    required String email,
    required String hashedPassword,
    required String salt,
    String? fullName,
  }) async {
    try {
      return await withDb((session) async {
        final result = await session.execute(
          pg.Sql.named('''
            INSERT INTO users (
              username, email, password_hash, salt, full_name,
              is_available, role, created_at, updated_at
            ) VALUES (
              @username, @email, @password, @salt, @full_name,
              false, 'user', NOW(), NOW()
            ) RETURNING *
          '''),
          parameters: {
            'username': username,
            'email': email,
            'password': hashedPassword,
            'salt': salt,
            'full_name': fullName,
          },
        );
        return result.isEmpty ? null : User.fromDatabaseRow(result.first.toColumnMap());
      });
    } catch (e) {
      print('Error inserting user: $e');
      return null;
    }
  }

  /*
 * Updates the user profile based on given input fields.
 * Only non-null values (fullName, profileImageUrl, bio) are updated.
 * Used for editing name, email, image URL, and bio after user uploads or modifies details.
 * Returns true if the update succeeds; false otherwise.
 */
  Future<bool> updateUserProfile({
    required int userId,
    String? fullName,
    String? profileImageUrl,
    String? bio,
    String? email, // ✅ New
  }) async {
    try {
      return await withDb((session) async {
        final updateParts = <String>[];                 // Holds dynamic SQL fields to update
        final values = <String, dynamic>{'id': userId}; // Query parameter values

        // ✅ Check if email is unique before updating
        if (email != null) {
          final existing = await session.execute(
            pg.Sql.named('SELECT id FROM users WHERE email = @email AND id != @id'),
            parameters: {'email': email, 'id': userId},
          );

          if (existing.isNotEmpty) {
            print('⚠️ Email already in use');
            return false;
          }

          updateParts.add('email = @email');
          values['email'] = email;
        }

        if (fullName != null) {
          updateParts.add('full_name = @full_name');
          values['full_name'] = fullName;
        }

        if (profileImageUrl != null) {
          updateParts.add('profile_image_url = @profile_image_url');
          values['profile_image_url'] = profileImageUrl;
        }

        if (bio != null) {
          updateParts.add('bio = @bio');
          values['bio'] = bio;
        }

        updateParts.add('updated_at = NOW()'); // Always update timestamp
        final query = '''
        UPDATE users SET ${updateParts.join(', ')} WHERE id = @id RETURNING *
      ''';

        final result = await session.execute(pg.Sql.named(query), parameters: values);
        return result.isNotEmpty;
      });
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }



  Future<bool> updateAvailability({
    required int userId,
    required bool isAvailable,
  }) async {
    try {
      return await withDb((session) async {
        final result = await session.execute(
          pg.Sql.named('''
            UPDATE users
            SET is_available = @is_available, updated_at = NOW()
            WHERE id = @id
            RETURNING *
          '''),
          parameters: {
            'id': userId,
            'is_available': isAvailable,
          },
        );
        return result.isNotEmpty;
      });
    } catch (e) {
      print('Error updating availability: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> updateUserLocation({
    required int userId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final result = await withDb((session) async {
        final updateResult = await session.execute(
          pg.Sql.named('''
            UPDATE users
            SET location_lat = @lat, location_lng = @lng, updated_at = NOW()
            WHERE id = @id
            RETURNING id
          '''),
          parameters: {
            'id': userId,
            'lat': latitude,
            'lng': longitude,
          },
        );
        return updateResult.isNotEmpty;
      });

      return result
          ? {'success': true, 'message': 'Location updated successfully'}
          : {'success': false, 'message': 'Location update failed'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Database error: $e',
      };
    }
  }

  Future<User?> findByEmailOrUsername(String email, String username) async {
    try {
      return await withDb((session) async {
        final result = await session.execute(
          pg.Sql.named('''
            SELECT * FROM users
            WHERE email = @email OR username = @username
            LIMIT 1
          '''),
          parameters: {
            'email': email,
            'username': username,
          },
        );
        return result.isEmpty ? null : User.fromDatabaseRow(result.first.toColumnMap());
      });
    } catch (e) {
      print('Error checking existing user: $e');
      return null;
    }
  }

  Future<List<User>> findNearbyHelpers(double lat, double lng, double radiusKm) async {
    try {
      return await withDb((session) async {
        final result = await session.execute(
          pg.Sql.named('''
          SELECT * FROM (
            SELECT *, (
              6371 * acos(
                cos(radians(@lat)) *
                cos(radians(location_lat)) *
                cos(radians(location_lng) - radians(@lng)) +
                sin(radians(@lat)) *
                sin(radians(location_lat))
              )
            ) AS distance
            FROM users
            WHERE is_available = true
              and fcm_token IS NOT NULL
              AND location_lat IS NOT NULL
              AND location_lng IS NOT NULL
                 AND NOT EXISTS (
                SELECT 1 FROM sessions s
                WHERE s.helper_id = users.id
                  AND s.status IN ('accepted', 'inProgress')
              )
          ) AS subquery
          WHERE distance <= @radius_km
          ORDER BY distance ASC
        '''),
          parameters: {
            'lat': lat,
            'lng': lng,
            'radius_km': radiusKm,
          },
        );
        return result.map((r) => User.fromDatabaseRow(r.toColumnMap())).toList();
      });
    } catch (e) {
      print('Error finding helpers: $e');
      return [];
    }
  }

  Future<void> clearFcmToken(int userId) async {
    try {
      await withDb((session) async {
        await session.execute(
          pg.Sql.named('''
          UPDATE users
          SET  location_lat = NULL,
              location_lng = NULL,
              fcm_token = NULL, updated_at = NOW()
          WHERE id = @userId
        '''),
          parameters: {'userId': userId},
        );
        print('🔄 Cleared FCM token for user $userId');
      });
    } catch (e) {
      print('❌ Error clearing FCM token: $e');
      rethrow;
    }
  }


  Future<List<User>> findNearbyTourists(double lat, double lng, double radiusKm) async {
    try {
      return await withDb((session) async {
        final result = await session.execute(
          pg.Sql.named('''
          SELECT * FROM (
            SELECT *, (
              6371 * acos(
                cos(radians(@lat)) *
                cos(radians(location_lat)) *
                cos(radians(location_lng) - radians(@lng)) +
                sin(radians(@lat)) *
                sin(radians(location_lat))
              )
            ) AS distance
            FROM users
            WHERE is_available = false
            and fcm_token IS NOT NULL
              AND location_lat IS NOT NULL
              AND location_lng IS NOT NULL
              AND role = 'user'
              AND NOT EXISTS (
                SELECT 1 FROM sessions s
                WHERE s.tourist_id = users.id
                  AND s.status IN ('accepted', 'inProgress')
              )
          ) AS subquery
          WHERE distance <= @radius_km
          ORDER BY distance ASC
        '''),
          parameters: {
            'lat': lat,
            'lng': lng,
            'radius_km': radiusKm,
          },
        );
        return result.map((r) => User.fromDatabaseRow(r.toColumnMap())).toList();
      });
    } catch (e) {
      print('Error finding tourists: $e');
      return [];
    }
  }

  Future<List<User>> findNearbyUsers({
    required double lat,
    required double lng,
    required double radiusKm,
    required bool isHelper,
  }) async {
    try {
      return await withDb((session) async {
        final result = await session.execute(
          pg.Sql.named('''
            SELECT * FROM (
              SELECT *, (
                6371 * acos(
                  cos(radians(@lat)) *
                  cos(radians(location_lat)) *
                  cos(radians(location_lng) - radians(@lng)) +
                  sin(radians(@lat)) *
                  sin(radians(location_lat))
                )
              ) AS distance
              FROM users
              WHERE is_available = true
                and fcm_token IS NOT NULL
                AND location_lat IS NOT NULL
                AND location_lng IS NOT NULL
                AND is_helper = @is_helper
            ) AS subquery
            WHERE distance <= @radius_km
            ORDER BY distance ASC
          '''),
          parameters: {
            'lat': lat,
            'lng': lng,
            'is_helper': isHelper,
            'radius_km': radiusKm,
          },
        );
        return result.map((r) => User.fromDatabaseRow(r.toColumnMap())).toList();
      });
    } catch (e) {
      print('Error finding nearby users: $e');
      return [];
    }
  }

  Future<void> updateFcmToken(int userId, String fcmToken) async {
    try {
      await withDb((session) async {
        await session.execute(
          pg.Sql.named('''
            UPDATE users
            SET fcm_token = @fcmToken, updated_at = NOW()
            WHERE id = @userId
          '''),
          parameters: {
            'fcmToken': fcmToken,
            'userId': userId,
          },
        );
        print('✅ Updated FCM token for user $userId');
      });
    } catch (e) {
      print('❌ Error updating FCM token: $e');
      rethrow;
    }
  }
}
