import 'dart:convert';
import 'dart:io';
import 'package:backend/services/admin_service.dart';
import 'package:backend/utils/jwt_utils.dart';
import 'package:dart_frog/dart_frog.dart';

final _adminService = AdminService();

Future<Response> onRequest(RequestContext context) async {
  final request = context.request;
  final method = request.method;
  final path = request.uri.path;
  final query = request.uri.queryParameters;

  print('[AdminRoute] 🔍 Incoming request: ${method.toUpperCase()} ${request.uri}');

  try {
    // Verify token first
    final authHeader = request.headers.value('Authorization');
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      print('[AdminRoute] ❌ Missing Authorization header.');
      return _unauthorized();
    }

    final token = authHeader.substring(7);
    final userId = JwtUtils.getUserIdFromToken(token);
    final userRole = JwtUtils.getUserRoleFromToken(token);  // Optional if you store role in token

    print('[AdminRoute] ✅ Token parsed: userId=$userId, role=$userRole');

    // If you store role inside JWT — validate role here (or you can skip this if handled already)
    if (userRole != 'admin') {
      print('[AdminRoute] ❌ Access denied: Not an admin');
      return _forbidden();
    }

    // Route dispatcher
    if (path.endsWith('/admin/summary') && method == HttpMethod.get) {
      return await _handleSummary();
    }

    if (path.endsWith('/admin/users') && method == HttpMethod.get) {
      final limit = int.tryParse(query['limit'] ?? '10') ?? 10;
      return await _handleRecentUsers(limit);
    }

    // Handle /admin/user/:id routes
    final userMatch = RegExp(r'^/admin/user/(\d+)$').firstMatch(path);
    if (userMatch != null) {
      final userIdParam = int.parse(userMatch.group(1)!);

      if (method == HttpMethod.delete) {
        return await _handleDeleteUser(userIdParam);
      }
      if (method == HttpMethod.put) {
        final body = await request.body();
        return await _handleUpdateUser(userIdParam, body);
      }
    }

    // Unknown route
    return Response.json(statusCode: 404, body: {'error': 'Route not found'});
  } catch (e, st) {
    print('[AdminRoute] ❌ Exception: $e');
    print(st);
    return Response.json(statusCode: 500, body: {'error': e.toString()});
  }
}

// ✅ Summary API
Future<Response> _handleSummary() async {
  print('[AdminRoute] 🔧 Processing /admin/summary');
  final summary = await _adminService.getSummary();
  return Response.json(body: summary);
}

// ✅ Recent Users API
Future<Response> _handleRecentUsers(int limit) async {
  print('[AdminRoute] 🔧 Processing /admin/users?limit=$limit');
  final users = await _adminService.getRecentUsers(limit);
  return Response.json(body: {'users': users.map((u) => u.toJson()).toList()});
}

// ✅ Delete User API
Future<Response> _handleDeleteUser(int userId) async {
  print('[AdminRoute] 🔧 Processing DELETE for userId=$userId');
  final success = await _adminService.deleteUser(userId);
  return Response.json(body: {'success': success});
}

// ✅ Update User API
Future<Response> _handleUpdateUser(int userId, String body) async {
  print('[AdminRoute] 🔧 Processing PUT for userId=$userId');
  final data = jsonDecode(body) as Map<String, dynamic>;
  final fullName = data['fullName'] as String?;
  final email = data['email'] as String?;
  final bio = data['bio'] as String?;

  print('[AdminRoute] ✏ Incoming update data: fullName=$fullName, email=$email, bio=$bio');

  final success = await _adminService.updateUserDetails(
    userId: userId,
    fullName: fullName,
    email: email,
    bio: bio,
  );

  return Response.json(body: {'success': success});
}

// ✅ Common Unauthorized response
Response _unauthorized() => Response.json(
  statusCode: 401,
  body: {'error': 'Unauthorized'},
);

// ✅ Common Forbidden response
Response _forbidden() => Response.json(
  statusCode: 403,
  body: {'error': 'Forbidden: Admin access only'},
);
