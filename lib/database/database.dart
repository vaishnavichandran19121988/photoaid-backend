import 'package:postgres/postgres.dart';

/// 🔐 Replace with your real Railway DB values
const String dbHost = 'mainline.proxy.rlwy.net';
const int dbPort = 25942;
const String dbName = 'railway';
const String dbUser = 'postgres';
const String dbPassword = 'kBQSGGjSXqDVomrjlPBYwpzkdbiOMcZB';

Connection? _singletonConnection;
Pool<Connection>? _connectionPool;

/// Hardcoded pool
Pool<Connection> getConnectionPool() {
  _connectionPool ??= Pool<Connection>.withEndpoints(
    [
      Endpoint(
        host: dbHost,
        port: dbPort,
        database: dbName,
        username: dbUser,
        password: dbPassword,
      ),
    ],
    settings: const PoolSettings(
      maxConnectionCount: 10,
      sslMode: SslMode.disable,
    ),
  );
  return _connectionPool!;
}

/// Debug print
void debugEnvVars() {
  print("🔎 DB_HOST: $dbHost");
  print("🔎 DB_PORT: $dbPort");
  print("🔎 DB_NAME: $dbName");
  print("🔎 DB_USER: $dbUser");
  print("🔎 DB_PASSWORD: $dbPassword");
}

/// Connection runner
Future<T> withDb<T>(Future<T> Function(Session) fn) async {
  return getConnectionPool().run(fn);
}

/// Cleanup
Future<void> closeDbConnections() async {
  if (_connectionPool != null) {
    await _connectionPool!.close();
    _connectionPool = null;
  } else if (_singletonConnection != null) {
    await _singletonConnection!.close();
    _singletonConnection = null;
  }
}
