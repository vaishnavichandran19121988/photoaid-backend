import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final accessToken = await File('secrets/fcm_token.txt').readAsString();
  final project = jsonDecode(await File('secrets/service_account.json').readAsString());

  final fcmToken = 'dWOFa019SKS5nbxHPWYZBY:APA91bHQP-bZOIBNpMSjO6Y8GtzHGPPKsqR7PWXWzD7JYTuRHIgGh1AQ4XvVnKS_iL__AO0tGmBkSg_pqOqiMW9r8-KFpTNECpkG3pqjslA9UPIiyfXztjQ';
  ; // 🔁 Replace this

  final message = {
    "message": {
      "token": fcmToken,
      "notification": {
        "title": "PhotoAid Test 🔔",
        "body": "This is a push from Dart backend!",
      }
    }
  };

  final response = await http.post(
    Uri.parse('https://fcm.googleapis.com/v1/projects/${project["project_id"]}/messages:send'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${accessToken.trim()}',
    },
    body: jsonEncode(message),
  );

  print('Status: ${response.statusCode}');
  print(response.body);
}
