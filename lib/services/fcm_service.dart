import 'dart:convert';
import 'package:http/http.dart' as http;

class FcmService {
  static const String _cloudFunctionUrl =
      'https://us-central1-soft-development-assignment.cloudfunctions.net/sendSessionPush';

  static Future<void> sendPush({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_cloudFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': fcmToken,
          'title': title,
          'body': body,
          'data': data ?? {},
        }),
      );

      if (response.statusCode == 200) {
        print("📤 FCM push sent to $fcmToken");
      } else {
        print("❌ Push failed: ${response.body}");
      }
    } catch (e) {
      print("❌ Push error: $e");
    }
  }
}
