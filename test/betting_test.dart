import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:volleybet/models/bet_model.dart';
import 'package:volleybet/models/match_model.dart';
import 'package:volleybet/models/user_profile.dart';
import 'package:volleybet/providers/betting_provider.dart';
import 'package:volleybet/screens/bets/bet_history_screen.dart';
import 'package:volleybet/screens/matches/match_detail_screen.dart';
import 'package:volleybet/services/betting_repository.dart';
import 'package:volleybet/services/simulation_service.dart';
import 'package:volleybet/theme/app_theme.dart';
import 'package:volleybet/widgets/bet_form.dart';
import 'package:volleybet/widgets/odds_button.dart';
import 'package:volleybet/widgets/points_badge.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final match = MatchModel(
    id: 'm-1',
    tournament: 'Liga Mundial',
    homeTeam: 'Brasil',
    awayTeam: 'Polonia',
    homeOdds: 1.75,
    awayOdds: 2.10,
    matchDate: DateTime(2026, 10, 23, 18),
    status: 'NS',
    sourceProvider: 'mock-local',
  );

  // ===========================================================================
  // HU-03: Formulario con validación y CRUD de apuestas
  // ===========================================================================

  group('HU-03: BetForm validación (Requisito 6)', () {
    test('validateAmount devuelve los mensajes exigidos por el criterio 3.1', () {
      expect(BetForm.validateAmount('', 500), 'Ingresa un monto');
      expect(BetForm.validateAmount(null, 500), 'Ingresa un monto');
      expect(BetForm.validateAmount('0', 500), 'El monto mínimo es 1 punto');
      expect(BetForm.validateAmount('-5', 500), 'El monto mínimo es 1 punto');
      expect(BetForm.validateAmount('501', 500),
          'Saldo insuficiente (disponibles: 500 pts)');
      expect(BetForm.validateAmount('500', 500), isNull);
      expect(BetForm.validateAmount('1', 500), isNull);
    });

    testWidgets('BetForm bloquea envíos inválidos y solo envía tras validate() == true',
        (tester) async {
      final submitted = <int>[];
      await tester.pumpWidget(_app(
        Scaffold(
          body: BetForm(
            availableBalance: 1000,
            odds: 1.75,
            onSubmit: (amount) async => submitted.add(amount),
          ),
        ),
      ));

      await tester.tap(find.text('CONFIRMAR APUESTA'));
      await tester.pump();
      expect(find.text('Ingresa un monto'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('bet-amount-field')), '0');
      await tester.pump();
      expect(find.text('El monto mínimo es 1 punto'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('bet-amount-field')), '1500');
      await tester.pump();
      expect(find.text('Saldo insuficiente (disponibles: 1000 pts)'), findsOneWidget);
      await tester.tap(find.text('CONFIRMAR APUESTA'));
      await tester.pump();
      expect(submitted, isEmpty);

      await tester.enterText(find.byKey(const Key('bet-amount-field')), '200');
      await tester.pump();
      expect(find.textContaining('Premio potencial: 350 pts'), findsOneWidget);
      await tester.tap(find.text('CONFIRMAR APUESTA'));
      await tester.pump();
      expect(submitted, [200]);
    });
  });

  group('HU-03: BetModel', () {
    test('BetModel deserializa filas de Supabase y serializa el insert', () {
      final bet = BetModel.fromJson({
        'id': 'b1',
        'user_id': 'u1',
        'match_id': '214958',
        'selected_team': 'Brasil',
        'home_team': 'Brasil',
        'away_team': 'Polonia',
        'odds': 1.75,
        'points_staked': 100,
        'status': 'WON',
        'points_won': 175,
        'created_at': '2026-10-23T10:00:00Z',
      });
      expect(bet.status, BetStatus.won);
      expect(bet.pointsWon, 175);
      expect(bet.matchLabel, 'Brasil vs Polonia');
      expect(bet.opponentTeam, 'Polonia');

      final insert = bet.toInsertJson();
      expect(insert['user_id'], 'u1');
      expect(insert['status'], 'PENDING');
      expect(insert.containsKey('id'), isFalse);
    });

    test('BetModel acepta odds como texto (numeric de Postgres)', () {
      final bet = BetModel.fromJson({'odds': '2.10', 'points_staked': 50});
      expect(bet.odds, 2.10);
      expect(bet.potentialPayout, 105);
      expect(bet.status, BetStatus.pending);
    });
  });

  group('HU-03: CRUD de apuestas vía BettingProvider', () {
    late FakeBettingRepository repo;
    late BettingProvider provider;

    setUp(() async {
      repo = FakeBettingRepository(balance: 1000);
      provider = BettingProvider(repository: repo);
      await provider.loadUserData();
    });

    test('CREATE descuenta el saldo y agrega la apuesta PENDING', () async {
      final bet = await provider.placeBet(match: match, selectedTeam: 'Polonia', amount: 300);
      expect(bet.status, BetStatus.pending);
      expect(bet.odds, 2.10);
      expect(bet.userId, 'user-1');
      expect(provider.pointsBalance, 700);
      expect(repo.balance, 700);
      expect(provider.activeBets, hasLength(1));
    });

    test('CREATE con saldo insuficiente no llama a Supabase', () async {
      expect(
        () => provider.placeBet(match: match, selectedTeam: 'Brasil', amount: 5000),
        throwsA(isA<StateError>()),
      );
      expect(repo.rows, isEmpty);
      expect(provider.pointsBalance, 1000);
    });

    test('UPDATE ajusta el saldo con la diferencia del nuevo monto', () async {
      final bet = await provider.placeBet(match: match, selectedTeam: 'Brasil', amount: 300);
      await provider.updateBetAmount(bet, 500);
      expect(provider.pointsBalance, 500);
      expect(provider.activeBets.single.pointsStaked, 500);

      await provider.updateBetAmount(provider.activeBets.single, 100);
      expect(provider.pointsBalance, 900);
      expect(repo.balance, 900);
    });

    test('DELETE cancela la apuesta pendiente y devuelve el monto íntegro', () async {
      final bet = await provider.placeBet(match: match, selectedTeam: 'Brasil', amount: 250);
      await provider.cancelBet(bet);
      expect(provider.pointsBalance, 1000);
      expect(repo.balance, 1000);
      expect(provider.bets, isEmpty);
    });

    test('READ carga saldo, insignias e historial del usuario', () async {
      await provider.placeBet(match: match, selectedTeam: 'Brasil', amount: 100);
      final fresh = BettingProvider(repository: repo);
      await fresh.loadUserData();
      expect(fresh.pointsBalance, 900);
      expect(fresh.bets, hasLength(1));
      expect(fresh.username, 'Otue');
    });

    test('Sin sesión no se permite apostar', () async {
      repo.userId = null;
      final anon = BettingProvider(repository: repo);
      await anon.loadUserData();
      expect(
        () => anon.placeBet(match: match, selectedTeam: 'Brasil', amount: 10),
        throwsA(isA<StateError>()),
      );
    });
  });

  // ===========================================================================
  // HU-04: Provider y motor de simulación acelerada
  // ===========================================================================

  group('HU-04: SimulationService', () {
    test('Genera marcadores de voleibol válidos (mejor de 5, sets a 25 y 15)', () {
      for (var seed = 0; seed < 300; seed++) {
        final result = SimulationService(random: Random(seed)).simulateMatch(
          matchId: 'm',
          homeTeam: 'A',
          awayTeam: 'B',
          homeOdds: 1.6,
          awayOdds: 2.3,
        );
        expect(max(result.homeSets, result.awaySets), 3);
        expect(min(result.homeSets, result.awaySets), lessThan(3));
        expect(result.sets.length, inInclusiveRange(3, 5));
        for (var i = 0; i < result.sets.length; i++) {
          final set = result.sets[i];
          final target = i == 4 ? 15 : 25;
          final high = max(set.home, set.away);
          final low = min(set.home, set.away);
          expect(high, greaterThanOrEqualTo(target));
          expect(high - low, greaterThanOrEqualTo(2));
          if (high > target) expect(high - low, 2);
        }
        expect(result.winner, result.homeWins ? 'A' : 'B');
        expect(result.status, 'FINISHED');
      }
    });

    test('El favorito por cuota gana con más frecuencia', () {
      var favoriteWins = 0;
      final service = SimulationService(random: Random(42));
      for (var i = 0; i < 500; i++) {
        final r = service.simulateMatch(
          matchId: 'm', homeTeam: 'Fav', awayTeam: 'Dog', homeOdds: 1.3, awayOdds: 3.5,
        );
        if (r.winner == 'Fav') favoriteWins++;
      }
      expect(favoriteWins, greaterThan(350));
    });

    test('Probabilidad normalizada, premio monto * cuota y racha', () {
      expect(SimulationService.homeWinProbability(2.0, 2.0), closeTo(0.5, 1e-9));
      expect(SimulationService.calculatePayout(100, 1.75), 175);
      expect(SimulationService.calculatePayout(33, 2.10), 69);

      BetModel settled(BetStatus status, int minute) => BetModel(
            id: '$minute', userId: 'u', matchId: 'm$minute', selectedTeam: 'A',
            odds: 2, pointsStaked: 10, status: status,
            settledAt: DateTime(2026, 10, 23, 12, minute),
          );
      expect(
        SimulationService.currentStreak([
          settled(BetStatus.won, 1),
          settled(BetStatus.lost, 2),
          settled(BetStatus.won, 3),
          settled(BetStatus.won, 4),
        ]),
        2,
      );
    });
  });

  group('HU-04: BettingProvider liquidación y reactividad (Requisito 7)', () {
    test('Simular liquida WON con monto * cuota y LOST con 0, notificando cambios', () async {
      final repo = FakeBettingRepository(balance: 1000);
      final provider = BettingProvider(
        repository: repo,
        simulationService: SimulationService(random: FixedRandom(0.0)), // gana el local
      );
      await provider.loadUserData();
      await provider.placeBet(match: match, selectedTeam: 'Brasil', amount: 100);
      await provider.placeBet(match: match, selectedTeam: 'Polonia', amount: 200);
      expect(provider.pointsBalance, 700);

      var notifications = 0;
      provider.addListener(() => notifications++);

      final outcome = await provider.simulateMatch(
        matchId: match.id,
        homeTeam: match.homeTeam,
        awayTeam: match.awayTeam,
        homeOdds: match.homeOdds,
        awayOdds: match.awayOdds,
      );

      expect(outcome.result.winner, 'Brasil');
      expect(outcome.result.scoreLabel, '3-0');
      expect(outcome.wonCount, 1);
      expect(outcome.lostCount, 1);
      expect(outcome.totalWon, 175);
      expect(provider.pointsBalance, 875);
      expect(repo.balance, 875);
      expect(provider.activeBets, isEmpty);
      expect(provider.simulationFor(match.id), isNotNull);
      expect(provider.isSimulating, isFalse);
      expect(notifications, greaterThanOrEqualTo(2));
    });

    test('3 aciertos consecutivos desbloquean la insignia Francotirador', () async {
      final repo = FakeBettingRepository(balance: 1000);
      final provider = BettingProvider(
        repository: repo,
        simulationService: SimulationService(random: FixedRandom(0.0)),
      );
      await provider.loadUserData();

      SimulationOutcome? last;
      for (var i = 0; i < 3; i++) {
        final m = MatchModel(
          id: 'm-$i', tournament: 'T', homeTeam: 'Local $i', awayTeam: 'Visita $i',
          homeOdds: 1.5, awayOdds: 2.5, matchDate: DateTime(2026), status: 'NS',
          sourceProvider: 'mock-local',
        );
        await provider.placeBet(match: m, selectedTeam: m.homeTeam, amount: 10);
        last = await provider.simulateMatch(
          matchId: m.id, homeTeam: m.homeTeam, awayTeam: m.awayTeam,
          homeOdds: m.homeOdds, awayOdds: m.awayOdds,
        );
        if (i < 2) expect(last.sniperUnlocked, isFalse);
      }

      expect(provider.streakCount, 3);
      expect(last!.sniperUnlocked, isTrue);
      expect(provider.hasSniperBadge, isTrue);
      expect(repo.badges, contains(BettingProvider.sniperBadge));
    });

    test('simulateFromBet resuelve el partido desde el historial', () async {
      final repo = FakeBettingRepository(balance: 1000);
      final provider = BettingProvider(
        repository: repo,
        simulationService: SimulationService(random: FixedRandom(0.99)), // gana la visita
      );
      await provider.loadUserData();
      final bet = await provider.placeBet(match: match, selectedTeam: 'Polonia', amount: 100);

      final outcome = await provider.simulateFromBet(bet);
      expect(outcome.result.winner, 'Polonia');
      expect(provider.pointsBalance, 900 + 210);
    });

    testWidgets('PointsBadge se redibuja al apostar (context.watch)', (tester) async {
      final provider = BettingProvider(repository: FakeBettingRepository(balance: 1000));
      await tester.pumpWidget(_app(
        const Scaffold(body: Center(child: PointsBadge())),
        provider: provider,
      ));
      await tester.runAsync(provider.loadUserData);
      await tester.pump();
      expect(find.text('1000 PTS VIRTUALES'), findsOneWidget);

      await tester.runAsync(
        () => provider.placeBet(match: match, selectedTeam: 'Brasil', amount: 250),
      );
      await tester.pump();
      expect(find.text('750 PTS VIRTUALES'), findsOneWidget);
    });

    testWidgets('MatchDetailScreen: seleccionar cuota, apostar y ver saldo actualizado',
        (tester) async {
      final repo = FakeBettingRepository(balance: 1000);
      final provider = BettingProvider(repository: repo);
      await tester.runAsync(provider.loadUserData);

      await tester.pumpWidget(_app(MatchDetailScreen(match: match), provider: provider));
      expect(find.text('1000 PTS'), findsOneWidget);

      await tester.tap(find.widgetWithText(OddsButton, '1 (LOCAL)'));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('bet-amount-field')), '100');
      await tester.pump();

      final confirm = find.text('CONFIRMAR APUESTA');
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pump();
      await tester.pump();

      expect(repo.rows, hasLength(1));
      expect(find.text('900 PTS'), findsOneWidget);
      expect(find.textContaining('Brasil · 100 pts @ 1.75 · PENDIENTE'), findsOneWidget);
      expect(find.textContaining('Simular Partido (1 pendiente(s))'), findsOneWidget);
    });

    testWidgets('BetHistoryScreen: cancelar apuesta con diálogo devuelve el saldo',
        (tester) async {
      final repo = FakeBettingRepository(balance: 1000);
      final provider = BettingProvider(repository: repo);
      await tester.runAsync(() async {
        await provider.loadUserData();
        await provider.placeBet(match: match, selectedTeam: 'Brasil', amount: 400);
      });

      await tester.pumpWidget(_app(const BetHistoryScreen(), provider: provider));
      expect(find.text('PENDIENTES (1)'), findsOneWidget);
      expect(find.text('600 PTS'), findsOneWidget);

      await tester.tap(find.text('Cancelar Apuesta'));
      await tester.pumpAndSettle();
      expect(find.text('¿Cancelar apuesta?'), findsOneWidget);

      await tester.tap(find.text('Sí, cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('PENDIENTES (0)'), findsOneWidget);
      expect(find.text('1000 PTS'), findsOneWidget);
      expect(repo.rows, isEmpty);
    });
  });
}

Widget _app(Widget home, {BettingProvider? provider}) {
  return ChangeNotifierProvider<BettingProvider>(
    create: (_) => provider ?? BettingProvider(repository: FakeBettingRepository(balance: 1000)),
    child: MaterialApp(theme: AppTheme.darkTheme, home: home),
  );
}

/// Random determinista: el mismo valor en cada tirada.
class FixedRandom implements Random {
  final double value;
  FixedRandom(this.value);

  @override
  double nextDouble() => value;

  @override
  int nextInt(int max) => (value * max).floor().clamp(0, max - 1);

  @override
  bool nextBool() => value < 0.5;
}

/// Repositorio en memoria que replica las reglas del trigger `bets_apply_balance`.
class FakeBettingRepository implements BettingRepository {
  int balance;
  String? userId = 'user-1';
  List<String> badges = [];
  final Map<String, BetModel> rows = {};
  int _seq = 0;

  FakeBettingRepository({required this.balance});

  @override
  String? get currentUserId => userId;

  @override
  Future<UserProfile?> getUserProfile(String userId) async => UserProfile(
        id: userId,
        username: 'Otue',
        pointsBalance: balance,
        badges: List.of(badges),
      );

  @override
  Future<List<BetModel>> getUserBets() async =>
      rows.values.where((b) => b.userId == userId).toList();

  @override
  Future<BetModel> createBet(BetModel bet) async {
    if (bet.pointsStaked > balance) {
      throw Exception('Saldo insuficiente (disponibles: $balance pts)');
    }
    balance -= bet.pointsStaked;
    _seq++;
    final created = BetModel(
      id: 'bet-$_seq',
      userId: bet.userId,
      matchId: bet.matchId,
      selectedTeam: bet.selectedTeam,
      homeTeam: bet.homeTeam,
      awayTeam: bet.awayTeam,
      odds: bet.odds,
      pointsStaked: bet.pointsStaked,
      createdAt: DateTime(2026, 10, 23, 10, _seq),
    );
    rows[created.id] = created;
    return created;
  }

  @override
  Future<BetModel> updateBetAmount({required String betId, required int amount}) async {
    final bet = rows[betId]!;
    final delta = amount - bet.pointsStaked;
    if (delta > balance) throw Exception('Saldo insuficiente (disponibles: $balance pts)');
    balance -= delta;
    return rows[betId] = bet.copyWith(pointsStaked: amount);
  }

  @override
  Future<void> cancelBet(String betId) async {
    final bet = rows.remove(betId)!;
    balance += bet.pointsStaked;
  }

  @override
  Future<BetModel> settleBet({required String betId, required bool won}) async {
    final bet = rows[betId]!;
    final pointsWon = won ? SimulationService.calculatePayout(bet.pointsStaked, bet.odds) : 0;
    balance += pointsWon;
    _seq++;
    return rows[betId] = bet.copyWith(
      status: won ? BetStatus.won : BetStatus.lost,
      pointsWon: pointsWon,
      settledAt: DateTime(2026, 10, 23, 11, _seq),
    );
  }

  @override
  Future<void> updateBadges({required String userId, required List<String> badges}) async {
    this.badges = List.of(badges);
  }
}
