import 'package:backend/database/database.dart';
import 'package:backend/models/chat_message.dart';
import 'package:postgres/postgres.dart' as pg;

class ChatRepository {
  static final ChatRepository _instance = ChatRepository._internal();
  factory ChatRepository() => _instance;
  ChatRepository._internal();
  Future<ChatMessage> saveMessage(
      int sessionId,
      int senderId,
      int receiverId,
      String content,
      ) async {
    try {
      return await withDb((session) async {
        final result = await session.execute(
          pg.Sql.named('''
          INSERT INTO chat_messages (
            session_id, sender_id, receiver_id, content, sent_at, is_read
          ) VALUES (
            @sessionId, @senderId, @receiverId, @content, NOW(), FALSE
          ) RETURNING *;
        '''),
          parameters: {
            'sessionId': sessionId,
            'senderId': senderId,
            'receiverId': receiverId,
            'content': content,
          },
        );

        if (result.isEmpty) {
          throw Exception('❌ Failed to insert message — no rows returned');
        }

        return ChatMessage.fromJson(result.first.toColumnMap());
      });
    } catch (e) {
      print('❌ Error in saveMessage: $e');
      rethrow;
    }
  }



  Future<ChatMessage?> findById(int id) async {
    try {
      return await withDb((session) async {
        final results = await session.execute(
          pg.Sql.named('SELECT * FROM chat_messages WHERE id = @id'),
          parameters: {'id': id},
        );
        return results.isEmpty
            ? null
            : ChatMessage.fromJson(results.first.toColumnMap());
      });
    } catch (e) {
      print('Error finding chat message by ID: $e');
      return null;
    }
  }

  Future<ChatMessage?> insertMessage(ChatMessage message) async {
    try {
      return await withDb((session) async {
        final result = await session.execute(
          pg.Sql.named('''
            INSERT INTO chat_messages (
              session_id, sender_id, receiver_id, content, sent_at, is_read
            ) VALUES (
              @sessionId, @senderId, @receiverId, @content, @sentAt, @isRead
            ) RETURNING *
            '''),
          parameters: {
            'sessionId': message.sessionId,
            'senderId': message.senderId,
            'receiverId': message.receiverId,
            'content': message.content,
            'sentAt': message.sentAt,
            'isRead': message.isRead,
          },
        );

        return result.isEmpty
            ? null
            : ChatMessage.fromJson(result.first.toColumnMap());
      });
    } catch (e) {
      print('❌ Error inserting chat message: $e');
      return null;
    }
  }

  Future<List<ChatMessage>> findBySessionId(int sessionId) async {
    try {
      return await withDb((session) async {
        final results = await session.execute(
          pg.Sql.named(
              'SELECT * FROM chat_messages WHERE session_id = @sessionId ORDER BY sent_at ASC'),
          parameters: {'sessionId': sessionId},
        );
        print('🗂 DB fetched ${results.length} messages for session $sessionId');
        for (final row in results) {
          print('📦 Message row: ${row.toColumnMap()}');
        }

        return results
            .map((r) => ChatMessage.fromJson(r.toColumnMap()))
            .toList();
      });
    } catch (e) {
      print('Error finding chat messages by session ID: $e');
      return [];
    }
  }

  Future<int> getUnreadCountForUser(int sessionId, int userId) async {
    try {
      return await withDb((session) async {
        final results = await session.execute(
          pg.Sql.named('''
            SELECT COUNT(*) as unread_count 
            FROM chat_messages 
            WHERE session_id = @sessionId 
            AND receiver_id = @userId 
            AND is_read = FALSE
            '''),
          parameters: {
            'sessionId': sessionId,
            'userId': userId,
          },
        );

        if (results.isEmpty) return 0;
        final row = results.first.toColumnMap();
        return row['unread_count'] != null ? (row['unread_count'] as int) : 0;
      });
    } catch (e) {
      print('Error getting unread message count: $e');
      return 0;
    }
  }

  Future<ChatMessage?> createMessage(ChatMessage message) async {
    try {
      return await withDb((session) async {
        final now = DateTime.now();
        final results = await session.execute(
          pg.Sql.named('''
            INSERT INTO chat_messages (
              session_id, sender_id, receiver_id, content, sent_at, is_read
            ) VALUES (
              @sessionId, @senderId, @receiverId, @content, @sentAt, @isRead
            ) RETURNING *
            '''),
          parameters: {
            'sessionId': message.sessionId,
            'senderId': message.senderId,
            'receiverId': message.receiverId,
            'content': message.content,
            'sentAt': now,
            'isRead': message.isRead,
          },
        );

        return results.isEmpty
            ? null
            : ChatMessage.fromJson(results.first.toColumnMap());
      });
    } catch (e) {
      print('Error creating chat message: $e');
      return null;
    }
  }

  Future<bool> markMessagesAsRead(int sessionId, int userId) async {
    try {
      return await withDb((session) async {
        await session.execute(
          pg.Sql.named('''
            UPDATE chat_messages
            SET is_read = TRUE
            WHERE session_id = @sessionId
            AND receiver_id = @userId
            AND is_read = FALSE
            '''),
          parameters: {
            'sessionId': sessionId,
            'userId': userId,
          },
        );
        return true;
      });
    } catch (e) {
      print('Error marking messages as read: $e');
      return false;
    }
  }

  Future<bool> deleteSessionMessages(int sessionId) async {
    try {
      return await withDb((session) async {
        await session.execute(
          pg.Sql.named(
              'DELETE FROM chat_messages WHERE session_id = @sessionId'),
          parameters: {'sessionId': sessionId},
        );
        return true;
      });
    } catch (e) {
      print('Error deleting session messages: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getMessageStats(int userId) async {
    try {
      return await withDb((session) async {
        final results = await session.execute(
          pg.Sql.named('''
            SELECT 
              COUNT(*) FILTER (WHERE sender_id = @userId) as sent_count,
              COUNT(*) FILTER (WHERE receiver_id = @userId) as received_count,
              COUNT(*) as total_count
            FROM chat_messages
            WHERE session_id IN (
              SELECT id FROM sessions 
              WHERE tourist_id = @userId OR helper_id = @userId
            )
            '''),
          parameters: {
            'userId': userId,
          },
        );

        if (results.isEmpty) {
          return {
            'sent_count': 0,
            'received_count': 0,
            'total_count': 0,
          };
        }

        return results.first.toColumnMap();
      });
    } catch (e) {
      print('Error getting message statistics: $e');
      return {
        'sent_count': 0,
        'received_count': 0,
        'total_count': 0,
      };
    }
  }
  Future<int> insertAbuseReport({
    required int reporterId,
    required int reportedUserId,
    required int sessionId,
    required String reason,
  }) async {
    try {
      print('🟠 [ChatRepository] insertAbuseReport called...');
      print('   - reporterId: $reporterId');
      print('   - reportedUserId: $reportedUserId');
      print('   - sessionId: $sessionId');
      print('   - reason: $reason');

      return await withDb((session) async {
        print('🟠 [ChatRepository] Acquired DB session');

        final result = await session.execute(
          pg.Sql.named('''
            INSERT INTO abuse_reports (
              reporter_id, reported_user_id, session_id, reason, created_at
            ) VALUES (
              @reporterId, @reportedUserId, @sessionId, @reason, NOW()
            ) RETURNING id
          '''),
          parameters: {
            'reporterId': reporterId,
            'reportedUserId': reportedUserId,
            'sessionId': sessionId,
            'reason': reason,
          },
        );

        if (result.isEmpty) {
          print('❌ [ChatRepository] No rows returned after abuse report insert');
          throw Exception('Failed to insert abuse report');
        }

        final insertedId = result.first.toColumnMap()['id'] as int;
        print('✅ [ChatRepository] Abuse report inserted successfully with ID: $insertedId');
        return insertedId;
      });
    } catch (e, st) {
      print('❌ [ChatRepository] Error inserting abuse report: $e\n$st');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUnreviewedAbuseReports() async {
    final sql = '''
      SELECT id, reporter_id, reported_user_id, session_id, reason, created_at, reviewed
      FROM abuse_reports
      WHERE reviewed = FALSE
      ORDER BY created_at DESC
    ''';
    final result = await db.query(sql);
    return result;
  }

  /// Mark abuse report as reviewed
  Future<void> markReportAsReviewed(int reportId) async {
    final sql = '''
      UPDATE abuse_reports SET reviewed = TRUE WHERE id = @id
    ''';
    await db.execute(sql, substitutionValues: {
      'id': reportId,
    });
  }
}
