class User {
  final int id;
  final String username;
  final String email;
  final String? fullName;
  final String? profileImageUrl;
  final String? bio;
  final double? locationLat;
  final double? locationLng;
  final bool isAvailable;
  final String role;
  final double? averageRating;
  final int? totalRatings;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? salt;
  final String? fcmToken; // ✅ camelCase

  User({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    this.profileImageUrl,
    this.bio,
    this.locationLat,
    this.locationLng,
    required this.isAvailable,
    required this.role,
    this.averageRating,
    this.totalRatings,
    required this.createdAt,
    required this.updatedAt,
    this.salt,
    this.fcmToken,
  });

  String get name => fullName ?? username;

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    username: json['username'],
    email: json['email'],
    fullName: json['full_name'],
    profileImageUrl: json['profile_image_url'],
    bio: json['bio'],
    locationLat: (json['location_lat'] as num?)?.toDouble(),
    locationLng: (json['location_lng'] as num?)?.toDouble(),
    isAvailable: json['is_available'],
    role: json['role'],
    averageRating: (json['average_rating'] as num?)?.toDouble(),
    totalRatings: json['total_ratings'],
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
    salt: json['salt'],
    fcmToken: json['fcm_token'], // ✅ from backend
  );

  factory User.fromDatabaseRow(Map<String, dynamic> row) => User(
    id: row['id'] as int,
    username: row['username'] as String,
    email: row['email'] as String,
    fullName: row['full_name'] as String?,
    profileImageUrl: row['profile_image_url'] as String?,
    bio: row['bio'] as String?,
    locationLat: (row['location_lat'] as num?)?.toDouble(),
    locationLng: (row['location_lng'] as num?)?.toDouble(),
    isAvailable: row['is_available'] as bool,
    role: row['role'] as String,
    averageRating: (row['average_rating'] as num?)?.toDouble(),
    totalRatings: row['total_ratings'] as int?,
    createdAt: row['created_at'] as DateTime,
    updatedAt: row['updated_at'] as DateTime,
    salt: row['salt'] as String?,
    fcmToken: row['fcm_token'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'full_name': fullName,
    'profile_image_url': profileImageUrl,
    'bio': bio,
    'location_lat': locationLat,
    'location_lng': locationLng,
    'is_available': isAvailable,
    'role': role,
    'average_rating': averageRating,
    'total_ratings': totalRatings,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'salt': salt,
    'fcm_token': fcmToken, // ✅ snake_case in JSON
  };

  User copyWith({
    int? id,
    String? username,
    String? email,
    String? fullName,
    String? profileImageUrl,
    String? bio,
    double? locationLat,
    double? locationLng,
    bool? isAvailable,
    String? role,
    double? averageRating,
    int? totalRatings,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? salt,
    String? fcmToken,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      isAvailable: isAvailable ?? this.isAvailable,
      role: role ?? this.role,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      salt: salt ?? this.salt,
      fcmToken: fcmToken ?? this.fcmToken, // ✅ fixed
    );
  }
}
