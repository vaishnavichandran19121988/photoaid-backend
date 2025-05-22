import 'dart:convert';           // for utf8, jsonDecode, jsonEncode
import 'dart:io';                // for HttpRequest, HttpStatus, ContentType

import 'package:backend/services/session_service.dart';  // for SessionService

Future<void> handleSetNavigationMode(HttpRequest request, int userId) async {
  print('🔔 handleSetNavigationMode called. Request path: ${request.uri.path}');

  final path = request.uri.path;
  final match = RegExp(r'^/api/sessions/(\d+)/set_mode/?$').firstMatch(path);
  if (match == null) {
    print('❌ Invalid path: $path');
    request.response.headers.contentType = ContentType.text;
    request.response.statusCode = HttpStatus.badRequest;
    request.response.write('Invalid path');
    await request.response.close();
    return;
  }

  final sessionId = int.parse(match.group(1)!);
  print('🔍 Parsed sessionId: $sessionId');

  if (request.method != 'POST') {
    print('❌ Method not allowed: ${request.method}');
    request.response.headers.contentType = ContentType.text;
    request.response.statusCode = HttpStatus.methodNotAllowed;
    request.response.write('Method not allowed');
    await request.response.close();
    return;
  }

  final bodyString = await utf8.decoder.bind(request).join();
  print('📦 Request body: $bodyString');
  final data = jsonDecode(bodyString) as Map<String, dynamic>;
  final mode = data['mode']?.toString();
  print('🔀 Requested navigation mode: $mode');

  if (mode != 'walking' && mode != 'driving') {
    print('❌ Invalid navigation mode received: $mode');
    request.response.headers.contentType = ContentType.json;
    request.response.statusCode = HttpStatus.badRequest;
    request.response.write(jsonEncode({'success': false, 'message': 'Invalid navigation mode'}));
    await request.response.close();
    return;
  }

  final session = await SessionService().findById(sessionId);
  if (session == null) {
    print('❌ Session not found for ID: $sessionId');
    request.response.headers.contentType = ContentType.json;
    request.response.statusCode = HttpStatus.notFound;
    request.response.write(jsonEncode({'success': false, 'message': 'Session not found'}));
    await request.response.close();
    return;
  }

  if (session.helperId != userId) {
    print('❌ Unauthorized user: userId=$userId does not match session.helperId=${session.helperId}');
    request.response.headers.contentType = ContentType.json;
    request.response.statusCode = HttpStatus.forbidden;
    request.response.write(jsonEncode({'success': false, 'message': 'Not authorized'}));
    await request.response.close();
    return;
  }

  final updatedSession = session.copyWith(navigationMode: mode);
  final result = await SessionService().updateSession(updatedSession);

  if (result == null) {
    print('❌ Failed to update session with new navigation mode');
    request.response.headers.contentType = ContentType.json;
    request.response.statusCode = HttpStatus.internalServerError;
    request.response.write(jsonEncode({'success': false, 'message': 'Failed to update session'}));
    await request.response.close();
    return;
  }

  print('✅ Session updated successfully with mode: $mode');

  request.response.headers.contentType = ContentType.json;
  request.response.statusCode = HttpStatus.ok;
  request.response.write(jsonEncode({'success': true, 'session': result.toJson()}));
  await request.response.close();
}
