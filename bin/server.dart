import 'dart:convert';
import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:backend/database/database.dart';
import 'package:backend/services/auth_service.dart';
import 'package:backend/utils/jwt_utils.dart';
import '../routes/rating_routes.dart';
import 'package:backend/services/chat_service.dart'; // ✅ NEW
import 'package:backend/repositories/chat_repository.dart'; // ✅ NEW
import 'package:backend/repositories/session_repository.dart'; // ✅ NEW
import 'package:backend/repositories/user_repository.dart'; // ✅ NEW

import '../routes/user_routes.dart';
import '../routes/session_routes.dart';
import '../routes/chat_routes.dart'; // ✅ NEW

final userRoutes = UserRoutes();
final sessionRoutes = SessionRoutes();
final chatRoutes = ChatRoutes(); // ✅ NEW
final ratingRoutes = RatingRoutes();
final Map<int, List<WebSocket>> sessionSockets = {};

Future<void> main() async {
  print('🚀 Starting PhotoAid HTTP Server...');

  try {
    await withDb((session) async {
      final result = await session.execute('SELECT 1');
      print('✅ Database connected: $result');
    });
  } catch (e) {
    print('❌ Failed to connect to DB: $e');
    exit(1);
  }

  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  print('✅ Server running at http://${server.address.address}:${server.port}');

  await for (final request in server) {
    final path = request.uri.path;
    print('[${request.method}] $path');

    // CORS headers
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add(
        'Access-Control-Allow-Headers', 'Origin, Content-Type, Authorization');
    request.response.headers.add('Access-Control-Allow-Methods',
        'GET, POST, PUT, PATCH, DELETE, OPTIONS');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = 204;
      await request.response.close();
      continue;
    }
    if (path.startsWith('/ws/chat/')) {
      final sessionIdStr = path.split('/').last;
      final sessionId = int.tryParse(sessionIdStr);

      if (sessionId == null) {
        request.response
          ..statusCode = 400
          ..write('Invalid session ID')
          ..close();
        continue;
      }

      if (WebSocketTransformer.isUpgradeRequest(request)) {
        final socket = await WebSocketTransformer.upgrade(request);
        print('🔌 WebSocket connected for session $sessionId');

        sessionSockets.putIfAbsent(sessionId, () => []).add(socket);

        socket.listen((data) async {
          final msg = jsonDecode(data);
          print('💬 Incoming WebSocket message: $msg');

          final senderId = msg['sender_id'];
          final content = msg['message'];
          final receiverId = msg['receiver_id'];

          if (senderId == null || content == null) {
            print('❌ Invalid message format.');
            return;
          }

          // ✅ Save message in DB
          final chatService = ChatService(
            ChatRepository(),
            SessionRepository(),
            UserRepository(),
          );

          final savedMessage = await chatService.sendMessage(
            sessionId,
            senderId,
            receiverId,
            content,
          );

          if (savedMessage == null) {
            print('❌ Failed to save message to DB');
            return;
          }

          // ✅ Build and broadcast message to all sockets in the session
          final messageJson = jsonEncode({
            'session_id': sessionId,
            'sender_id': senderId,
            'receiver_id': receiverId,
            'message': content,
            'sent_at': DateTime.now().toIso8601String(),
          });

          for (final client in List<WebSocket>.from(sessionSockets[sessionId]!)) {
            try {
              client.add(messageJson);
            } catch (e) {
              print('❌ Failed to send to socket: $e');
              sessionSockets[sessionId]?.remove(client);
            }
          }
        }, onDone: () {
          sessionSockets[sessionId]?.remove(socket);
          print('🔌 Socket disconnected from session $sessionId');
        }, onError: (error) {
          sessionSockets[sessionId]?.remove(socket);
          print('⚠️ Socket error in session $sessionId: $error');
        });
      } else {
        request.response
          ..statusCode = 426
          ..write('Expected WebSocket upgrade')
          ..close();
      }

      continue;
    }


    // ✅ Serve static uploaded files like profile images
    if (request.uri.path.startsWith('/uploads/')) {
      final file = File('.${request.uri.path}'); // maps to ./uploads/profile_images/6.jpg

      if (await file.exists()) {
        final ext = file.path.split('.').last.toLowerCase();
        if (ext == 'jpg' || ext == 'jpeg') {
          request.response.headers.contentType = ContentType('image', 'jpeg');
        } else if (ext == 'png') {
          request.response.headers.contentType = ContentType('image', 'png');
        } else {
          request.response.headers.contentType = ContentType.binary;
        }

        await request.response.addStream(file.openRead());
        await request.response.close();
        continue; // ⬅️ Skip the rest of the routing
      } else {
        request.response
          ..statusCode = 404
          ..write('File not found')
          ..close();
        continue;
      }
    }


    try {
      if (path == '/auth/register' && request.method == 'POST') {
        await _handleRegister(request);
      } else if (path == '/auth/login' && request.method == 'POST') {
        await _handleLogin(request);
      } else if (path == '/auth/verify') {
        final authHeader = request.headers.value('Authorization');
        print('🧪 /auth/verify header: $authHeader');

        if (authHeader == null || !authHeader.startsWith('Bearer ')) {
          request.response
            ..statusCode = 401
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({
              'success': false,
              'message': 'Missing or invalid Authorization header'
            }))
            ..close();
          continue;
        }

        final token = authHeader.substring(7);
        final result = await AuthService().verifyToken(token);
        print('✅ Verification result: $result');

        request.response
          ..statusCode = result['success'] ? 200 : 401
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(result))
          ..close();
      } else if (path.startsWith('/api/users') ||
          path.startsWith('/api/sessions') ||
          path.startsWith('/api/chat') ||
          path.startsWith('/api/ratings'))
      {
        final authHeader = request.headers.value('Authorization');
        print("🔍 Raw auth header: $authHeader");

        if (authHeader == null || !authHeader.startsWith('Bearer ')) {
          request.response
            ..statusCode = 401
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'success': false, 'message': 'Unauthorized'}))
            ..close();
          continue;
        }

        final token = authHeader.substring(7);
        final userId = JwtUtils.getUserIdFromToken(token);
        print('👤 Parsed user ID: $userId');

        if (userId == null) {
          request.response
            ..statusCode = 401
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'success': false, 'message': 'Invalid token'}))
            ..close();
          continue;
        }

        final wasHandled = await chatRoutes.handleRequest(
            request, userId)||await userRoutes.handleRequest(request, userId) ||
            await sessionRoutes.handleRequest(request, userId) ||

      await ratingRoutes.handleRequest(request, userId); // ✅ ADD CHAT ROUTES

        if (!wasHandled) {
          request.response
            ..statusCode = 404
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'error': 'Route not handled'}))
            ..close();
        }
      } else {
        request.response
          ..statusCode = 404
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'error': 'Not found'}))
          ..close();
      }
    } catch (e, st) {
      print('❌ Server Error: $e\n$st');

      try {
        request.response
          ..statusCode = 500
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({
            'success': false,
            'message': 'Internal server error',
            'error': e.toString()
          }))
          ..close();
      } catch (_) {
        print('⚠️ Response already closed — skipping second write.');
      }
    }
  }
}

Future<void> _handleRegister(HttpRequest request) async {
  try {
    final body = await utf8.decoder.bind(request).join();
    final data = jsonDecode(body) as Map<String, dynamic>;

    final result = await AuthService().register(
      username: data['username'],
      email: data['email'],
      password: data['password'],
      fullName: data['fullName'],
    );

    request.response
      ..statusCode = result['success'] == true ? 201 : 400
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(result))
      ..close();
  } catch (e) {
    print('Error in /auth/register: $e');
    request.response
      ..statusCode = 500
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'success': false, 'message': 'Server error'}))
      ..close();
  }
}

Future<void> _handleLogin(HttpRequest request) async {
  try {
    final body = await utf8.decoder.bind(request).join();
    final data = jsonDecode(body) as Map<String, dynamic>;

    final usernameOrEmail = data['usernameOrEmail'];
    final password = data['password'];

    if (usernameOrEmail == null || password == null) {
      print('[Auth] ⚠️ Missing usernameOrEmail or password');
      request.response
        ..statusCode = 400
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({
          'success': false,
          'message': 'Missing required fields: usernameOrEmail and/or password',
        }))
        ..close();
      return;
    }

    final result = await AuthService().login(
      usernameOrEmail: usernameOrEmail,
      password: password,
    );

    request.response
      ..statusCode = result['success'] == true ? 200 : 401
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(result))
      ..close();
  } catch (e) {
    print('Error in /auth/login: $e');
    request.response
      ..statusCode = 500
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'success': false, 'message': 'Server error'}))
      ..close();
  }
}
