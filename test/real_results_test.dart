import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:volleybet/models/bet_model.dart';
import 'package:volleybet/models/match_model.dart';
import 'package:volleybet/providers/betting_provider.dart';
import 'package:volleybet/screens/matches/match_detail_screen.dart';
import 'package:volleybet/services/sports_api_service.dart';
import 'package:volleybet/theme/app_theme.dart';

import 'betting_test.dart' show FakeBettingRepository;

MatchModel _match({
  String id = '214958',
  String status = 'NS',
  int? homeSets,
  int? awaySets,
}) {
  return MatchModel(
    id: id,
    tournament: 'Superliga',
    homeTeam: 'Brasil',
    awayTeam: 'Polonia',
    homeOdds: 1.75,
    awayOdds: 2.10,
    matchDate: DateTime(2026, 10, 25, 18),
    status: status,
    scores: homeSets == null ? null : MatchScores(home: homeSets, away: awaySets),
    sourceProvider: 'api-sports',
  );
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('MatchModel: estado para apostar y ganador real', () {
    test('Solo los partidos por jugar admiten apuestas', () {
      expect(_match(status: 'NS').isUpcoming, isTrue);
      expect(_match(status: 'S2').isUpcoming, isFalse);
      expect(_match(status: 'FT').isUpcoming, isFalse);
      expect(_match(status: 'CANC').isCancelled, isTrue);
    });

    test('winnerTeam usa los sets del marcador final', () {
      expect(_match(status: 'FT', homeSets: 3, awaySets: 1).winnerTeam, 'Brasil');
      expect(_match(status: 'FT', homeSets: 2, awaySets: 3).winnerTeam, 'Polonia');
      expect(_match(status: 'S3', homeSets: 2, awaySets: 0).winnerTeam, isNull);
      expect(_match(status: 'FT').winnerTeam, isNull);
    });
  });

  group('BettingProvider: liquidación con resultados reales (opción A)', () {
    late FakeBettingRepository repo;
    late Map<String, MatchModel?> results;
    late List<String> lookups;
    late BettingProvider provider;

    setUp(() async {
      repo = FakeBettingRepository(balance: 1000);
      results = {};
      lookups = [];
      provider = BettingProvider(
        repository: repo,
        resultLookup: (id) async {
          lookups.add(id);
          return results[id];
        },
      );
      await provider.loadUserData();
    });

    test('Partido terminado: acertar paga monto * cuota y fallar no paga', () async {
      await provider.placeBet(match: _match(), selectedTeam: 'Brasil', amount: 100);
      await provider.placeBet(match: _match(), selectedTeam: 'Polonia', amount: 200);
      expect(provider.pointsBalance, 700);

      results['214958'] = _match(status: 'FT', homeSets: 3, awaySets: 1);
      final settled = await provider.settleWithRealResults();

      expect(settled, hasLength(2));
      expect(lookups, ['214958'], reason: 'una consulta por partido, no por apuesta');
      final won = provider.bets.firstWhere((b) => b.selectedTeam == 'Brasil');
      final lost = provider.bets.firstWhere((b) => b.selectedTeam == 'Polonia');
      expect(won.status, BetStatus.won);
      expect(won.pointsWon, 175);
      expect(lost.status, BetStatus.lost);
      expect(lost.pointsWon, 0);
      expect(provider.pointsBalance, 875);
      expect(repo.balance, 875);
      expect(provider.activeBets, isEmpty);
    });

    test('Partido en curso o sin marcador: la apuesta sigue pendiente', () async {
      await provider.placeBet(match: _match(), selectedTeam: 'Brasil', amount: 100);
      results['214958'] = _match(status: 'S2', homeSets: 1, awaySets: 0);

      expect(await provider.settleWithRealResults(), isEmpty);
      expect(provider.activeBets, hasLength(1));
      expect(provider.pointsBalance, 900);
    });

    test('Partido cancelado: se anula la apuesta y se devuelve lo apostado', () async {
      await provider.placeBet(match: _match(), selectedTeam: 'Brasil', amount: 300);
      results['214958'] = _match(status: 'CANC');

      await provider.settleWithRealResults();
      expect(provider.bets.single.status, BetStatus.cancelled);
      expect(provider.pointsBalance, 1000);
      expect(repo.balance, 1000);
    });

    test('No vuelve a consultar el mismo partido antes de 15 minutos', () async {
      await provider.placeBet(match: _match(), selectedTeam: 'Brasil', amount: 100);
      await provider.settleWithRealResults();
      await provider.settleWithRealResults();
      expect(lookups, ['214958']);
    });

    test('Los partidos simulados (modo demo) no se consultan a la API', () async {
      final bet = await provider.placeBet(match: _match(), selectedTeam: 'Brasil', amount: 100);
      await provider.simulateFromBet(bet);
      lookups.clear();

      await provider.settleWithRealResults();
      expect(lookups, isEmpty);
    });

    test('Un fallo de la API no liquida ni rompe la carga', () async {
      final failing = BettingProvider(
        repository: repo,
        resultLookup: (_) async => throw Exception('Quota exceeded'),
      );
      await failing.loadUserData();
      await failing.placeBet(match: _match(), selectedTeam: 'Brasil', amount: 50);
      expect(await failing.settleWithRealResults(), isEmpty);
      expect(failing.activeBets, hasLength(1));
      expect(failing.errorMessage, isNull);
    });

    test('loadUserData liquida automáticamente al abrir la app', () async {
      await provider.placeBet(match: _match(), selectedTeam: 'Polonia', amount: 100);
      results['214958'] = _match(status: 'FT', homeSets: 1, awaySets: 3);

      final reopened = BettingProvider(
        repository: repo,
        resultLookup: (id) async => results[id],
      );
      await reopened.loadUserData();
      expect(reopened.bets.single.status, BetStatus.won);
      expect(reopened.pointsBalance, 900 + 210);
    });

    test('Apostar en un partido en vivo o terminado se rechaza', () async {
      expect(
        () => provider.placeBet(match: _match(status: 'S1'), selectedTeam: 'Brasil', amount: 10),
        throwsA(isA<StateError>()),
      );
      expect(repo.rows, isEmpty);
    });
  });

  group('SportsApiService.getMatchResult', () {
    test('Consulta /games?id= en API-Sports y no repite partidos finalizados', () async {
      final requested = <Uri>[];
      final dio = Dio()
        ..httpClientAdapter = _JsonAdapter((options) {
          requested.add(options.uri);
          return '{"errors":[],"response":[{"id":214958,"status":{"short":"FT"},'
              '"league":{"name":"Superliga"},'
              '"teams":{"home":{"name":"Brasil"},"away":{"name":"Polonia"}},'
              '"scores":{"home":3,"away":1}}]}';
        });
      final service = SportsApiService(dio: dio, overrideApiSportsKey: 'test-key');

      final first = await service.getMatchResult('214958');
      final second = await service.getMatchResult('214958');

      expect(first!.winnerTeam, 'Brasil');
      expect(second!.isFinished, isTrue);
      expect(requested, hasLength(1));
      expect(requested.single.path, '/games');
      expect(requested.single.queryParameters['id'], '214958');
    });
  });

  testWidgets('MatchDetailScreen cierra las apuestas cuando el partido está en vivo',
      (tester) async {
    final provider = BettingProvider(
      repository: FakeBettingRepository(balance: 1000),
      resultLookup: (_) async => null,
    );
    await tester.runAsync(provider.loadUserData);

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: MatchDetailScreen(match: _match(status: 'S1'), initialSelectedTeam: 'Brasil'),
      ),
    ));

    expect(find.text('Las apuestas se cierran al comenzar el partido.'), findsOneWidget);
    expect(find.byKey(const Key('bet-amount-field')), findsNothing);
  });
}

class _JsonAdapter implements HttpClientAdapter {
  final String Function(RequestOptions options) body;
  _JsonAdapter(this.body);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(body(options), 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}
