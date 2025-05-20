import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/services/auth_service.dart';

Future<Response> onRequest(RequestContext context) async {
  print('[LoginRoute] 🔵 Incoming request: ${context.request.method}');

  // Only allow POST requests
  if (context.request.method != HttpMethod.post) {
    print('[LoginRoute] ❌ Method not allowed: ${context.request.method}');
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    // Parse the request body
    final body = await context.request.body();
    print('[LoginRoute] 📥 Raw body: $body');

    final data = jsonDecode(body) as Map<String, dynamic>;
    print('[LoginRoute] 📦 Parsed JSON: $data');

    // Validate the request data
    final usernameOrEmail = data['usernameOrEmail'] as String?;
    final password = data['password'] as String?;

    if (usernameOrEmail == null || password == null) {
      print('[LoginRoute] ⚠️ Missing fields: $data');
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'message': 'Missing required fields: usernameOrEmail or password',
        },
      );
    }

    print('[LoginRoute] 🔐 Attempting login for: $usernameOrEmail');

    // Create the auth service
    final authService = AuthService();

    // Login the user
    final result = await authService.login(
      usernameOrEmail: usernameOrEmail,
      password: password,
    );

    print('[LoginRoute] ✅ Login result: $result');

    return Response.json(
      statusCode: result['success'] ? HttpStatus.ok : HttpStatus.unauthorized,
      body: result,
    );
  } catch (e, st) {
    print('[LoginRoute] ❌ Exception: $e');
    print(st);

    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'success': false,
        'message': 'Failed to login: ${e.toString()}',
      },
    );
  }
}
