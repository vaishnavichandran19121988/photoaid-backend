import 'dart:io';
import 'user/update_profile.dart';
import 'user/get_by_id.dart';

import 'user/toggle_helper.dart';
import 'user/update_location.dart';
import 'user/nearby_helpers.dart';
import 'user/nearby_tourists.dart';
import 'user/update_fcm_token.dart';
import 'user/clear_fcm_token.dart';
import 'package:backend/services/auth_service.dart';


// ✅ Add this at the top
class UserRoutes {
  Future<bool> handleRequest(HttpRequest request, int userId) async {
    final path = request.uri.path;
    final method = request.method;



    if (path == '/api/users/toggle_helper' &&
        (method == 'PUT' || method == 'PATCH')) {
      await handleToggleHelper(request, userId);
      return true;
    }

    if ((path == '/api/users/update_location' ||
        path == '/api/users/location') &&
        (method == 'PUT' || method == 'PATCH')) {
      await handleUpdateLocation(request, userId, AuthService());
      return true;
    }

    if (path == '/api/users/nearby_helpers' && method == 'GET') {
      await handleNearbyHelpers(request, userId);
      return true;
    }

    if (path == '/api/users/nearby_tourists' && method == 'GET') {
      await handleNearbyTourists(request, userId);
      return true;
    }

    if (path == '/api/users/register_fcm' && method == 'POST') {
      await handleUpdateFcmToken(request, userId);
      return true;
    }
    if (path == '/api/users/clear_presence' && method == 'POST') {
      await handleClearPresence(request, userId);
      return true;
    }

    if (path == '/api/users/update_profile' && method == 'POST') {
      await handleUpdateProfile(request);
      return true;
    }

    // ✅ This must be LAST to avoid hijacking other routes

    if (path == '/api/users/profile' && method == 'GET') {
      await handleGetUserProfile(request);
      return true;
    }

    return false;
  }
}
