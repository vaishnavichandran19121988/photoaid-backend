// backend/lib/firebase_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class FirebaseService {
  final _scopedTokenCache = <String, String>{};

  Future<String> _getAccessToken() async {
    if (_scopedTokenCache.containsKey('access_token')) {
      return _scopedTokenCache['access_token']!;
    }

    final jsonKey = jsonDecode(
      await File('secrets/service_account.json').readAsString(),
    );

    final header = {
      'alg': 'RS256',
      'typ': 'JWT',
    };

    final now = DateTime.now().toUtc();
    final payload = {
      'iss': jsonKey['client_email'],
      'scope': 'https://www.googleapis.com/auth/firebase.messaging',
      'aud': 'https://oauth2.googleapis.com/token',
      'iat': (now.millisecondsSinceEpoch / 1000).floor(),
      'exp': (now.add(Duration(minutes: 60)).millisecondsSinceEpoch / 1000).floor(),
    };

    String base64UrlEncode(Map<String, dynamic> jsonMap) {
      return base64Url.encode(utf8.encode(json.encode(jsonMap)))
          .replaceAll('=', '');
    }

    final jwtHeader = base64UrlEncode(header);
    final jwtPayload = base64UrlEncode(payload);
    final toSign = '$jwtHeader.$jwtPayload';

    final privateKey = jsonKey['private_key'];
    final rsaSigner = Signer(privateKey); // You’ll use `package:jwt_decode` alternative or external call

    final signature = rsaSigner.sign(toSign); // Or external workaround
    final jwt = '$toSign.$signature';

    final response = await http.post(
      Uri.parse('https://oauth2.googleapis.com/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion': jwt,
      },
    );

    final token = jsonDecode(response.body)['access_token'];
    _scopedTokenCache['access_token'] = token;
    return token;
  }

  Future<void> sendPushNotification({
    required String targetToken,
    required String title,
    required String body,
  }) async {
    final accessToken = await _getAccessToken();

    final projectId = jsonDecode(
      await File('secrets/service_account.json').readAsString(),
    )['project_id'];

    final message = {
      'message': {
        'token': targetToken,
        'notification': {
          'title': title,
          'body': body,
        },
        'data': {
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        }
      }
    };

    final response = await http.post(
      Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(message),
    );

    print('🔔 FCM response: ${response.statusCode}');
    print(response.body);
  }
}
