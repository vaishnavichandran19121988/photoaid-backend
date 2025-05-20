import 'package:backend/database/database.dart';
import '../models/rating.dart';
import 'package:postgres/postgres.dart' as pg;



class RatingRepository {
  static final RatingRepository _instance = RatingRepository._internal();
  factory RatingRepository() => _instance;
  RatingRepository._internal();

  Future<Rating?> findById(int id) async {
    try {
      return await withDb((session) async {
        final result = await session.execute(
          'SELECT * FROM ratings WHERE id = @id',
          parameters: {'id': id},
        );
        return result.isEmpty
            ? null
            : Rating.fromJson(result.first.toColumnMap());
      });
    } catch (e) {
      print('Error finding rating by ID: $e');
      return null;
    }
  }

  Future<List<Rating>> findBySessionId(int sessionId) async {
    try {
      return await withDb((session) async {
        final result = await session.execute(
          'SELECT * FROM ratings WHERE session_id = @sessionId',
          parameters: {'sessionId': sessionId},
        );
        return result.map((row) => Rating.fromJson(row.toColumnMap())).toList();
      });
    } catch (e) {
      print('Error finding ratings by session ID: $e');
      return [];
    }
  }

  Future<List<Rating>> findByRatedUserId(int ratedId) async {
    try {
      return await withDb((session) async {
        final result = await session.execute(
          'SELECT * FROM ratings WHERE rated_id = @ratedId',
          parameters: {'ratedId': ratedId},
        );
        return result.map((row) => Rating.fromJson(row.toColumnMap())).toList();
      });
    } catch (e) {
      print('Error finding ratings by rated user ID: $e');
      return [];
    }
  }

  Future<List<Rating>> findByRaterId(int raterId) async {
    try {
      return await withDb((session) async {
        final result = await session.execute(
          'SELECT * FROM ratings WHERE rater_id = @raterId',
          parameters: {'raterId': raterId},
        );
        return result.map((row) => Rating.fromJson(row.toColumnMap())).toList();
      });
    } catch (e) {
      print('Error finding ratings by rater ID: $e');
      return [];
    }
  }

  Future<Rating?> findExistingRating(
      int sessionId, int raterId, int ratedId) async {
    try {
      return await withDb((session) async {
        final result = await session.execute(
          '''
          SELECT * FROM ratings 
          WHERE session_id = @sessionId AND rater_id = @raterId AND rated_id = @ratedId
          ''',
          parameters: {
            'sessionId': sessionId,
            'raterId': raterId,
            'ratedId': ratedId,
          },
        );
        return result.isEmpty
            ? null
            : Rating.fromJson(result.first.toColumnMap());
      });
    } catch (e) {
      print('Error finding existing rating: $e');
      return null;
    }
  }

  Future<Rating?> createRating(Rating rating) async {
    try {
      return await withDb((session) async {
        final result = await session.execute(
          pg.Sql.named('''
          INSERT INTO ratings (
            session_id, rater_id, rated_id, rating, comment, created_at
          ) VALUES (
            @sessionId, @raterId, @ratedId, @rating, @comment, @createdAt
          ) RETURNING *
        '''),
          parameters: {
            'sessionId': rating.sessionId,
            'raterId': rating.raterId,
            'ratedId': rating.ratedId,
            'rating': rating.rating,
            'comment': rating.comment,
            'createdAt': DateTime.now(),
          },
        );

        if (result.isEmpty) {
          print('⚠️ Rating insert succeeded but RETURNING * returned no rows.');
          return Rating(
            id: null,
            sessionId: rating.sessionId,
            raterId: rating.raterId,
            ratedId: rating.ratedId,
            rating: rating.rating,
            comment: rating.comment,
            createdAt: DateTime.now(),
          );
        }

        final row = result.first.toColumnMap();
        print('✅ Created Rating: $row');
        return Rating.fromJson(row);
      });
    } catch (e) {
      print('❌ Error creating rating: $e');
      return null;
    }
  }

  Future<Rating?> updateRating(Rating rating) async {
    try {
      return await withDb((session) async {
        final result = await session.execute(
          '''
          UPDATE ratings
          SET rating = @rating, comment = @comment
          WHERE id = @id
          RETURNING *
          ''',
          parameters: {
            'id': rating.id,
            'rating': rating.rating,
            'comment': rating.comment,
          },
        );
        return result.isEmpty
            ? null
            : Rating.fromJson(result.first.toColumnMap());
      });
    } catch (e) {
      print('Error updating rating: $e');
      return null;
    }
  }

  Future<bool> deleteRating(int id) async {
    try {
      return await withDb((session) async {
        await session.execute(
          'DELETE FROM ratings WHERE id = @id',
          parameters: {'id': id},
        );
        return true;
      });
    } catch (e) {
      print('Error deleting rating: $e');
      return false;
    }
  }

  Future<double?> getUserAverageRating(int userId) async {
    try {
      return await withDb((session) async {
        final result = await session.execute(
          'SELECT AVG(rating)::numeric(3,2) as average FROM ratings WHERE rated_id = @userId',
          parameters: {'userId': userId},
        );
        if (result.isEmpty) return null;
        final row = result.first.toColumnMap();
        return row['average'] != null
            ? (row['average'] as num).toDouble()
            : null;
      });
    } catch (e) {
      print('Error calculating user average rating: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getRatingStats(int userId) async {
    try {
      return await withDb((session) async {
        final result = await session.execute('''
          SELECT 
            AVG(rating)::numeric(3,2) as average,
            COUNT(*) as count,
            SUM(CASE WHEN rating = 1 THEN 1 ELSE 0 END) as star1,
            SUM(CASE WHEN rating = 2 THEN 1 ELSE 0 END) as star2,
            SUM(CASE WHEN rating = 3 THEN 1 ELSE 0 END) as star3,
            SUM(CASE WHEN rating = 4 THEN 1 ELSE 0 END) as star4,
            SUM(CASE WHEN rating = 5 THEN 1 ELSE 0 END) as star5
          FROM ratings
          WHERE rated_id = @userId
        ''', parameters: {
          'userId': userId,
        });

        if (result.isEmpty) {
          return {
            'average': null,
            'count': 0,
            'distribution': {
              '1': 0,
              '2': 0,
              '3': 0,
              '4': 0,
              '5': 0,
            },
          };
        }

        final row = result.first.toColumnMap();
        return {
          'average': row['average'],
          'count': row['count'],
          'distribution': {
            '1': row['star1'],
            '2': row['star2'],
            '3': row['star3'],
            '4': row['star4'],
            '5': row['star5'],
          },
        };
      });
    } catch (e) {
      print('Error getting rating statistics: $e');
      return {
        'average': null,
        'count': 0,
        'distribution': {
          '1': 0,
          '2': 0,
          '3': 0,
          '4': 0,
          '5': 0,
        },
      };
    }
  }

  Future<void> updateUserRatingSummary(int userId) async {
    try {
      await withDb((session) async {
        final result = await session.execute(
          pg.Sql.named('''
          SELECT 
            AVG(rating)::numeric(3,2) AS average, 
            COUNT(*) AS total 
          FROM ratings 
          WHERE rated_id = @userId
        '''),
          parameters: {'userId': userId},
        );

        if (result.isEmpty) return;

        final row = result.first.toColumnMap();
        final avgRaw = row['average'];
        final avg = avgRaw is num
            ? avgRaw.toDouble()
            : avgRaw is String
            ? double.tryParse(avgRaw) ?? 0.0
            : 0.0;
        final total = row['total'] ?? 0;

        await session.execute(
          pg.Sql.named('''
          UPDATE users 
          SET average_rating = @avg, 
              total_ratings = @total, 
              updated_at = NOW()
          WHERE id = @userId
        '''),
          parameters: {
            'avg': avg,
            'total': total,
            'userId': userId,
          },
        );

        print('✅ Rating summary updated for user $userId: $avg stars over $total ratings');
      });
    } catch (e) {
      print('❌ Error in updateUserRatingSummary: $e');
    }
  }

}
