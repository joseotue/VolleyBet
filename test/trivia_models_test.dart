import 'package:flutter_test/flutter_test.dart';
import 'package:volleybet/models/trivia_reward_result.dart';
import 'package:volleybet/models/user_profile.dart';

void main() {
  group('HU-05: modelos de progreso de trivia', () {
    test('UserProfile convierte el progreso recibido desde Supabase', () {
      final profile = UserProfile.fromJson({
        'id': 'user-1',
        'username': 'Jesús',
        'points_balance': 1600,
        'badges': <String>[],
        'trivia_points_earned': 600,
        'trivia_points_capacity': 1000,
      });

      expect(profile.triviaPointsEarned, 600);
      expect(profile.triviaPointsCapacity, 1000);
      expect(profile.pointsBalance, 1600);
    });

    test('TriviaRewardResult conserva el premio limitado por Supabase', () {
      final result = TriviaRewardResult.fromJson({
        'correct_answers': 4,
        'calculated_points': 800,
        'points_awarded': 400,
        'points_balance': 2000,
        'trivia_points_earned': 1000,
        'trivia_points_capacity': 1000,
        'capacity_reached': true,
        'badges': <String>[],
      });

      expect(result.calculatedPoints, 800);
      expect(result.pointsAwarded, 400);
      expect(result.triviaPointsEarned, 1000);
      expect(result.capacityReached, isTrue);
    });

    test('los valores seguros se aplican cuando faltan campos opcionales', () {
      final profile = UserProfile.fromJson({
        'id': 'user-2',
        'username': 'Lucas',
        'points_balance': 1000,
      });

      expect(profile.triviaPointsEarned, 0);
      expect(profile.triviaPointsCapacity, 1000);
    });
  });
}
