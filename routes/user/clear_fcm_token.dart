import 'dart:io';
import 'dart:convert';
import 'package:backend/repositories/user_repository.dart';

Future<void>  handleClearPresence(HttpRequest request, int userId) async {
  try {
    await UserRepository().clearFcmToken(userId);
    request.response
      ..statusCode = 200
      ..write(jsonEncode({'success': true}))
      ..close();
  } catch (e) {
    request.response
      ..statusCode = 500
      ..write(jsonEncode({'success': false, 'error': e.toString()}))
      ..close();
  }
}
