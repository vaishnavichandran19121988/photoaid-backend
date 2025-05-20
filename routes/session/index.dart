import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405, body: 'Method Not Allowed');
  }

  try {
    final body = await context.request.json();

    final helperId = body['helper_id'];
    final latitude = body['latitude'];
    final longitude = body['longitude'];
    final description = body['description'];

    if (helperId == null || latitude == null || longitude == null) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'Missing required fields'},
      );
    }

    // 🔧 TODO: Insert into database
    print('✅ Session request received: helperId=$helperId, lat=$latitude, lng=$longitude');

    return Response.json(
      statusCode: 201,
      body: {'message': 'Session created'},
    );
  } catch (e) {
    print('❌ Error: $e');
    return Response.json(
      statusCode: 500,
      body: {'error': 'Failed to create session: $e'},
    );
  }
}
