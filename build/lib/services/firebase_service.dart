import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Sends a push notification via Firebase Cloud Messaging (REST API)
Future<void> sendPushNotification({
  required String token,
  required String title,
  required String body,
  Map<String, dynamic>? data,
}) async {
  final serverKey = Platform.environment['FIREBASE_SERVER_KEY'];

  if (serverKey == null || serverKey.isEmpty) {
    print('FIREBASE_SERVER_KEY not set. Skipping push notification.');
    return;
  }

  final payload = {
    'to': token,
    'notification': {
      'title': title,
      'body': body,
    },
    'data': data ?? {},
  };

  try {
    final response = await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.authorizationHeader: 'key=$serverKey',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      print('✅ Push notification sent successfully');
    } else {
      print(
          '❌ Failed to send notification: ${response.statusCode} ${response.body}');
    }
  } catch (e) {
    print('🚨 Error sending notification: $e');
  }
}
