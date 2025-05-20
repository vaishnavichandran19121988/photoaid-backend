/// Model representing a chat message in a session
class ChatMessage {
  /// Unique identifier for the message
  final int? id;
  
  /// ID of the session this message belongs to
  final int sessionId;
  
  /// ID of the user who sent the message
  final int senderId;
  
  /// The message content
  final String content;
  
  /// When the message was sent
  final DateTime? sentAt;
  
  /// Whether the message has been read by the recipient
  final bool isRead;

  final int receiverId; 
  /// Constructor
 ChatMessage({
  this.id,
  required this.sessionId,
  required this.senderId,
  required this.receiverId, // NEW
  required this.content,
  this.sentAt,
  this.isRead = false,
});
  /// Create a copy of this ChatMessage with the given fields replaced with new values
  ChatMessage copyWith({
    int? id,
    int? sessionId,
    int? senderId,
    int? receiverId,
    String? content,
    DateTime? sentAt,
    bool? isRead,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
    );
  }
  
  /// Convert ChatMessage to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'sender_id': senderId,
      'receiver_id': receiverId, 
      'content': content,
      'sent_at': sentAt?.toIso8601String(),
      'is_read': isRead,
    };
  }
  
  /// Create ChatMessage from JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Handle DateTime conversion
    DateTime? parseSentAt(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          print('Error parsing DateTime: $e, value: $value');
          return null;
        }
      }
      return null;
    }
    
    return ChatMessage(
      id: json['id'] as int?,
      sessionId: json['session_id'] as int,
      senderId: json['sender_id'] as int,
      receiverId: json['receiver_id'] as int,
      content: json['content'] as String,
      sentAt: parseSentAt(json['sent_at']),
      isRead: json['is_read'] as bool? ?? false,
    );
  }
}