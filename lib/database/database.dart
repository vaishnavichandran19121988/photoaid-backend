import 'dart:io';
import 'package:postgres/postgres.dart';

final bool useConnectionPool =
    (Platform.environment['USE_CONNECTION_POOL']?.toLowerCase() == 'true');

Connection? _singletonConnection;

final Pool<Connection>? _connectionPool = useConnectionPool
    ? Pool<Connection>.withEndpoints(
        [
          Endpoint(
            host: Platform.environment['DB_HOST']!,
            port: int.parse(Platform.environment['DB_PORT']!),
            database: Platform.environment['DB_NAME']!,
            username: Platform.environment['DB_USER']!,
            password: Platform.environment['DB_PASSWORD']!,
          ),
        ],
        settings: const PoolSettings(
          maxConnectionCount: 10,
          sslMode: SslMode.require, // SSL enabled
        ),
      )
    : null;

Future<Connection> _getSingletonConnection() async {
  _singletonConnection ??= await Connection.open(
    Endpoint(
      host: Platform.environment['DB_HOST']!,
      port: int.parse(Platform.environment['DB_PORT']!),
      database: Platform.environment['DB_NAME']!,
      username: Platform.environment['DB_USER']!,
      password: Platform.environment['DB_PASSWORD']!,
    ),
    settings: const ConnectionSettings(
      sslMode: SslMode.require, // SSL enabled
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
