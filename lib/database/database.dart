import 'package:dotenv/dotenv.dart';
import 'package:postgres/postgres.dart';

final _env = DotEnv()..load();

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


void debugEnvVars() {
  print('DB_HOST: ${Platform.environment['DB_HOST']}');
  print('DB_PORT: ${Platform.environment['DB_PORT']}');
  print('DB_NAME: ${Platform.environment['DB_NAME']}');
  print('DB_USER: ${Platform.environment['DB_USER']}');
  print('DB_PASSWORD: ${Platform.environment['DB_PASSWORD'] != null ? '***' : null}');
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
