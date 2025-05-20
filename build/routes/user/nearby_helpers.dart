import 'dart:convert';
import 'dart:io';

import 'package:backend/repositories/user_repository.dart';

Future<void> handleNearbyHelpers(HttpRequest request, int userId) async {
  try {
    final params = request.uri.queryParameters;
    final lat = double.tryParse(params['lat'] ?? '');
    final lng = double.tryParse(params['lng'] ?? '');
    final radius = double.tryParse(params['radius'] ?? '10');

    if (lat == null || lng == null || radius == null) {
      request.response
        ..statusCode = 400
        ..write(jsonEncode({'success': false, 'message': 'Invalid parameters'}))
        ..close();
      return;
    }

    final helpers = await UserRepository().findNearbyHelpers(lat, lng, radius);

    request.response
      ..statusCode = 200
      ..write(jsonEncode({
        'success': true,
        'helpers': helpers.map((e) => e.toJson()).toList()
      }))
      ..close();
  } catch (e) {
    request.response
      ..statusCode = 500
      ..write(jsonEncode({'success': false, 'message': 'Error: $e'}))
      ..close();
  }
}
