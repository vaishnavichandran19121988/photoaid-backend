// routes/user_routes.dart
import 'dart:io';
import 'package:backend/services/auth_service.dart';

import 'user/me.dart';
import 'user/toggle_helper.dart';
import 'user/update_location.dart';
import 'user/nearby_helpers.dart';
import 'user/nearby_tourists.dart';

class UserRoutes {
  Future<bool> handleRequest(HttpRequest request, int userId) async {
    final path = request.uri.path;
    final method = request.method;

    if (path == '/api/users/me' && method == 'GET') {
      await handleGetMe(request, userId);
      return true;
    }

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

    return false;
  }
}
