import 'package:postgres/postgres.dart';

/// Run database migrations for setting up the database schema
Future<void> runMigrations(Session session) async {
  print('Running database migrations...');

  try {
    await session.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        username VARCHAR(50) UNIQUE NOT NULL,
        email VARCHAR(100) UNIQUE NOT NULL,
        password_hash VARCHAR(100) NOT NULL,
        full_name VARCHAR(100),
        profile_image_url TEXT,
        bio TEXT,
        location_lat DOUBLE PRECISION,
        location_lng DOUBLE PRECISION,
        is_available BOOLEAN DEFAULT FALSE,
        role VARCHAR(20) DEFAULT 'user',
        salt TEXT,
        fcm_token TEXT,
        average_rating DOUBLE PRECISION DEFAULT 0,
        total_ratings INTEGER DEFAULT 0,
        created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await session.execute('''
      CREATE TABLE IF NOT EXISTS sessions (
        id SERIAL PRIMARY KEY,
        tourist_id INTEGER REFERENCES users(id),
        helper_id INTEGER REFERENCES users(id),
        status VARCHAR(20) NOT NULL,
        meeting_point_lat DOUBLE PRECISION,
        meeting_point_lng DOUBLE PRECISION,
        meeting_time TIMESTAMP,
        description TEXT,
        created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
        completed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP

      )
    ''');

    await session.execute('''
      CREATE TABLE IF NOT EXISTS chat_messages (
        id SERIAL PRIMARY KEY,
        session_id INTEGER REFERENCES sessions(id) ON DELETE CASCADE,
        sender_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        receiver_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        content TEXT NOT NULL,
        sent_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
        is_read BOOLEAN DEFAULT FALSE
      )
    ''');

    await session.execute('''
      CREATE TABLE IF NOT EXISTS ratings (
        id SERIAL PRIMARY KEY,
        session_id INTEGER REFERENCES sessions(id),
        rater_id INTEGER REFERENCES users(id),
        rated_id INTEGER REFERENCES users(id),
        rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
        comment TEXT,
        created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await session.execute('''
  CREATE TABLE IF NOT EXISTS session_status_logs (
    id SERIAL PRIMARY KEY,
    session_id INTEGER NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL,
    changed_by_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
  )
''');


    print('✅ Migrations completed.');
  } catch (e) {
    print('❌ Error during migrations: $e');
    rethrow;
  }
}
