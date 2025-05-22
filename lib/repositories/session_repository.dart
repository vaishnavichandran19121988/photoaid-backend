import 'package:postgres/postgres.dart' as pg;
import 'dart:math';
import 'package:backend/database/database.dart';
import 'package:backend/models/session.dart';
import 'package:backend/services/fcm_service.dart';
import 'package:backend/repositories/user_repository.dart';
import 'Package:backend/models/user.dart';


class SessionRepository {
  static final SessionRepository _instance = SessionRepository._internal();
  factory SessionRepository() => _instance;
  SessionRepository._internal();

  Future<Session?> findById(int id) async {
    try {
      return await withDb((session) async {
        final results = await session.execute(
          pg.Sql.named('SELECT * FROM sessions WHERE id = @id'),
          parameters: {'id': id},
        );
        return results.isEmpty
            ? null
            : Session.fromJson(results.first.toColumnMap());
      });
    } catch (e) {
      print('❌ Error finding session by ID ($id): $e');
      return null;
    }
  }


  Future<List<Session>> findByUserId(int userId) async {
    try {
      return await withDb((session) async {
        final results = await session.execute(
          pg.Sql.named('''
          SELECT * FROM sessions 
          WHERE tourist_id = @userId OR helper_id = @userId
        '''),
          parameters: {'userId': userId},
        );
        return results.map((r) => Session.fromJson(r.toColumnMap())).toList();
      });
    } catch (e) {
      print('❌ Error finding sessions by user ID ($userId): $e');
      return [];
    }
  }


  Future<List<Session>> findByHelperId(int helperId) async {
    try {
      return await withDb((session) async {
        final results = await session.execute(
          pg.Sql.named('SELECT * FROM sessions WHERE helper_id = @helperId'),
          parameters: {'helperId': helperId},
        );
        return results.map((r) => Session.fromJson(r.toColumnMap())).toList();
      });
    } catch (e) {
      print('❌ Error finding sessions by helper ID ($helperId): $e');
      return [];
    }
  }




  Future<Session?> createSession(Session s) async {
    try {
      return await withDb((session) async {
        print('📥 Creating session with values:');
        print('Tourist ID: ${s.requesterId}');
        print('Helper ID: ${s.helperId}');
        print('Lat/Lng: ${s.locationLat}, ${s.locationLng}');
        print('Status: ${s.status}');
        print('Description: ${s.description}');

        final now = DateTime.now();
        final status = s.status.toString().split('.').last;
        final result = await session.execute(
          pg.Sql.named('''
          INSERT INTO sessions (
            tourist_id, helper_id, status, meeting_point_lat, meeting_point_lng, 
            description, created_at, updated_at,navigation_mode
          ) VALUES (
            @touristId, @helperId, @status, @lat, @lng, 
            @description, @createdAt, @updatedAt,@navigation_mode
          ) RETURNING *
          '''),
          parameters: {
            'touristId': s.requesterId,
            'helperId': s.helperId,
            'status': status,
            'lat': s.locationLat,
            'lng': s.locationLng,
            'description': s.description,
            'createdAt': now,
            'updatedAt': now,
            'navigation_mode': s.navigationMode,

          },
        );
        return result.isEmpty
            ? null
            : Session.fromJson(result.first.toColumnMap());
      });
    } catch (e) {
      print('sql Error creating session: $e');
      return null;
    }
  }

  Future<Session?> updateSession(Session s) async {
    try {
      return await withDb((session) async {
        final now = DateTime.now();
        final result = await session.execute(
          pg.Sql.named('''
          UPDATE sessions SET
            tourist_id = @touristId,
            helper_id = @helperId,
            status = @status,
            meeting_point_lat = @lat,
            meeting_point_lng = @lng,
            description = @description,
            updated_at = @updatedAt,
            completed_at = @completedAt,
            navigation_mode = @navigation_mode
          WHERE id = @id
          RETURNING *
        '''),
          parameters: {
            'id': s.id,
            'touristId': s.requesterId,
            'helperId': s.helperId,
            'status': s.status.name,
            'lat': s.locationLat,
            'lng': s.locationLng,
            'description': s.description,
            'updatedAt': now,
            'completedAt': s.completedAt,
            'navigation_mode': s.navigationMode
          },
        );

        if (result.isEmpty) {
          print('❌ No session updated for ID: ${s.id}');
          return null;
        }

        final updatedRow = result.first.toColumnMap();
        print('[SessionService] Updated session ID=${s.id} with navigation_mode=${updatedRow['navigation_mode']}');

        return Session.fromJson(updatedRow);
      });
    } catch (e) {
      print('❌ Error updating session: $e');
      return null;
    }
  }




  Future<Session?> rejectSession(int sessionId, int helperId) async {
    try {
      return await withDb((session) async {
        final now = DateTime.now();
        final result = await session.execute(
          pg.Sql.named('''
          UPDATE sessions
          SET status = @status,
              updated_at = @updatedAt,
              completed_at = @completedAt
          WHERE id = @sessionId 
            AND helper_id = @helperId 
            AND status = @pendingStatus
          RETURNING *
        '''),
          parameters: {
            'sessionId': sessionId,
            'helperId': helperId,
            'status': SessionStatus.cancelled.name,
            'pendingStatus': SessionStatus.pending.name,
            'updatedAt': now,
            'completedAt': now,   // ✅ Mark as ended
          },
        );
        return result.isEmpty ? null : Session.fromJson(result.first.toColumnMap());
      });
    } catch (e) {
      print('❌ Error rejecting session: $e');
      return null;
    }
  }

  Future<Session?> acceptSession(int sessionId, int helperId) async {
    try {
      print('🔧 Attempting to accept sessionId=$sessionId by helperId=$helperId');

      return await withDb((session) async {
        final result = await session.execute(
          pg.Sql.named('''
          UPDATE sessions
          SET helper_id = @helperId, 
              status = @status, 
              updated_at = @updatedAt
          WHERE id = @sessionId 
            AND status = @pendingStatus
            
          RETURNING *
        '''),
          parameters: {
            'sessionId': sessionId,
            'helperId': helperId,
            'status': SessionStatus.accepted.name,
            'pendingStatus': SessionStatus.pending.name,
            'updatedAt': DateTime.now(),
          },
        );

        if (result.isEmpty) {
          print('❌ Accept failed: Session was not pending or already has helper.');
          return null;
        }

        print('✅ Session accepted and updated: ${result.first.toColumnMap()}');
        return Session.fromJson(result.first.toColumnMap());
      });
    } catch (e) {
      print('❌ Exception in acceptSession: $e');
      return null;
    }
  }

  Future<Session?> completeSession(int sessionId) async {
    try {
      return await withDb((session) async {
        final now = DateTime.now();
        final result = await session.execute(
          pg.Sql.named('''
          UPDATE sessions
          SET status = @status, completed_at = @completedAt, updated_at = @updatedAt
          WHERE id = @sessionId AND status =  @acceptedStatus
          RETURNING *
        '''),
          parameters: {
            'sessionId': sessionId,
            'status': SessionStatus.completed.name,
            'acceptedStatus': SessionStatus.accepted.name,
            'completedAt': now,
            'updatedAt': now,
          },
        );
        return result.isEmpty ? null : Session.fromJson(result.first.toColumnMap());
      });
    } catch (e) {
      print('❌ Error completing session: $e');
      return null;
    }
  }

  Future<Session?> cancelSession(int sessionId) async {
    try {
      return await withDb((session) async {
        final now = DateTime.now();
        final result = await session.execute(
          pg.Sql.named('''
          UPDATE sessions
          SET status = @status,
              updated_at = @updatedAt,
              completed_at = @completedAt
          WHERE id = @sessionId
            AND status IN (@pending, @accepted)
          RETURNING *
        '''),
          parameters: {
            'sessionId': sessionId,
            'status': SessionStatus.cancelled.name,
            'pending': SessionStatus.pending.name,
            'accepted': SessionStatus.accepted.name,
            'updatedAt': now,
            'completedAt': now,   // ✅ Mark as ended
          },
        );
        return result.isEmpty ? null : Session.fromJson(result.first.toColumnMap());
      });
    } catch (e) {
      print('❌ Error cancelling session: $e');
      return null;
    }
  }


  Future<int> expireOldPendingSessions() async {
    try {
      return await withDb((session) async {
        // 1. Fetch and expire sessions that are old
        final result = await session.execute(
          pg.Sql.named('''
          UPDATE sessions
          SET status = @status, updated_at = NOW()
          WHERE status = @pendingStatus 
            AND created_at <= NOW() - INTERVAL '120 seconds'
          RETURNING id, tourist_id
        '''), // 👈 We return id and user
          parameters: {
            'status': SessionStatus.expired.name,
            'pendingStatus': SessionStatus.pending.name,
          },
        );

        if (result.isEmpty) {
          print('🟡 No sessions to expire.');
          return 0;
        }

        // 2. Notify each tourist about the expiry
        for (final row in result) {
          final rowMap = row.toColumnMap();
          final userId = rowMap['tourist_id'] as int;

          final user = await UserRepository().getUserById(userId);
          final token = user?.fcmToken;

          if (token != null && token.isNotEmpty) {
            await FcmService.sendPush(
              fcmToken: token,
              title: "⏰ Session Expired",
              body: "No helper accepted your session request in time.",
              data: {
                'type': 'session_expired',
                'sessionId': rowMap['id'].toString(),
              },
            );
          } else {
            print('⚠️ No FCM token for user $userId');
          }
        }

        print('✅ Expired ${result.length} sessions and notified users');
        return result.length;
      });
    } catch (e) {
      print('❌ Error expiring old sessions: $e');
      return 0;
    }
  }




  Future<List<Session>> findIncomingRequestsForHelper(int helperId) async {
    try {
      return await withDb((session) async {
        final result = await session.execute(
          pg.Sql.named('''
          SELECT * FROM sessions 
          WHERE helper_id = @helperId AND status = 'pending'
        '''),
          parameters: {'helperId': helperId},
        );
        return result.map((r) => Session.fromJson(r.toColumnMap())).toList();
      });
    } catch (e) {
      print('Error fetching incoming requests: $e');
      return [];
    }
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);


  Future<List<Session>> findPastSessionsForUser(int userId) async {
    try {
      final pastStatuses = [
        SessionStatus.completed.name,
        SessionStatus.cancelled.name,
        SessionStatus.expired.name,
      ];

      return await withDb((session) async {
        final results = await session.execute(
          pg.Sql.named('''
          SELECT * FROM sessions 
          WHERE (tourist_id = @userId OR helper_id = @userId)
          AND status = ANY(@statuses)
          ORDER BY updated_at DESC
        '''),
          parameters: {
            'userId': userId,
            'statuses': pastStatuses,
          },
        );

        return results.map((r) => Session.fromJson(r.toColumnMap())).toList();
      });
    } catch (e) {
      print('❌ Error finding past sessions for user ($userId): $e');
      return [];
    }
  }


  Future<Session?> findByIdWithUsers(int sessionId) async {
    try {
      return await withDb((dbSession) async {
        final results = await dbSession.execute(
          pg.Sql.named('''
        SELECT s.*, 
       h.id as h_id, h.username as h_username, h.full_name as h_full_name, h.profile_image_url as h_profile_image_url,
       h.location_lat as h_lat, h.location_lng as h_lng,  -- ✅ Add this
       r.id as r_id, r.username as r_username, r.full_name as r_full_name, r.profile_image_url as r_profile_image_url,
       r.location_lat as r_lat, r.location_lng as r_lng   -- ✅ Add this

        FROM sessions s
        LEFT JOIN users h ON s.helper_id = h.id
        LEFT JOIN users r ON s.tourist_id = r.id
        WHERE s.id = @sessionId
        '''),
          parameters: {'sessionId': sessionId},
        );

        if (results.isEmpty) return null;

        final row = results.first.toColumnMap();
        final sessionModel = Session.fromJson(row);

        // Attach helper
        if (row['h_id'] != null) {
          sessionModel.helper = User(
            id: row['h_id'],
            username: row['h_username'],
            fullName: row['h_full_name'],
            profileImageUrl: row['h_profile_image_url'],
            locationLat: (row['h_lat'] as num?)?.toDouble(),     // ✅ New
            locationLng: (row['h_lng'] as num?)?.toDouble(),
            email: '',
            role: '',
            isAvailable: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }

        // Attach requester
        if (row['r_id'] != null) {
          sessionModel.requester = User(
            id: row['r_id'],
            username: row['r_username'],
            fullName: row['r_full_name'],
            profileImageUrl: row['r_profile_image_url'],
            locationLat: (row['r_lat'] as num?)?.toDouble(),     // ✅ New
            locationLng: (row['r_lng'] as num?)?.toDouble(),
            email: '',
            role: '',
            isAvailable: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }

        return sessionModel;
      });
    } catch (e, stack) {
      print('❌ Error in findByIdWithUsers: $e');
      print(stack);
      return null;
    }
  }

  Future<List<Session>> findActiveSessionsForUser(int userId) async {
    try {
      final activeStatuses = [
        SessionStatus.pending.name,
        SessionStatus.accepted.name,
      ];

      return await withDb((session) async {
        final results = await session.execute(
          pg.Sql.named('''
          SELECT * FROM sessions 
          WHERE (tourist_id = @userId OR helper_id = @userId)
          AND status = ANY(@statuses)
        '''),
          parameters: {
            'userId': userId,
            'statuses': activeStatuses,
          },
        );

        return results.map((r) => Session.fromJson(r.toColumnMap())).toList();
      });
    } catch (e) {
      print('❌ Error finding active sessions for user ($userId): $e');
      return [];
    }
  }

  Future<List<Session>> findActiveSessionsForHelper(int helperId) async {
    try {
      final activeStatuses = [
        SessionStatus.pending.name,
        SessionStatus.accepted.name,
      ];

      return await withDb((session) async {
        final results = await session.execute(
          pg.Sql.named('''
          SELECT * FROM sessions 
          WHERE helper_id = @helperId
          AND status = ANY(@statuses)
        '''),
          parameters: {
            'helperId': helperId,
            'statuses': activeStatuses,
          },
        );

        return results.map((r) => Session.fromJson(r.toColumnMap())).toList();
      });
    } catch (e) {
      print('❌ Error finding active sessions for helper ($helperId): $e');
      return [];
    }
  }


}
