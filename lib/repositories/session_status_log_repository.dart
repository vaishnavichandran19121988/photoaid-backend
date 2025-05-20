import 'package:backend/database/database.dart';
import 'package:backend/models/session.dart';
import 'package:backend/models/session_status_log.dart';
import 'package:postgres/postgres.dart' as pg;

class SessionStatusLogRepository {
  static final SessionStatusLogRepository _instance = SessionStatusLogRepository._internal();
  factory SessionStatusLogRepository() => _instance;
  SessionStatusLogRepository._internal();

  /// Log a new status change
  Future<void> logStatusChange({
    required int sessionId,
    required SessionStatus status,
    required int changedByUserId,
  }) async {
    try {
      await withDb((session) async {
        await session.execute(
          pg.Sql.named('''
            INSERT INTO session_status_logs (
              session_id, status, changed_by_user_id, changed_at
            ) VALUES (
              @sessionId, @status, @changedByUserId, @changedAt
            )
          '''),
          parameters: {
            'sessionId': sessionId,
            'status': status.name,
            'changedByUserId': changedByUserId,
            'changedAt': DateTime.now(),
          },
        );
        print('📝 Logged status change: session=$sessionId → $status by user=$changedByUserId');
      });
    } catch (e) {
      print('❌ Error logging session status change: $e');
    }
  }

  /// (Optional) Get all logs for a session
  Future<List<SessionStatusLog>> getLogsForSession(int sessionId) async {
    try {
      return await withDb((session) async {
        final result = await session.execute(
          pg.Sql.named('SELECT * FROM session_status_logs WHERE session_id = @sessionId ORDER BY changed_at ASC'),
          parameters: {'sessionId': sessionId},
        );
        return result.map((r) => SessionStatusLog.fromJson(r.toColumnMap())).toList();
      });
    } catch (e) {
      print('❌ Error fetching status logs for session $sessionId: $e');
      return [];
    }
  }
}
