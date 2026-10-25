class TriviaRewardResult {
  final int correctAnswers;
  final int calculatedPoints;
  final int pointsAwarded;
  final int pointsBalance;
  final int triviaPointsEarned;
  final int triviaPointsCapacity;
  final bool capacityReached;
  final List<String> badges;

  const TriviaRewardResult({
    required this.correctAnswers,
    required this.calculatedPoints,
    required this.pointsAwarded,
    required this.pointsBalance,
    required this.triviaPointsEarned,
    required this.triviaPointsCapacity,
    required this.capacityReached,
    required this.badges,
  });

  factory TriviaRewardResult.fromJson(Map<String, dynamic> json) {
    return TriviaRewardResult(
      correctAnswers: (json['correct_answers'] as num?)?.toInt() ?? 0,
      calculatedPoints: (json['calculated_points'] as num?)?.toInt() ?? 0,
      pointsAwarded: (json['points_awarded'] as num?)?.toInt() ?? 0,
      pointsBalance: (json['points_balance'] as num?)?.toInt() ?? 0,
      triviaPointsEarned: (json['trivia_points_earned'] as num?)?.toInt() ?? 0,
      triviaPointsCapacity:
          (json['trivia_points_capacity'] as num?)?.toInt() ?? 1000,
      capacityReached: json['capacity_reached'] == true,
      badges:
          (json['badges'] as List<dynamic>?)
              ?.map((badge) => badge.toString())
              .toList() ??
          const [],
    );
  }
}
