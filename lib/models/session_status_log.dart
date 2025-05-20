import 'package:backend/models/session.dart';

class SessionStatusLog {
  final int? id;
  final int sessionId;
  final SessionStatus status;
  final int changedByUserId;
  final DateTime changedAt;

  SessionStatusLog({
    this.id,
    required this.sessionId,
    required this.status,
    required this.changedByUserId,
    required this.changedAt,
  });

  factory SessionStatusLog.fromJson(Map<String, dynamic> json) {
    return SessionStatusLog(
      id: json['id'] as int?,
      sessionId: json['session_id'] as int,
      status: SessionStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String),
        orElse: () => SessionStatus.pending,
      ),
      changedByUserId: json['changed_by_user_id'] as int,
      changedAt: DateTime.parse(json['changed_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'status': status.name,
      'changed_by_user_id': changedByUserId,
      'changed_at': changedAt.toIso8601String(),
    };
  }
}
