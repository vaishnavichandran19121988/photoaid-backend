import 'package:backend/models/session.dart';
import 'package:backend/repositories/session_repository.dart';
import 'package:backend/repositories/session_status_log_repository.dart';
import 'package:backend/utils/jwt_utils.dart';
import 'package:backend/models/user.dart';
import 'package:backend/repositories/user_repository.dart';
import 'package:backend/services/fcm_service.dart';
/// Service class responsible for business logic of session operations
class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  final _sessionRepo = SessionRepository();
  final SessionStatusLogRepository _logRepo = SessionStatusLogRepository();
  final _userRepo = UserRepository();

  /// ✅ Extract userId from JWT token
  int? getUserIdFromToken(String? token) {
    if (token == null || token.isEmpty) return null;
    return JwtUtils.getUserIdFromToken(token);
  }
  Future<Session?> findById(int sessionId) async {
    try {
      return await SessionRepository().findById(sessionId);
    } catch (e) {
      print('❌ Error in SessionService.findById: $e');
      return null;
    }
  }


  Future<Map<String, dynamic>> createSession(Session session) async {
    try {
      print('[SessionService] ➕ createSession started');

      // ✅ 1. Only tourists can create sessions
      final user = await _userRepo.findById(session.requesterId);
      if (user == null || user.isAvailable) {
        print('[SessionService] ❌ Invalid requester: either null or not a tourist');
        return { 'success': false, 'message': 'Only tourists can create sessions' };
      }

      // ✅ 2. Tourist cannot have multiple active sessions
      final activeSessions = await _sessionRepo.findActiveSessionsForUser(session.requesterId);
      if (activeSessions.isNotEmpty) {
        print('[SessionService] ⛔ Tourist already has an active session');
        return { 'success': false, 'message': 'You already have an active session' };
      }

      // ✅ 3. Check if helper ID was provided
      if (session.helperId == null) {
        print('[SessionService] ❌ Missing helper_id in request');
        return {
          'success': false,
          'message': 'Missing helper_id. Frontend must select a helper.'
        };
      }

      // ✅ 4. Create session
      final newSession = await _sessionRepo.createSession(session);
      if (newSession == null) {
        print('[SessionService] ❌ Failed to create session in DB');
        return { 'success': false, 'message': 'Failed to create session' };
      }

      print('[SessionService] ✅ Session created in DB with ID: ${newSession.id}');

      // ✅ 5. Log creation
      await _logRepo.logStatusChange(
        sessionId: newSession.id!,
        status: newSession.status,
        changedByUserId: newSession.requesterId,
      );
      print('[SessionService] 📝 Logged status change to ${newSession.status}');

      // ✅ 6. Send notification to helper
      final helper = await _userRepo.getUserById(newSession.helperId!);
      if (helper != null && helper.fcmToken != null) {
        print('[SessionService] 🔔 Preparing to send FCM to helper ${helper.id}');
        print('[SessionService] 📬 Token: ${helper.fcmToken}');
        print('[SessionService] 📦 Payload: {type: session_request, session_id: ${newSession.id}}');

        await FcmService.sendPush(
          fcmToken: helper.fcmToken!,
          title: '📸 New Photo Session',
          body: '${user.fullName} is requesting your help nearby!',
          data: {
            'type': 'session_request',
            'session_id': newSession.id!.toString(),
            'requester_id': newSession.requesterId.toString()
          },
        );

        print('[SessionService] ✅ FCM push sent to helper');
      } else {
        print('[SessionService] ⚠️ No valid FCM token found for helper ${newSession.helperId}');
      }

      return {
        'success': true,
        'message': 'Session created',
        'session': newSession.toJson(),
      };

    } catch (e, stack) {
      print('[SessionService] ❌ Exception in createSession: $e');
      print(stack);
      return { 'success': false, 'message': e.toString() };
    }
  }


  Future<Map<String, dynamic>> acceptSession(int sessionId, int helperId) async {
    try {
      print('[SessionService] ✅ acceptSession started for session $sessionId');

      final user = await _userRepo.findById(helperId);
      print('[SessionService] 👤 Fetched helper: ${user?.id}, available: ${user?.isAvailable}');
      if (user == null) {
        return {'success': false, 'message': 'Helper not found'};
      }

      if (!user.isAvailable) {
        print('[SessionService] ❌ Helper not available');
        return {
          'success': false,
          'message': 'Only helpers can accept sessions (isAvailable = false)'
        };
      }

      final targetSession = await _sessionRepo.findById(sessionId);
      print('[SessionService] 📦 Fetched target session: ${targetSession?.id}');
      if (targetSession == null) {
        return {'success': false, 'message': 'Session not found'};
      }

      if (targetSession.helperId != helperId) {
        print('[SessionService] ❌ Session not assigned to this helper');
        return {'success': false, 'message': 'This session is not assigned to you'};
      }

      final activeSessions = await _sessionRepo.findActiveSessionsForHelper(helperId);
      print('[SessionService] 📋 Active sessions for helper $helperId: ${activeSessions.length}');
      for (final s in activeSessions) {
        print('🔁 Active session: ID=${s.id}, status=${s.status}');
      }

      final session = await _sessionRepo.acceptSession(sessionId, helperId);
      if (session == null) {
        print('[SessionService] ❌ Failed to accept session');
        return {'success': false, 'message': 'Session cannot be accepted'};
      }

      print('[SessionService] ✅ Session accepted: ${session.id}');

      await _userRepo.updateAvailability(userId: helperId, isAvailable: false);
      print('[SessionService] 🔧 Updated helper $helperId availability to false');

      await _logRepo.logStatusChange(
        sessionId: sessionId,
        status: SessionStatus.accepted,
        changedByUserId: helperId,
      );
      print('[SessionService] 📝 Logged status change for session $sessionId');

      // ✅ NEW: Reload session with full user objects
      final fullSession = await _sessionRepo.findByIdWithUsers(sessionId);
      print('[SessionService] 🔍 Loaded session navigationMode: ${session.navigationMode}');


      return {
        'success': true,
        'message': 'Session accepted',
        'session': fullSession?.toJson(), // 👈 this powers the LiveSessionScreen
      };

    } catch (e, stack) {
      print('[SessionService] ❗ Error in acceptSession: $e');
      print(stack);
      return {'success': false, 'message': 'Internal server error'};
    }
  }



  Future<Map<String, dynamic>> completeSession(int sessionId, int userId) async {
    print('[SessionService] 🎉 completeSession started for session $sessionId');

    try {
      // Load the session
      final targetSession = await _sessionRepo.findById(sessionId);
      print('[SessionService] 🔍 Loaded session: $targetSession');

      if (targetSession == null) {
        print('[SessionService] ❌ Session not found');
        return {'success': false, 'message': 'Session not found'};
      }

      // Check if already completed
      if (targetSession.status == 'completed') {
        print('[SessionService] ⚠️ Session already marked as completed');
        return {'success': false, 'message': 'Already completed'};
      }

      // ✅ Use updated logic that assumes 'accepted' is the active status
      final updatedSession = await _sessionRepo.completeSession(sessionId);
      if (updatedSession == null) {
        print('[SessionService] ❌ Failed to update session in DB');
        return {'success': false, 'message': 'DB update failed'};
      }
      print('[SessionService] ✅ Session marked as completed in DB');

      // Send notifications to users (if applicable)
      final helperId = targetSession.helperId ?? -1;
      final requesterId = targetSession.requesterId ?? -1;
      final helper = await _userRepo.findById(helperId);
      final tourist = await _userRepo.findById(requesterId);

      if (helper != null && helper.fcmToken != null) {
        await FcmService.sendPush(
          fcmToken: helper.fcmToken!,
          title: 'Session Completed ✅',
          body: 'Your session #$sessionId has been marked as completed.',
          data: {
            'type': 'session_update',
            'session_id': sessionId.toString(),
            'status': 'completed',
          },
        );
        print('[SessionService] 🔔 Notified helper');
      }


      if (tourist != null && tourist.fcmToken != null) {
        await FcmService.sendPush(
          fcmToken: tourist.fcmToken!,
          title: 'Session Completed ✅',
          body: 'Your session #$sessionId has been marked as completed.',
          data: {
            'type': 'session_update',
            'session_id': sessionId.toString(),
            'status': 'completed',
          },
        );
        print('[SessionService] 🔔 Notified tourist');
      }

      return {'success': true, 'session': updatedSession};
    } catch (e) {
      print('[SessionService] ❌ Error in completeSession: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }



  Future<Map<String, dynamic>> cancelSession(int sessionId, int userId) async {
    try {
      print('[SessionService] 🛑 cancelSession started for session $sessionId');

      final session = await _sessionRepo.cancelSession(sessionId);
      if (session == null) {
        return {'success': false, 'message': 'Session cannot be cancelled'};
      }

      await _logRepo.logStatusChange(
        sessionId: sessionId,
        status: SessionStatus.cancelled,
        changedByUserId: userId,
      );

      // ✅ Notify helper if available
      if (session.helperId != null) {
        final helper = await _userRepo.getUserById(session.helperId!);
        print('[SessionService] Helper FCM token: ${helper?.fcmToken}');
        if (helper?.fcmToken != null) {
          await FcmService.sendPush(
            fcmToken: helper!.fcmToken!,
            title: '🚫 Session Cancelled',
            body: 'Tourist cancelled the session.',
            data: {
              'type': 'session_update',
              'session_id': session.id.toString(),
              'status': 'cancelled',
            },
          );
        } else {
          print('[SessionService] ⚠️ No fcmToken found for helper ${session.helperId}');
        }
      } else {
        print('[SessionService] ⚠️ helperId is null in session ${session.id}');
      }

      return {
        'success': true,
        'message': 'Session cancelled',
        'session': session.toJson(),
      };

    } catch (e, stack) {
      print('[SessionService] ❌ Exception in cancelSession: $e');
      print(stack);
      return {'success': false, 'message': 'Error cancelling session: $e'};
    }
  }

  /// ✅ Get session by sessionId
  Future<Map<String, dynamic>> getSessionById(int sessionId) async {
    try {
      final session = await _sessionRepo.findById(sessionId);
      if (session == null) {
        return { 'success': false, 'message': 'Session not found' };
      }
      return {
        'success': true,
        'message': 'Session found',
        'session': session.toJson(),
      };
    } catch (e) {
      return { 'success': false, 'message': e.toString() };
    }
  }

  /// ✅ Get all sessions (tourist or helper)
  Future<Map<String, dynamic>> getSessionsByUserId(int userId) async {
    try {
      final sessions = await _sessionRepo.findByUserId(userId);
      return {
        'success': true,
        'message': 'Sessions found',
        'sessions': sessions.map((s) => s.toJson()).toList(),
      };
    } catch (e) {
      return { 'success': false, 'message': e.toString() };
    }
  }

  /// ✅ Get all sessions where user is helper
  Future<Map<String, dynamic>> getSessionsByHelperId(int helperId) async {
    try {
      final sessions = await _sessionRepo.findByHelperId(helperId);
      return {
        'success': true,
        'message': 'Sessions found',
        'sessions': sessions.map((s) => s.toJson()).toList(),
      };
    } catch (e) {
      return { 'success': false, 'message': e.toString() };
    }
  }

  /// ✅ Get all active sessions for user
  Future<Map<String, dynamic>> getActiveSessionsForUser(int userId) async {
    try {
      final sessions = await _sessionRepo.findIncomingRequestsForHelper(userId);
      return {
        'success': true,
        'message': 'Active sessions found',
        'sessions': sessions.map((s) => s.toJson()).toList(),
      };
    } catch (e) {
      return { 'success': false, 'message': e.toString() };
    }
  }

  /// ✅ Get all past sessions for user
  Future<Map<String, dynamic>> getPastSessionsForUser(int userId) async {
    try {
      final sessions = await _sessionRepo.findPastSessionsForUser(userId);
      return {
        'success': true,
        'message': 'Past sessions found',
        'sessions': sessions.map((s) => s.toJson()).toList(),
      };
    } catch (e) {
      return { 'success': false, 'message': e.toString() };
    }
  }

  Future<List<Session>> getActiveSessionsForTourist(int userId) async {
    final sessions = await _sessionRepo.findActiveSessionsForUser(userId);
    return sessions.where((s) => s.requesterId == userId).toList();
  }

  Future<List<Session>> getActiveSessionsForHelper(int userId) async {
    final sessions = await _sessionRepo.findActiveSessionsForUser(userId);
    return sessions.where((s) => s.helperId == userId).toList();
  }

  Future<List<Session>> getPastSessionsForTourist(int userId) async {
    final sessions = await _sessionRepo.findPastSessionsForUser(userId);
    return sessions.where((s) => s.requesterId == userId).toList();
  }

  Future<List<Session>> getPastSessionsForHelper(int userId) async {
    final sessions = await _sessionRepo.findPastSessionsForUser(userId);
    return sessions.where((s) => s.helperId == userId).toList();
  }
  Future<Session?> updateSession(Session updatedSession) async {
    try {
      final result = await _sessionRepo.updateSession(updatedSession);
      if (result == null) {
        print('[SessionService] ❌ Failed to update session in repository');
        return null;
      }
      print('[SessionService] ✅ Session updated successfully: ID=${result.id}');
      return result;
    } catch (e) {
      print('[SessionService] ❌ Error in updateSession: $e');
      return null;
    }
  }

  Future<Session?> findByIdWithUsers(int sessionId) async {
    print('[SessionService] 🔍 findByIdWithUsers called for sessionId=$sessionId');

    try {
      final session = await _sessionRepo.findByIdWithUsers(sessionId);

      if (session == null) {
        print('[SessionService] ❌ No session found with ID: $sessionId');
        return null;
      }

      print('[SessionService] ✅ Session found: ID=${session.id}, Status=${session.status}');
      print('[SessionService] 👤 Requester: ${session.requester?.username}, '
          'Helper: ${session.helper?.username}');
      print('[SessionService] 📍 Meeting Point: '
          'Lat=${session.locationLat}, Lng=${session.locationLng}');
      print('[SessionService] 🔍 Loaded session navigationMode: ${session.navigationMode}');



      return session;
    } catch (e, stack) {
      print('[SessionService] ❌ Error in findByIdWithUsers: $e');
      print(stack);
      return null;
    }
  }



}
