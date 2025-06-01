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
  // ✅ Add this new method for role extraction
  static String? getUserRoleFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final data = jsonDecode(decoded);

      return data['role'];  // extract role field if present
    } catch (e) {
      print('❌ Error decoding JWT for role: $e');
      return null;
    }
  }

  // 🔥 NEW method to generate token
  static String generateToken(Map<String, dynamic> payload) {
    final header = {'alg': 'HS256', 'typ': 'JWT'};
    final base64Header =
        base64Url.encode(utf8.encode(jsonEncode(header))).replaceAll('=', '');
    final base64Payload =
        base64Url.encode(utf8.encode(jsonEncode(payload))).replaceAll('=', '');

    // NOTE: No signing — this is just for demo (same as you're doing currently)
    final token = '$base64Header.$base64Payload.signature';
    return token;
  }
}

