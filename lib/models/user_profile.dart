/// Modelo para representar el perfil de usuario en VolleyBet.
class UserProfile {
  final String id;
  final String username;
  final int pointsBalance;
  final List<String> badges;
  final DateTime? updatedAt;

  UserProfile({
    required this.id,
    required this.username,
    required this.pointsBalance,
    this.badges = const [],
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? 'Usuario',
      pointsBalance: (json['points_balance'] as num?)?.toInt() ?? 1000,
      badges: (json['badges'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
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
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? username,
    int? pointsBalance,
    List<String>? badges,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      pointsBalance: pointsBalance ?? this.pointsBalance,
      badges: badges ?? this.badges,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
