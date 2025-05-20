// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, implicit_dynamic_list_literal

import 'dart:io';

import 'package:dart_frog/dart_frog.dart';


import '../routes/user_routes.dart' as user_routes;
import '../routes/index.dart' as index;
import '../routes/chat_routes.dart' as chat_routes;
import '../routes/user/update_location.dart' as user_update_location;
import '../routes/user/toggle_helper.dart' as user_toggle_helper;
import '../routes/user/nearby_tourists.dart' as user_nearby_tourists;
import '../routes/user/nearby_helpers.dart' as user_nearby_helpers;
import '../routes/user/me.dart' as user_me;
import '../routes/session/start_session.dart' as session_start_session;
import '../routes/session/session_details.dart' as session_session_details;
import '../routes/session/reject_session.dart' as session_reject_session;
import '../routes/session/incoming_requests.dart' as session_incoming_requests;
import '../routes/session/get_sessions.dart' as session_get_sessions;
import '../routes/session/create_session.dart' as session_create_session;
import '../routes/session/complete_session.dart' as session_complete_session;
import '../routes/session/cancel_session.dart' as session_cancel_session;
import '../routes/session/active_session.dart' as session_active_session;
import '../routes/session/accept_session.dart' as session_accept_session;
import '../routes/chat/send_chat_message.dart' as chat_send_chat_message;
import '../routes/chat/get_chat_messages.dart' as chat_get_chat_messages;
import '../routes/auth/verify.dart' as auth_verify;
import '../routes/auth/register.dart' as auth_register;
import '../routes/auth/login.dart' as auth_login;


void main() async {
  final address = InternetAddress.anyIPv6;
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  createServer(address, port);
}

Future<HttpServer> createServer(InternetAddress address, int port) async {
  final handler = Cascade().add(buildRootHandler()).handler;
  final server = await serve(handler, address, port);
  print('\x1B[92m✓\x1B[0m Running on http://${server.address.host}:${server.port}');
  return server;
}

Handler buildRootHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..mount('/auth', (context) => buildAuthHandler()(context))
    ..mount('/chat', (context) => buildChatHandler()(context))
    ..mount('/session', (context) => buildSessionHandler()(context))
    ..mount('/user', (context) => buildUserHandler()(context))
    ..mount('/', (context) => buildHandler()(context));
  return pipeline.addHandler(router);
}

Handler buildAuthHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/verify', (context) => auth_verify.onRequest(context,))..all('/register', (context) => auth_register.onRequest(context,))..all('/login', (context) => auth_login.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildChatHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/send_chat_message', (context) => chat_send_chat_message.onRequest(context,))..all('/get_chat_messages', (context) => chat_get_chat_messages.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildSessionHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/start_session', (context) => session_start_session.onRequest(context,))..all('/session_details', (context) => session_session_details.onRequest(context,))..all('/reject_session', (context) => session_reject_session.onRequest(context,))..all('/incoming_requests', (context) => session_incoming_requests.onRequest(context,))..all('/get_sessions', (context) => session_get_sessions.onRequest(context,))..all('/create_session', (context) => session_create_session.onRequest(context,))..all('/complete_session', (context) => session_complete_session.onRequest(context,))..all('/cancel_session', (context) => session_cancel_session.onRequest(context,))..all('/active_session', (context) => session_active_session.onRequest(context,))..all('/accept_session', (context) => session_accept_session.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildUserHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/update_location', (context) => user_update_location.onRequest(context,))..all('/toggle_helper', (context) => user_toggle_helper.onRequest(context,))..all('/nearby_tourists', (context) => user_nearby_tourists.onRequest(context,))..all('/nearby_helpers', (context) => user_nearby_helpers.onRequest(context,))..all('/me', (context) => user_me.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/user_routes', (context) => user_routes.onRequest(context,))..all('/', (context) => index.onRequest(context,))..all('/chat_routes', (context) => chat_routes.onRequest(context,));
  return pipeline.addHandler(router);
}

