import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:rsa_pkcs/rsa_pkcs.dart'; // ✅ Add this package

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

    String base64UrlEncodeClean(String input) {
      return base64Url.encode(utf8.encode(input)).replaceAll('=', '');
    }

    final jwtHeader = base64UrlEncodeClean(json.encode(header));
    final jwtPayload = base64UrlEncodeClean(json.encode(payload));
    final toSign = '$jwtHeader.$jwtPayload';

    // ✅ Sign JWT with private key using RS256
    final privateKeyPem = jsonKey['private_key'];
    final privateKey = RsaPrivateKey.fromPem(privateKeyPem);
    final signer = RsaSigner(RsaHash.sha256, privateKey);
    final signatureBytes = signer.sign(utf8.encode(toSign) as List<int>);
    final signature = base64Url.encode(signatureBytes).replaceAll('=', '');

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
