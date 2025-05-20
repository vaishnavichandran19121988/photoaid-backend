import 'dart:convert';
import 'dart:io';
import 'package:backend/services/auth_service.dart';
import 'package:backend/repositories/user_repository.dart';

Future<void> handleUpdateLocation(
    HttpRequest request, int userId, AuthService authService) async {
  try {
    print('Handling update location request for user $userId');

    // Parse request body
    final content = await utf8.decoder.bind(request).join();
    print('📩 Raw request body: $content');
    final data = jsonDecode(content) as Map<String, dynamic>;
    final userRepo = UserRepository();
    // Get the location coordinates from request body
    final locationLat = data['location_lat'];
    final locationLng = data['location_lng'];

    // Make sure coordinates are provided
    if (locationLat == null || locationLng == null) {
      request.response
        ..statusCode = 400
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({
          'success': false,
          'message': 'Validation failed',
          'errors': {
            'location_lat':
                'The location_lat parameter is required and must be a number',
            'location_lng':
                'The location_lng parameter is required and must be a number',
          },
        }))
        ..close();
      return;
    }

    // Convert to double
    double lat, lng;
    try {
      lat = double.parse(locationLat.toString());
      lng = double.parse(locationLng.toString());
    } catch (e) {
      request.response
        ..statusCode = 400
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({
          'success': false,
          'message': 'Validation failed',
          'errors': {
            'location_lat': 'The location_lat parameter must be a valid number',
            'location_lng': 'The location_lng parameter must be a valid number',
          },
        }))
        ..close();
      return;
    }

    print('Updating location to: ($lat, $lng)');

    // Update location
    final result = await userRepo.updateUserLocation(
      userId: userId,
      latitude: lat,
      longitude: lng,
    );

    if (!result['success']) {
      request.response
        ..statusCode = 500
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(result))
        ..close();
      return;
    }

    // Return success response
    // ✅ Fetch the updated user from DB
    final updatedUser = await userRepo.getUserById(userId);

    request.response
      ..statusCode = 200
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({
        'success': true,
        'message': 'Location updated successfully',
        'user': updatedUser?.toJson(), // ✅ This is what frontend expects
      }))
      ..close();
  } catch (e) {
    print('Error updating location: $e');
    request.response
      ..statusCode = 500
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({
        'success': false,
        'message': 'Error updating location: $e',
      }))
      ..close();
  }
}
