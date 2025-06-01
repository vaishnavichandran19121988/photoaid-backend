import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/services/auth_service.dart';

Future<Response> onRequest(RequestContext context) async {
  print('[AdminLoginRoute] 🔵 Incoming admin login request: ${context.request.method}');

  if (context.request.method != HttpMethod.post) {
    print('[AdminLoginRoute] ❌ Method not allowed: ${context.request.method}');
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final body = await context.request.body();
    print('[AdminLoginRoute] 📥 Raw body: $body');

    final data = jsonDecode(body) as Map<String, dynamic>;
    final usernameOrEmail = data['usernameOrEmail'] as String?;
    final password = data['password'] as String?;

    if (usernameOrEmail == null || password == null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'message': 'Missing fields: usernameOrEmail or password',
        },
      );
    }

    final authService = AuthService();
    final result = await authService.adminLogin(
      usernameOrEmail: usernameOrEmail,
      password: password,
    );

    print('[AdminLoginRoute] ✅ Admin Login result: $result');

    return Response.json(
      statusCode: result['success'] ? HttpStatus.ok : HttpStatus.unauthorized,
      body: result,
    );
  } catch (e, st) {
    print('[AdminLoginRoute] ❌ Exception: $e');
    print(st);

    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'success': false,
        'message': 'Failed admin login: ${e.toString()}',
      },
    );
  }
}
