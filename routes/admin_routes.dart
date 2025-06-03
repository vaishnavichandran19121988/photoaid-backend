import 'dart:convert';
import 'dart:io';
import 'package:backend/services/admin_service.dart';
import 'package:backend/utils/jwt_utils.dart';

class AdminRoutes {
  final _adminService = AdminService();

  Future<bool> handleRequest(HttpRequest request) async {
    final path = request.uri.path;
    final method = request.method;
    final query = request.uri.queryParameters;

    print('[AdminRoute] 🔍 Incoming request: ${method.toUpperCase()} $path');

    try {
      // Verify token first
      final authHeader = request.headers.value('Authorization');
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        print('[AdminRoute] ❌ Missing Authorization header.');
        await _unauthorized(request);
        return true;
      }

      final token = authHeader.substring(7);
      final userId = JwtUtils.getUserIdFromToken(token);
      final userRole = JwtUtils.getUserRoleFromToken(token);

      print('[AdminRoute] ✅ Token parsed: userId=$userId, role=$userRole');

      if (userRole != 'admin') {
        print('[AdminRoute] ❌ Access denied: Not an admin');
        await _forbidden(request);
        return true;
      }

      // Dispatcher
      if (path == '/admin/summary' && method == 'GET') {
        await _handleSummary(request);
        return true;
      }

      if (path == '/admin/users' && method == 'GET') {
        final limit = int.tryParse(query['limit'] ?? '10') ?? 10;
        await _handleRecentUsers(request, limit);
        return true;
      }

      final userMatch = RegExp(r'^/admin/user/(\d+)$').firstMatch(path);
      if (userMatch != null) {
        final userIdParam = int.parse(userMatch.group(1)!);

        if (method == 'DELETE') {
          await _handleDeleteUser(request, userIdParam);
          return true;
        }
        if (method == 'PUT') {
  final body = await request.cast<List<int>>().transform(utf8.decoder).join();
  await _handleUpdateUser(userIdParam, body, request.response);
  return true;
}


      }

      return false;  // not handled
    } catch (e, st) {
      print('[AdminRoute] ❌ Exception: $e');
      print(st);
      request.response
        ..statusCode = 500
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'error': e.toString()}));
      await request.response.close();
      return true;
    }
  }

  // Handlers
  Future<void> _handleSummary(HttpRequest request) async {
    final summary = await _adminService.getSummary();
    request.response
      ..statusCode = 200
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(summary));
    await request.response.close();
  }

  Future<void> _handleRecentUsers(HttpRequest request, int limit) async {
    final users = await _adminService.getRecentUsers(limit);
    request.response
      ..statusCode = 200
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'users': users.map((u) => u.toJson()).toList()}));
    await request.response.close();
  }

  Future<void> _handleDeleteUser(HttpRequest request, int userId) async {
    final success = await _adminService.deleteUser(userId);
    request.response
      ..statusCode = 200
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'success': success}));
    await request.response.close();
  }

Future<void> _handleUpdateUser(int userId, String body, HttpResponse response) async {
  try {
    final data = jsonDecode(body) as Map<String, dynamic>;
    final fullName = data['fullName'] as String?;
    final email = data['email'] as String?;
    final bio = data['bio'] as String?;

    final success = await _adminService.updateUserDetails(
      userId: userId,
      fullName: fullName,
      email: email,
      bio: bio,
    );

    response
      ..statusCode = 200
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'success': success}));
    await response.close();
  } catch (e, st) {
    print('[AdminRoute] ❌ Exception during update: $e');
    print(st);
    response
      ..statusCode = 400
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'error': e.toString()}));
    await response.close();
  }
}


  // Helpers
  Future<void> _unauthorized(HttpRequest request) async {
    request.response
      ..statusCode = 401
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'error': 'Unauthorized'}));
    await request.response.close();
  }

  Future<void> _forbidden(HttpRequest request) async {
    request.response
      ..statusCode = 403
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'error': 'Forbidden: Admin access only'}));
    await request.response.close();
  }
}
