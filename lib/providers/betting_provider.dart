import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bet_model.dart';
import '../models/match_model.dart';
import '../models/user_profile.dart';
import '../services/betting_repository.dart';
import '../services/simulation_service.dart';
import '../services/sports_api_service.dart';
import '../services/supabase_service.dart';

/// Consulta el estado y marcador real de un partido por su id.
typedef MatchResultLookup = Future<MatchModel?> Function(String matchId);

/// Resumen de una simulación con la liquidación de las apuestas del partido.
class SimulationOutcome {
  final SimulationResult result;
  final List<BetModel> settledBets;
  final bool sniperUnlocked;

  const SimulationOutcome({
    required this.result,
    required this.settledBets,
    required this.sniperUnlocked,
  });

  int get totalWon => settledBets.fold(0, (sum, b) => sum + b.pointsWon);
  int get wonCount => settledBets.where((b) => b.status == BetStatus.won).length;
  int get lostCount => settledBets.where((b) => b.status == BetStatus.lost).length;
}

/// Estado global de apuestas, saldo y simulación (HU-04 / Requisito 7).
/// Toda pantalla que muestre el saldo lo lee con `context.watch<BettingProvider>()`
/// o `Consumer<BettingProvider>`, y se redibuja con cada `notifyListeners()`.
class BettingProvider extends ChangeNotifier {
  static const String juniorBadge = 'Experto Junior en Voleibol';
  static const String sniperBadge = 'Francotirador';
  static const String leaderBadge = 'Líder';
  static const int sniperStreakTarget = 3;
  static const int defaultBalance = 1000;

  /// Tope de partidos consultados a la API por actualización y espera mínima
  /// antes de volver a consultar el mismo partido (cuota gratuita: 100/día).
  static const int maxResultLookupsPerRefresh = 10;
  static const Duration resultRecheckInterval = Duration(minutes: 15);

  final BettingRepository _repository;
  final SimulationService _simulationService;
  final MatchResultLookup _resultLookup;

  BettingProvider({
    BettingRepository? repository,
    SimulationService? simulationService,
    MatchResultLookup? resultLookup,
  })  : _repository = repository ?? SupabaseService.instance,
        _simulationService = simulationService ?? SimulationService(),
        _resultLookup =
            resultLookup ?? ((id) => SportsApiService.instance.getMatchResult(id));

  String? _userId;
  String? _username;
  int _pointsBalance = defaultBalance;
  List<String> _badges = const [];
  List<BetModel> _bets = const [];
  int _streakCount = 0;
  bool _isLoading = false;
  bool _isSimulating = false;
  String? _errorMessage;
  final Map<String, SimulationResult> _simulatedMatches = {};
  final Map<String, DateTime> _lastResultCheck = {};
  bool _isSettlingResults = false;

  String? get username => _username;
  int get pointsBalance => _pointsBalance;
  List<String> get badges => _badges;
  List<BetModel> get bets => _bets;
  int get streakCount => _streakCount;
  bool get isLoading => _isLoading;
  bool get isSimulating => _isSimulating;
  String? get errorMessage => _errorMessage;
  bool get hasSniperBadge => _badges.contains(sniperBadge);
  bool get hasLeaderBadge => _badges.contains(leaderBadge);

  List<BetModel> get activeBets => _bets.where((b) => b.isPending).toList();
  List<BetModel> get settledBets => _bets.where((b) => !b.isPending).toList();

  List<BetModel> betsForMatch(String matchId) =>
      _bets.where((b) => b.matchId == matchId).toList();

  List<BetModel> pendingBetsForMatch(String matchId) =>
      _bets.where((b) => b.matchId == matchId && b.isPending).toList();

  SimulationResult? simulationFor(String matchId) => _simulatedMatches[matchId];

  /// Carga perfil (saldo e insignias) e historial de apuestas del usuario actual.
  Future<void> loadUserData() async {
    final userId = _repository.currentUserId;
    if (userId == null) {
      reset();
      return;
    }
    if (userId != _userId) {
      _simulatedMatches.clear();
      _lastResultCheck.clear();
    }
    _userId = userId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final profile = await _repository.getUserProfile(userId);
      if (profile != null) {
        _username = profile.username;
        _pointsBalance = profile.pointsBalance;
        _badges = List.unmodifiable(profile.badges);
      }
      _bets = List.unmodifiable(await _repository.getUserBets());
      _streakCount = SimulationService.currentStreak(_bets);
    } catch (e) {
      _errorMessage = describeError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    if (_errorMessage == null) {
      await settleWithRealResults();
    }
  }

  /// Liquida las apuestas pendientes de partidos reales ya terminados:
  /// acertar el ganador paga monto * cuota (WON) y fallar no paga (LOST).
  /// Un partido cancelado devuelve lo apostado. Consulta una vez por partido,
  /// como máximo cada [resultRecheckInterval], y omite los partidos simulados.
  Future<List<BetModel>> settleWithRealResults() async {
    if (_isSettlingResults || _userId == null) return const [];

    final now = DateTime.now();
    final matchIds = activeBets
        .map((b) => b.matchId)
        .toSet()
        .where((id) => !_simulatedMatches.containsKey(id))
        .where((id) {
          final last = _lastResultCheck[id];
          return last == null || now.difference(last) >= resultRecheckInterval;
        })
        .take(maxResultLookupsPerRefresh)
        .toList();
    if (matchIds.isEmpty) return const [];

    _isSettlingResults = true;
    final settled = <BetModel>[];
    try {
      for (final matchId in matchIds) {
        _lastResultCheck[matchId] = now;
        final MatchModel? result;
        try {
          result = await _resultLookup(matchId);
        } catch (e) {
          debugPrint('⚠️ [BettingProvider] Sin resultado para $matchId: $e');
          continue;
        }
        if (result == null) continue;

        if (result.isCancelled) {
          for (final bet in pendingBetsForMatch(matchId)) {
            final voided = await _repository.voidBet(bet.id);
            settled.add(voided);
            _replaceBet(voided);
            _pointsBalance += bet.pointsStaked;
          }
          continue;
        }

        final winner = result.winnerTeam;
        if (winner == null) continue;
        for (final bet in pendingBetsForMatch(matchId)) {
          // Si el nombre del equipo no coincide con la API, no se adivina el resultado.
          if (bet.selectedTeam != result.homeTeam && bet.selectedTeam != result.awayTeam) {
            continue;
          }
          final updated = await _repository.settleBet(
            betId: bet.id,
            won: bet.selectedTeam == winner,
          );
          settled.add(updated);
          _replaceBet(updated);
          _pointsBalance += updated.pointsWon;
        }
      }

      if (settled.isNotEmpty) {
        _streakCount = SimulationService.currentStreak(_bets);
        await _unlockSniperIfEarned();
      }
    } catch (e) {
      _errorMessage = describeError(e);
    } finally {
      _isSettlingResults = false;
      if (settled.isNotEmpty || _errorMessage != null) notifyListeners();
    }
    return settled;
  }

  /// Limpia el estado al cerrar sesión.
  void reset() {
    _userId = null;
    _username = null;
    _pointsBalance = defaultBalance;
    _badges = const [];
    _bets = const [];
    _streakCount = 0;
    _isLoading = false;
    _isSimulating = false;
    _errorMessage = null;
    _simulatedMatches.clear();
    _lastResultCheck.clear();
    notifyListeners();
  }

  /// CREATE — Coloca una apuesta y descuenta el saldo en memoria.
  Future<BetModel> placeBet({
    required MatchModel match,
    required String selectedTeam,
    required int amount,
  }) async {
    final userId = _requireUser();
    if (!match.isUpcoming) {
      throw StateError('Solo se puede apostar en partidos por jugar');
    }
    _ensureAffordable(amount);
    final odds = selectedTeam == match.homeTeam ? match.homeOdds : match.awayOdds;

    final created = await _repository.createBet(
      BetModel(
        id: '',
        userId: userId,
        matchId: match.id,
        selectedTeam: selectedTeam,
        homeTeam: match.homeTeam,
        awayTeam: match.awayTeam,
        odds: odds,
        pointsStaked: amount,
      ),
    );

    _bets = List.unmodifiable([created, ..._bets]);
    _pointsBalance -= created.pointsStaked;
    notifyListeners();
    return created;
  }

  /// UPDATE — Cambia el monto de una apuesta pendiente y ajusta la diferencia.
  Future<BetModel> updateBetAmount(BetModel bet, int newAmount) async {
    _requireUser();
    if (!bet.isPending) {
      throw StateError('Solo se pueden modificar apuestas pendientes');
    }
    _ensureAffordable(newAmount - bet.pointsStaked);

    final updated = await _repository.updateBetAmount(
      betId: bet.id,
      amount: newAmount,
    );
    _replaceBet(updated);
    _pointsBalance -= updated.pointsStaked - bet.pointsStaked;
    notifyListeners();
    return updated;
  }

  /// DELETE — Cancela una apuesta pendiente y devuelve el monto íntegro.
  Future<void> cancelBet(BetModel bet) async {
    _requireUser();
    if (!bet.isPending) {
      throw StateError('Solo se pueden cancelar apuestas pendientes');
    }
    await _repository.cancelBet(bet.id);
    _bets = List.unmodifiable(_bets.where((b) => b.id != bet.id));
    _pointsBalance += bet.pointsStaked;
    notifyListeners();
  }

  /// Simula el partido, lo marca FINISHED y liquida las apuestas pendientes:
  /// WON suma monto * cuota al saldo; LOST no paga. Con 3 aciertos
  /// consecutivos desbloquea la insignia "Francotirador".
  Future<SimulationOutcome> simulateMatch({
    required String matchId,
    required String homeTeam,
    required String awayTeam,
    required double homeOdds,
    required double awayOdds,
  }) async {
    if (_isSimulating) {
      throw StateError('Ya hay una simulación en curso');
    }
    _isSimulating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = _simulationService.simulateMatch(
        matchId: matchId,
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        homeOdds: homeOdds,
        awayOdds: awayOdds,
      );

      final settled = <BetModel>[];
      for (final bet in pendingBetsForMatch(matchId)) {
        final updated = await _repository.settleBet(
          betId: bet.id,
          won: bet.selectedTeam == result.winner,
        );
        settled.add(updated);
        _replaceBet(updated);
        _pointsBalance += updated.pointsWon;
      }

      _simulatedMatches[matchId] = result;
      _streakCount = SimulationService.currentStreak(_bets);

      final sniperUnlocked = await _unlockSniperIfEarned();

      return SimulationOutcome(
        result: result,
        settledBets: settled,
        sniperUnlocked: sniperUnlocked,
      );
    } catch (e) {
      _errorMessage = describeError(e);
      rethrow;
    } finally {
      _isSimulating = false;
      notifyListeners();
    }
  }

  /// Desbloquea "Líder" cuando el usuario autenticado ocupa el primer lugar.
  /// Recibe el ranking ya ordenado por puntos y persiste la insignia una sola vez.
  Future<bool> unlockLeaderBadgeIfRankingLeader(
    List<UserProfile> ranking,
  ) async {
    final userId = _userId ?? _repository.currentUserId;
    if (userId == null || ranking.isEmpty || ranking.first.id != userId) {
      return false;
    }

    _userId = userId;
    final mergedBadges = <String>{...ranking.first.badges, ..._badges};

    if (mergedBadges.contains(leaderBadge)) {
      if (!hasLeaderBadge) {
        _badges = List.unmodifiable(mergedBadges);
        notifyListeners();
      }
      return false;
    }

    mergedBadges.add(leaderBadge);
    final newBadges = List<String>.unmodifiable(mergedBadges);
    await _repository.updateBadges(userId: userId, badges: newBadges);
    _badges = newBadges;
    notifyListeners();
    return true;
  }

  /// Simula a partir de una apuesta del historial (sin el MatchModel cargado).
  Future<SimulationOutcome> simulateFromBet(BetModel bet) {
    final home = bet.homeTeam ?? bet.selectedTeam;
    final away = bet.awayTeam ?? bet.opponentTeam ?? 'Rival';
    double? knownOdds(String team) => betsForMatch(bet.matchId)
        .where((b) => b.selectedTeam == team)
        .map((b) => b.odds)
        .firstOrNull;
    final homeOdds = knownOdds(home) ?? _complementOdds(knownOdds(away) ?? bet.odds);
    final awayOdds = knownOdds(away) ?? _complementOdds(homeOdds);
    return simulateMatch(
      matchId: bet.matchId,
      homeTeam: home,
      awayTeam: away,
      homeOdds: homeOdds,
      awayOdds: awayOdds,
    );
  }

  /// Cuota aproximada del rival cuando solo se conoce la de un equipo
  /// (mismo margen del 8% que usa `MatchModel.generateDeterministicOdds`).
  static double _complementOdds(double odds) {
    final implied = (1.08 - 1 / odds).clamp(0.05, 0.95);
    return 1 / implied;
  }

  /// Traduce errores de Supabase/PostgREST a un mensaje legible.
  static String describeError(Object error) {
    if (error is PostgrestException) return error.message;
    if (error is AuthException) return error.message;
    if (error is StateError) return error.message;
    return error.toString().replaceFirst('Exception: ', '');
  }

  /// Desbloquea "Francotirador" con 3 aciertos consecutivos (una sola vez).
  Future<bool> _unlockSniperIfEarned() async {
    final userId = _userId;
    if (_streakCount < sniperStreakTarget || hasSniperBadge || userId == null) {
      return false;
    }
    final newBadges = [..._badges, sniperBadge];
    await _repository.updateBadges(userId: userId, badges: newBadges);
    _badges = List.unmodifiable(newBadges);
    return true;
  }

  String _requireUser() {
    final userId = _userId ?? _repository.currentUserId;
    if (userId == null) {
      throw StateError('Debes iniciar sesión para apostar');
    }
    _userId = userId;
    return userId;
  }

  void _ensureAffordable(int extraPoints) {
    if (extraPoints > _pointsBalance) {
      throw StateError('Saldo insuficiente (disponibles: $_pointsBalance pts)');
    }
  }

  void _replaceBet(BetModel updated) {
    _bets = List.unmodifiable(
      _bets.map((b) => b.id == updated.id ? updated : b),
    );
  }
}
