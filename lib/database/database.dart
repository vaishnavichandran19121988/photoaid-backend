import 'dart:io';
import 'package:postgres/postgres.dart';

final String? databaseUrl = Platform.environment['DATABASE_URL'] ?? 
  'postgresql://postgres:kBQSGGjSXqDVomrjlPBYwpzkdbiOMcZB@mainline.proxy.rlwy.net:25942/railway';

final uri = Uri.parse(databaseUrl);

final host = uri.host;                // mainline.proxy.rlwy.net
final port = uri.port;                // 25942
final database = uri.pathSegments.first; // railway
final userInfo = uri.userInfo.split(':');
final username = userInfo[0];         // postgres
final password = userInfo[1];         // kBQSGGjSXqDVomrjlPBYwpzkdbiOMcZB

final connection = PostgreSQLConnection(
  host,
  port,
  database,
  username: username,
  password: password,
  useSSL: true, // Set true if your Railway DB requires SSL
);

Future<void> main() async {
  try {
    await connection.open();
    print('✅ Connected to DB!');
    // Run your queries or start your server here
  } catch (e) {
    print('❌ Failed to connect to DB: $e');
  }
}
