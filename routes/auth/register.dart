import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/services/auth_service.dart';

Future<Response> onRequest(RequestContext context) async {
  // Only allow POST requests
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    print('[REGISTER] Incoming request to /auth/register');
    // Parse the request body
    final body = await context.request.body();
    final data = jsonDecode(body) as Map<String, dynamic>;

    // Validate the request data
    final username = data['username'] as String?;
    final email = data['email'] as String?;
    final password = data['password'] as String?;
    final fullName = data['fullName'] as String?;

    if (username == null || email == null || password == null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'message': 'Missing required fields: username, email, or password',
        },
      );
    }

    // Create the auth service
    final authService = AuthService();

    // Register the user
    final result = await authService.register(
      username: username,
      email: email,
      password: password,
      fullName: fullName,
    );

    // Return the result
    return Response.json(
      statusCode: result['success'] ? HttpStatus.ok : HttpStatus.badRequest,
      body: result,
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'success': false,
        'message': 'Failed to register: ${e.toString()}',
      },
    );
  }
}