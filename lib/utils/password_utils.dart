class PasswordUtils {
  static String generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Encode(saltBytes);
  }

  static String hashPassword(String password, String salt) {
    final key = utf8.encode(password);
    final saltBytes = base64Decode(salt);  // <-- FIXED
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(saltBytes);
    return digest.toString();
  }
}
