import 'dart:math';
import '../models/bet_model.dart';

/// Marcador de un set de voleibol.
class SetScore {
  final int home;
  final int away;

  const SetScore(this.home, this.away);

  bool get homeWon => home > away;

  @override
  String toString() => '$home-$away';
}

/// Resultado final de un partido simulado (HU-04 / CAP-4).
class SimulationResult {
  final String matchId;
  final String homeTeam;
  final String awayTeam;
  final List<SetScore> sets;

  const SimulationResult({
    required this.matchId,
    required this.homeTeam,
    required this.awayTeam,
    required this.sets,
  });

  int get homeSets => sets.where((s) => s.homeWon).length;
  int get awaySets => sets.length - homeSets;
  bool get homeWins => homeSets > awaySets;
  String get winner => homeWins ? homeTeam : awayTeam;
  String get loser => homeWins ? awayTeam : homeTeam;

  /// Estado que adopta el partido tras la simulación.
  String get status => 'FINISHED';

  /// Marcador en sets, por ejemplo "3-1".
  String get scoreLabel => '$homeSets-$awaySets';
}

/// Motor de simulación acelerada de partidos de voleibol (HU-04).
/// Genera marcadores creíbles (al mejor de 5 sets, sets a 25 y quinto set a 15,
/// diferencia mínima de 2 puntos) ponderando al favorito según las cuotas.
class SimulationService {
  final Random _random;

  SimulationService({Random? random}) : _random = random ?? Random();

  /// Probabilidad de que gane el local, normalizando las probabilidades
  /// implícitas de ambas cuotas para eliminar el margen de la casa.
  static double homeWinProbability(double homeOdds, double awayOdds) {
    if (homeOdds <= 0 || awayOdds <= 0) return 0.5;
    final home = 1 / homeOdds;
    final away = 1 / awayOdds;
    return home / (home + away);
  }

  /// Premio de una apuesta ganadora: monto * cuota (redondeado a puntos enteros).
  static int calculatePayout(int pointsStaked, double odds) =>
      (pointsStaked * odds).round();

  /// Aciertos consecutivos más recientes entre las apuestas liquidadas.
  static int currentStreak(Iterable<BetModel> bets) {
    final settled = bets
        .where((b) => b.status == BetStatus.won || b.status == BetStatus.lost)
        .toList()
      ..sort((a, b) {
        final aDate = a.settledAt ?? a.createdAt ?? DateTime(0);
        final bDate = b.settledAt ?? b.createdAt ?? DateTime(0);
        return bDate.compareTo(aDate);
      });

    var streak = 0;
    for (final bet in settled) {
      if (bet.status != BetStatus.won) break;
      streak++;
    }
    return streak;
  }

  SimulationResult simulateMatch({
    required String matchId,
    required String homeTeam,
    required String awayTeam,
    required double homeOdds,
    required double awayOdds,
  }) {
    final homeProbability = homeWinProbability(homeOdds, awayOdds);
    final sets = <SetScore>[];
    var homeSets = 0;
    var awaySets = 0;

    while (homeSets < 3 && awaySets < 3) {
      final isTieBreak = sets.length == 4;
      final homeWinsSet = _random.nextDouble() < homeProbability;
      final (winnerPoints, loserPoints) = _simulateSetPoints(isTieBreak);
      if (homeWinsSet) {
        sets.add(SetScore(winnerPoints, loserPoints));
        homeSets++;
      } else {
        sets.add(SetScore(loserPoints, winnerPoints));
        awaySets++;
      }
    }

    return SimulationResult(
      matchId: matchId,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      sets: List.unmodifiable(sets),
    );
  }

  /// Puntos (ganador, perdedor) de un set: 25 puntos (15 en el quinto) o
  /// alargue con diferencia de 2 cuando el set llega igualado.
  (int, int) _simulateSetPoints(bool isTieBreak) {
    final target = isTieBreak ? 15 : 25;
    final goesToDeuce = _random.nextDouble() < 0.2;
    if (goesToDeuce) {
      final loser = target - 1 + _random.nextInt(4);
      return (loser + 2, loser);
    }
    final minLoser = isTieBreak ? 8 : 15;
    final loser = minLoser + _random.nextInt(target - 1 - minLoser);
    return (target, loser);
  }
}
