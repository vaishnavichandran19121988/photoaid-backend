/// Model representing a user rating
class Rating {
  /// Unique identifier for the rating
  final int? id;
  
  /// ID of the session this rating is for
  final int sessionId;
  
  /// ID of the user who submitted the rating
  final int raterId;
  
  /// ID of the user who received the rating
  final int ratedId;
  
  /// Rating value (1-5 stars)
  final int rating;
  
  /// Optional comment with the rating
  final String? comment;
  
  /// When the rating was created
  final DateTime? createdAt;
  
  /// Constructor
  Rating({
    this.id,
    required this.sessionId,
    required this.raterId,
    required this.ratedId,
    required this.rating,
    this.comment,
    this.createdAt,
  });
  
  /// Create a copy of this Rating with the given fields replaced with new values
  Rating copyWith({
    int? id,
    int? sessionId,
    int? raterId,
    int? ratedId,
    int? rating,
    String? comment,
    DateTime? createdAt,
  }) {
    return Rating(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      raterId: raterId ?? this.raterId,
      ratedId: ratedId ?? this.ratedId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  /// Convert Rating to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'rater_id': raterId,
      'rated_user_id': ratedId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt?.toIso8601String(),
    };
  }
  
  /// Create Rating from JSON
  factory Rating.fromJson(Map<String, dynamic> json) {
    // Handle DateTime conversion
    DateTime? parseCreatedAt(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          print('Error parsing DateTime: $e, value: $value');
          return null;
        }
      }
      return null;
    }
    
    return Rating(
      id: json['id'] as int?,
      sessionId: json['session_id'] as int,
      raterId: json['rater_id'] as int,
      ratedId: json['rated_user_id'] as int,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: parseCreatedAt(json['created_at']),
    );
  }
}