// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, implicit_dynamic_list_literal

import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import '../realtime/web_socket_channel.dart' as chat_socket;



import '../routes/index.dart' as index;
import '../routes/auth/verify.dart' as auth_verify;
import '../routes/auth/register.dart' as auth_register;
import '../routes/auth/login.dart' as auth_login;


void main() async {
  final address = InternetAddress.tryParse('') ?? InternetAddress.anyIPv6;
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  hotReload(() => createServer(address, port));
}

Future<HttpServer> createServer(InternetAddress address, int port) {
  final handler = Cascade().add(buildRootHandler()).handler;
  return serve(handler, address, port);
}

Handler buildRootHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..mount('/auth', (context) => buildAuthHandler()(context))
    ..mount('/', (context) => buildHandler()(context));
  return pipeline.addHandler(router);
}

Handler buildAuthHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => index.onRequest(context))
    ..get('/ws/chat', (context) async {
      final request = context.request;
      final ioRequest = request.context['shelf.io.connection_info']?.httpRequest;
      if (ioRequest is HttpRequest) {
        await chat_socket.handleWebSocketChat(ioRequest);
      } else {
        return Response.internalServerError(body: 'Not a real HttpRequest');
      }
      return Response.ok(''); // Needed to satisfy return type
    });

  return pipeline.addHandler(router);
}


  Handler buildHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => index.onRequest(context,));
  return pipeline.addHandler(router);
}

