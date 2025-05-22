// routes/session_routes.dart
import 'dart:io';
import 'session/get_session_by_id.dart';
import 'session/get_full_session_by_id.dart';
import 'session/create_session.dart';
import 'session/accept_session.dart';

import 'session/cancel_session.dart';
import 'session/complete_session.dart';
import 'session/incoming_requests.dart';
import 'session/get_sessions.dart';
import 'session/active_tourist_sessions.dart';
import 'session/active_helper_sessions.dart';


class SessionRoutes {
  Future<bool> handleRequest(HttpRequest request, int userId) async {
    final path = request.uri.path;
    final method = request.method;

    print('[SessionRoutes] 🔍 Handling request: $method $path');

    if (RegExp(r'^/api/sessions/\d+/accept/?$').hasMatch(path) && method == 'PUT') {
      await handleAcceptSession(request, userId);
      return true;
    }



    if (path == '/api/sessions/create' && method == 'POST') {
      await handleCreateSession(request, userId);
      return true;
    }

    if (path == '/api/sessions' && method == 'GET') {
      await handleGetSessions(request, userId);
      return true;
    }

    if (path == '/api/sessions/incoming' && method == 'GET') {
      await handleIncomingRequests(request, userId);
      return true;
    }

    if (RegExp(r'^/api/sessions/\d+/complete/?$').hasMatch(path) && method == 'PUT') {
      await handleCompleteSession(request, userId);
      return true;
    }

    if (RegExp(r'^/api/sessions/\d+/cancel/?$').hasMatch(path) && method == 'PUT') {
      await handleCancelSession(request, userId);
      return true;
    }
    if (RegExp(r'^/api/sessions/\d+/set_mode/?$').hasMatch(path) && method == 'POST') {
      await handleSetNavigationMode(request, userId);
      return true;
    }


    if (path == '/api/sessions/active/tourist' && method == 'GET') {
      await handleActiveTouristSessions(request, userId);
      return true;
    }

    if (path == '/api/sessions/active/helper' && method == 'GET') {
      await handleActiveHelperSessions(request, userId);
      return true;
    }


    if (RegExp(r'^/api/sessions/\d+/?$').hasMatch(path) && method == 'GET') {
      await handleGetSessionById(request, userId);
      return true;
    }

    if (RegExp(r'^/api/sessions/\d+/full/?$').hasMatch(path) && method == 'GET') {
      await handleGetFullSessionById(request, userId);
      return true;
    }

    print('[SessionRoutes] ❌ No matching route found for: $method $path');
    return false;
  }




}
