import 'dart:io';

Map<String, String> loadEnvFile([String path = '.env']) {
  final file = File(path);
  final lines = file.readAsLinesSync();
  final env = <String, String>{};

  for (final line in lines) {
    if (line.trim().isEmpty || line.trim().startsWith('#')) continue;
    final index = line.indexOf('=');
    if (index != -1) {
      final key = line.substring(0, index).trim();
      final value = line.substring(index + 1).trim();
      env[key] = value;
    }
  }

  return env;
}
