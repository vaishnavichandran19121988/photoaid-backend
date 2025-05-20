import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/services/auth_service.dart';

Future<Response> onRequest(RequestContext context) async {
  // Only allow GET requests
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    // Extract the Authorization header
    final authHeader = context.request.headers['Authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {
          'success': false,
          'message': 'Missing or invalid Authorization header',
        },
      );
    }

    // Extract the token
    final token = authHeader.substring(7); // Remove 'Bearer ' prefix

    // Create the auth service
    final authService = AuthService();

    // Verify the token
    final result = await authService.verifyToken(token);

    // Return the result
    return Response.json(
      statusCode: result['success'] ? HttpStatus.ok : HttpStatus.unauthorized,
      body: result,
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'success': false,
        'message': 'Failed to verify token: ${e.toString()}',
      },
    );
  }
}