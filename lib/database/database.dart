import 'dart:io'; // ✅ Use Dart's built-in env
import 'package:postgres/postgres.dart';

final _env = Platform.environment;

final bool useConnectionPool =
    _env['USE_CONNECTION_POOL']?.toLowerCase() == 'true';

Connection? _singletonConnection;
Pool<Connection>? _connectionPool;

/// Lazily initialize pool AFTER env is loaded
Pool<Connection> getConnectionPool() {
  _connectionPool ??= Pool<Connection>.withEndpoints(
    [
      Endpoint(
        host: _env['DB_HOST'] ?? 'MISSING_DB_HOST',
        port: int.tryParse(_env['DB_PORT'] ?? '') ?? 5432,
        database: _env['DB_NAME'] ?? 'MISSING_DB_NAME',
        username: _env['DB_USER'] ?? 'MISSING_DB_USER',
        password: _env['DB_PASSWORD'] ?? 'MISSING_DB_PASSWORD',
      ),
    ],
    settings: const PoolSettings(
      maxConnectionCount: 10,
      sslMode: SslMode.disable,
    ),
  );
  return _connectionPool!;
}

/// Prints environment variables for debugging
void debugEnvVars() {
  print("🧪 ENV KEYS: ${_env.keys.toList()}");
  print("🔎 DB_HOST: ${_env['DB_HOST']}");
  print("🔎 DB_PORT: ${_env['DB_PORT']}");
  print("🔎 DB_NAME: ${_env['DB_NAME']}");
  print("🔎 DB_USER: ${_env['DB_USER']}");
  print("🔎 DB_PASSWORD: ${_env['DB_PASSWORD']}");
  print("🔎 USE_CONNECTION_POOL: ${_env['USE_CONNECTION_POOL']}");
}

/// Use connection pool or singleton
Future<T> withDb<T>(Future<T> Function(Session) fn) async {
  if (useConnectionPool) {
    return getConnectionPool().run(fn);
  } else {
    final conn = await _getSingletonConnection();
    return fn(conn);
  }
}

/// Singleton fallback (no pool)
Future<Connection> _getSingletonConnection() async {
  _singletonConnection ??= await Connection.open(
    Endpoint(
      host: _env['DB_HOST']!,
      port: int.parse(_env['DB_PORT']!),
      database: _env['DB_NAME']!,
      username: _env['DB_USER']!,
      password: _env['DB_PASSWORD']!,
    ),
    settings: const ConnectionSettings(
      sslMode: SslMode.disable,
    ),
  );
  return _singletonConnection!;
}

/// Cleanup connections
Future<void> closeDbConnections() async {
  if (useConnectionPool && _connectionPool != null) {
    await _connectionPool!.close();
  } else if (_singletonConnection != null) {
    await _singletonConnection!.close();
    _singletonConnection = null;
  }
}
