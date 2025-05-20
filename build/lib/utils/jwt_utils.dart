import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class AuthUtils {

  static String getJwtSecret() {
    return Platform.environment['JWT_SECRET'] ?? 'default_secret';
  }
  // 🔐 Generate a cryptographic salt
  static String generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Encode(saltBytes);
  }

  // 🔐 Hash a password using HMAC SHA256 + salt
  static String hashPassword(String password, String salt) {
    final codec = Utf8Codec();
    final key = codec.encode(password);
    final saltBytes = codec.encode(salt);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(saltBytes);
    return digest.toString();
  }

  // 🔐 Generate a JWT token with user ID and 30-day expiry
  static String generateToken(int userId) {
    final jwt = JWT({
      'userId': userId,
      'exp': DateTime.now().add(Duration(days: 30)).millisecondsSinceEpoch ~/ 1000,
    });

    return jwt.sign(SecretKey(_getJwtSecret()));
  }

  // 🔓 Decode userId from JWT token (without verifying signature)
  static int? getUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final data = jsonDecode(decoded);

      print('🧬 Decoded JWT payload: $data');
      return data['userId'] ?? data['id'];
    } catch (e) {
      print('❌ Error decoding JWT: $e');
      return null;
    }
  }

  // 🔐 Internal: Get secret key from environment
  static String _getJwtSecret() {
    return Platform.environment['JWT_SECRET'] ?? 'photoaid_default_secret_key';
  }
}
