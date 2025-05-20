import '../models/chat_message.dart';
import '../models/user.dart';
import '../repositories/chat_repository.dart';
import '../repositories/session_repository.dart';
import '../repositories/user_repository.dart';
import '../models/session.dart';

/// Service for chat operations
class ChatService {
  final ChatRepository _chatRepository;
  final SessionRepository _sessionRepository;
  final UserRepository _userRepository;

  ChatService(
      this._chatRepository, this._sessionRepository, this._userRepository);

  /// Get a user by ID
  Future<User?> getUser(int userId) async {
    return await _userRepository.getUserById(userId);
  }

  /// Get all messages for a session
  Future<List<ChatMessage>> getSessionMessages(
      int sessionId, int userId) async {
    // Verify the user is a participant in this session
    final session = await _sessionRepository.findById(sessionId);

    if (session == null) {
      throw Exception('Session not found');
    }

    // Check if user is a participant (either requester or helper)
    if (session.requesterId != userId && session.helperId != userId) {
      throw Exception('User is not a participant in this session');
    }

    // Mark messages as read when fetched
    await _chatRepository.markMessagesAsRead(sessionId, userId);
    final messages = await _chatRepository.findBySessionId(sessionId);
    print('📤 getSessionMessages: Returning ${messages.length} messages');
    // Return messages
    return _chatRepository.findBySessionId(sessionId);
  }

  /// Send a message in a session
  Future<ChatMessage?> sendMessage(
      int sessionId,
      int senderId,
      int receiverId,
      String content,
      ) async {
    // ✅ 1. Verify session exists
    final session = await _sessionRepository.findById(sessionId);
    if (session == null) {
      print('❌ Session $sessionId not found');
      throw Exception('Session not found');
    }

    // ✅ 2. Validate sender is part of the session
    final isParticipant = senderId == session.requesterId || senderId == session.helperId;
    if (!isParticipant) {
      print('❌ sender_id=$senderId is not part of session ${session.id}');
      throw Exception('User is not a participant in this session');
    }

    // ✅ 3. Validate receiver is also part of the session
    final isReceiverValid = receiverId == session.requesterId || receiverId == session.helperId;
    if (!isReceiverValid) {
      print('❌ receiver_id=$receiverId is not part of session ${session.id}');
      throw Exception('Receiver is not a participant in this session');
    }

    // ✅ 4. Ensure session status is valid
    const invalidStatuses = {
      SessionStatus.pending,
      SessionStatus.cancelled,
      SessionStatus.completed,
      SessionStatus.expired,
    };
    if (invalidStatuses.contains(session.status)) {
      print('❌ Cannot send message — session status is ${session.status}');
      throw Exception('Cannot send messages in a ${session.status.name} session');
    }

    // ✅ 5. Save the message to the DB
    try {
      return await _chatRepository.saveMessage(
        sessionId,
        senderId,
        receiverId,
        content,
      );
    } catch (e) {
      print('❌ DB Error while saving message: $e');
      return null;
    }
  }

  /// Mark all messages in a session as read for a user
  Future<bool> markAsRead(int sessionId, int userId) async {
    // Verify the user is a participant in this session
    final session = await _sessionRepository.findById(sessionId);
    if (session == null) {
      throw Exception('Session not found');
    }

    // Check if user is a participant (either requester or helper)
    if (session.requesterId != userId && session.helperId != userId) {
      throw Exception('User is not a participant in this session');
    }

    // Mark messages as read
    return await _chatRepository.markMessagesAsRead(sessionId, userId);
  }

  /// Get unread message count for a user in a session
  Future<int> getUnreadCount(int sessionId, int userId) async {
    // Verify the user is a participant in this session
    final session = await _sessionRepository.findById(sessionId);
    if (session == null) {
      throw Exception('Session not found');
    }

    // Check if user is a participant (either requester or helper)
    if (session.requesterId != userId && session.helperId != userId) {
      throw Exception('User is not a participant in this session');
    }

    // Get unread count
    return await _chatRepository.getUnreadCountForUser(sessionId, userId);
  }

  /// Get total unread message count across all sessions for a user
  Future<int> getTotalUnreadCount(int userId) async {
    // Get active sessions for the user
    final sessions = await _sessionRepository.findActiveSessionsForUser(userId);

    // Track total unread count
    int totalUnread = 0;

    // Check each session for unread messages
    for (final session in sessions) {
      final unreadCount = await _chatRepository.getUnreadCountForUser(
        session.id!,
        userId,
      );
      totalUnread += unreadCount;
    }

    return totalUnread;
  }

  /// Get chat message statistics for a user
  Future<Map<String, dynamic>> getUserMessageStats(int userId) async {
    return await _chatRepository.getMessageStats(userId);
  }
}
