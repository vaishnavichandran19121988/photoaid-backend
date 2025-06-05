import 'package:backend/repositories/chat_repository.dart';

class AbuseService {
  final ChatRepository _chatRepository = ChatRepository();

  /// Creates a new abuse report by calling the repository layer.
  Future<int> createAbuseReport({
    required int reporterId,
    required int reportedUserId,
    required int sessionId,
    required String reason,
  }) async {
    print('🟠 [AbuseService] Creating abuse report...');
    print('   Reporter: $reporterId');
    print('   Reported User: $reportedUserId');
    print('   Session ID: $sessionId');
    print('   Reason: $reason');

    final insertedId = await _chatRepository.insertAbuseReport(
      reporterId: reporterId,
      reportedUserId: reportedUserId,
      sessionId: sessionId,
      reason: reason,
    );

    print('✅ [AbuseService] Inserted abuse report ID: $insertedId');
    return insertedId;
  }
}
