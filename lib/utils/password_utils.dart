import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class PasswordUtils {
  /// ✅ Generate random salt (Base64 encoded)
  static String generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Encode(saltBytes);
  }

  /// ✅ Hash password using HMAC-SHA256 with Base64-decoded salt
  static String hashPassword(String password, String salt) {
    final key = utf8.encode(password);
    final saltBytes = base64Decode(salt);  // ✅ Correct decoding
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(saltBytes);
    return digest.toString();
  }
}
