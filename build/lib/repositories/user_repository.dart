import 'package:backend/database/database.dart';
import 'package:backend/models/user.dart';
import 'package:postgres/postgres.dart';

class UserRepository {
  static final UserRepository _instance = UserRepository._internal();
  factory UserRepository() => _instance;
  UserRepository._internal();

  Future<User?> getUserById(int id) async {
    try {
      return await withDb((session) async {
        final result = await session.execute(
          Sql.named('SELECT * FROM users WHERE id = @id'),
          parameters: {'id': id},
        );
        if (result.isEmpty) return null;
        return User.fromDatabaseRow(result.first.toColumnMap());
      });
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

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
          Sql.named('''
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
        if (result.isEmpty) return null;
        return User.fromDatabaseRow(result.first.toColumnMap());
      });
    } catch (e) {
      print('Error inserting user: $e');
      return null;
    }
  }

  Future<bool> updateUserProfile({
    required int userId,
    String? fullName,
    String? profileImageUrl,
    String? bio,
  }) async {
    try {
      return await withDb((session) async {
        final updateParts = <String>[];
        final values = <String, dynamic>{'id': userId};

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

        updateParts.add('updated_at = NOW()');

        final query = '''
          UPDATE users SET ${updateParts.join(', ')} WHERE id = @id RETURNING *
        ''';

        final result =
        await session.execute(Sql.named(query), parameters: values);
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
        print('🔁 Toggling user $userId to isAvailable=$isAvailable');
        final result = await session.execute(
          Sql.named('''
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
          Sql.named('''
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

      if (!result) {
        return {
          'success': false,
          'message': 'Location update failed',
        };
      }

      return {
        'success': true,
        'message': 'Location updated successfully',
      };
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
          Sql.named('''
            SELECT * FROM users
            WHERE email = @email OR username = @username
            LIMIT 1
          '''),
          parameters: {
            'email': email,
            'username': username,
          },
        );
        if (result.isEmpty) return null;
        return User.fromDatabaseRow(result.first.toColumnMap());
      });
    } catch (e) {
      print('Error checking existing user: $e');
      return null;
    }
  }

  Future<List<User>> findNearbyHelpers(
      double lat, double lng, double radiusKm) async {
    try {
      return await withDb((session) async {
        final result = await session.execute(
          Sql.named('''
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
                AND location_lat IS NOT NULL
                AND location_lng IS NOT NULL
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
        return result
            .map((row) => User.fromDatabaseRow(row.toColumnMap()))
            .toList();
      });
    } catch (e) {
      print('Error finding helpers: $e');
      return [];
    }
  }

  Future<List<User>> findNearbyTourists(
      double lat, double lng, double radiusKm) async {
    try {
      return await withDb((session) async {
        final result = await session.execute(
          Sql.named('''
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
                AND location_lat IS NOT NULL
                AND location_lng IS NOT NULL
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
        return result
            .map((row) => User.fromDatabaseRow(row.toColumnMap()))
            .toList();
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
          Sql.named('''
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
        return result
            .map((row) => User.fromDatabaseRow(row.toColumnMap()))
            .toList();
      });
    } catch (e) {
      print('Error finding nearby users: $e');
      return [];
    }
  }
}
