import 'package:backend/database/database.dart';
import 'package:backend/models/chat_message.dart';
import 'package:postgres/postgres.dart' as pg;

class ChatRepository {
  static final ChatRepository _instance = ChatRepository._internal();
  factory ChatRepository() => _instance;
  ChatRepository._internal();

  Future<ChatMessage?> findById(int id) async {
    try {
      return await withDb((pg.Session session) async {
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
      return await withDb((pg.Session session) async {
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
        return result.isEmpty ? null : ChatMessage.fromJson(result.first.toColumnMap());
      });
    } catch (e) {
      print('❌ Error inserting chat message: $e');
      return null;
    }
  }

  Future<List<ChatMessage>> findBySessionId(int sessionId) async {
    try {
      return await withDb((pg.Session session) async {
        final results = await session.execute(
          pg.Sql.named('''
            SELECT * FROM chat_messages 
            WHERE session_id = @sessionId 
            ORDER BY sent_at ASC
          '''),
          parameters: {'sessionId': sessionId},
        );
        return results.map((r) => ChatMessage.fromJson(r.toColumnMap())).toList();
      });
    } catch (e) {
      print('Error finding chat messages by session ID: $e');
      return [];
    }
  }

  Future<int> getUnreadCountForUser(int sessionId, int userId) async {
    try {
      return await withDb((pg.Session session) async {
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
        return row['unread_count'] ?? 0;
      });
    } catch (e) {
      print('Error getting unread message count: $e');
      return 0;
    }
  }

  Future<ChatMessage?> createMessage(ChatMessage message) async {
    try {
      return await withDb((pg.Session session) async {
        final now = DateTime.now();
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
            'sentAt': now,
            'isRead': message.isRead,
          },
        );

        return result.isEmpty ? null : ChatMessage.fromJson(result.first.toColumnMap());
      });
    } catch (e) {
      print('Error creating chat message: $e');
      return null;
    }
  }

  Future<bool> markMessagesAsRead(int sessionId, int userId) async {
    try {
      return await withDb((pg.Session session) async {
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
      return await withDb((pg.Session session) async {
        await session.execute(
          pg.Sql.named('DELETE FROM chat_messages WHERE session_id = @sessionId'),
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
      return await withDb((pg.Session session) async {
        final results = await session.execute(
          pg.Sql.named('''
            SELECT 
              COUNT(*) FILTER (WHERE sender_id = @userId) AS sent_count,
              COUNT(*) FILTER (WHERE receiver_id = @userId) AS received_count,
              COUNT(*) AS total_count
            FROM chat_messages
            WHERE session_id IN (
              SELECT id FROM sessions 
              WHERE tourist_id = @userId OR helper_id = @userId
            )
          '''),
          parameters: {'userId': userId},
        );

        return results.isEmpty
            ? {'sent_count': 0, 'received_count': 0, 'total_count': 0}
            : results.first.toColumnMap();
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
}
