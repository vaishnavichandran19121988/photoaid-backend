import 'dart:convert';

class JwtUtils {
  static int? getUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final data = jsonDecode(decoded);

      print('🧬 Decoded JWT payload: $data'); // Add this for debugging

      // Check for both common key names: userId or id
      return data['userId'] ?? data['id'];
    } catch (e) {
      print('❌ Error decoding JWT: $e');
      return null;
    }
  }
}
