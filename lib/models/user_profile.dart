/// Modelo para representar el perfil de usuario en VolleyBet.
class UserProfile {
  final String id;
  final String username;
  final int pointsBalance;
  final List<String> badges;
  final int triviaPointsEarned;
  final int triviaPointsCapacity;
  final DateTime? updatedAt;

  UserProfile({
    required this.id,
    required this.username,
    required this.pointsBalance,
    this.badges = const [],
    this.triviaPointsEarned = 0,
    this.triviaPointsCapacity = 1000,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? 'Usuario',
      pointsBalance: (json['points_balance'] as num?)?.toInt() ?? 1000,
      badges:
          (json['badges'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      triviaPointsEarned: (json['trivia_points_earned'] as num?)?.toInt() ?? 0,
      triviaPointsCapacity:
          (json['trivia_points_capacity'] as num?)?.toInt() ?? 1000,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'points_balance': pointsBalance,
      'badges': badges,
      'trivia_points_earned': triviaPointsEarned,
      'trivia_points_capacity': triviaPointsCapacity,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? username,
    int? pointsBalance,
    List<String>? badges,
    int? triviaPointsEarned,
    int? triviaPointsCapacity,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      pointsBalance: pointsBalance ?? this.pointsBalance,
      badges: badges ?? this.badges,
      triviaPointsEarned: triviaPointsEarned ?? this.triviaPointsEarned,
      triviaPointsCapacity: triviaPointsCapacity ?? this.triviaPointsCapacity,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
