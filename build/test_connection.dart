import 'database/database.dart';

void main() async {
  try {
    final conn = await openDbConnection();
    final result = await conn.query('SELECT NOW()');
    print('✅ Connected to NeonDB: ${result.first.first}');
  } catch (e) {
    print('❌ Connection failed: $e');
  } finally {
    await closeDbConnection();
  }
}
