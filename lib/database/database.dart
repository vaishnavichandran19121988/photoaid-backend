import 'dart:io'; // ✅ Use Dart's built-in env

import 'package:postgres/postgres.dart';

final _env = Platform.environment;

final bool useConnectionPool =
    _env['USE_CONNECTION_POOL']?.toLowerCase() == 'true';

Connection? _singletonConnection;



final Pool<Connection>? _connectionPool = useConnectionPool
    ? Pool<Connection>.withEndpoints(
        [
          Endpoint(
            host: _env['DB_HOST']!,
            port: int.parse(_env['DB_PORT']!),
            database: _env['DB_NAME']!,
            username: _env['DB_USER']!,
            password: _env['DB_PASSWORD']!,
          ),
        ],
        settings: const PoolSettings(
          maxConnectionCount: 10,
          sslMode: SslMode.disable,
        ),
      )
    : null;


void debugEnvVars() {
  print("🔎 DB_HOST: ${_env['DB_HOST']}");
  print("🔎 DB_PORT: ${_env['DB_PORT']}");
  print("🔎 DB_NAME: ${_env['DB_NAME']}");
  print("🔎 DB_USER: ${_env['DB_USER']}");
  print("🔎 DB_PASSWORD: ${_env['DB_PASSWORD']}");
  print("🔎 USE_CONNECTION_POOL: ${_env['USE_CONNECTION_POOL']}");
}

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

Future<T> withDb<T>(Future<T> Function(Session) fn) async {
  if (useConnectionPool) {
    return _connectionPool!.run(fn);
  } else {
    final conn = await _getSingletonConnection();
    return fn(conn);
  }
}

Future<void> closeDbConnections() async {
  if (useConnectionPool && _connectionPool != null) {
    await _connectionPool!.close();
  } else if (_singletonConnection != null) {
    await _singletonConnection!.close();
    _singletonConnection = null;
  }
}
