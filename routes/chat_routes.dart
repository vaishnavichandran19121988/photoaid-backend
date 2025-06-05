import 'dart:io';

import 'chat/send_chat_message.dart';
import 'chat/get_chat_messages.dart';
import 'chat/report_abuse.dart';

class ChatRoutes {
  Future<bool> handleRequest(HttpRequest request, int userId) async {
    final path = request.uri.path;
    final method = request.method;
    if (RegExp(r'^/api/chat/messages/\d+$').hasMatch(path) && method == 'GET') {
      await handleGetChatMessages(request, userId);
      return true;
    }
    if (RegExp(r'^/api/chat/messages/\d+/send$').hasMatch(path) && method == 'POST') {
      await handleSendChatMessage(request, userId);
      return true;
    }
     if (path == '/api/chat/report_abuse' && method == 'POST') {
      await handleReportAbuse(request, userId);
      return true;
    }

    // 📨 Send a new chat message
    if (RegExp(r'^/api/chat/messages/\d+/send$').hasMatch(path) &&
        method == 'POST') {
      await handleSendChatMessage(request, userId);
      return true;
    }

    // 📥 Get chat messages for a session (e.g., /api/chat/messages/1)
    if (RegExp(r'^/api/chat/messages/\d+$').hasMatch(path) && method == 'GET') {
      await handleGetChatMessages(request, userId);
      return true;
    }

    // 🚫 No chat route matched
    return false;
  }
}
