import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:volleybet/models/match_model.dart';
import 'package:provider/provider.dart';
import 'package:volleybet/models/user_profile.dart';
import 'package:volleybet/providers/betting_provider.dart';
import 'package:volleybet/screens/auth/auth_gate.dart';
import 'package:volleybet/screens/auth/login_screen.dart';
import 'package:volleybet/screens/home/home_screen.dart';
import 'package:volleybet/screens/matches/match_detail_screen.dart';
import 'package:volleybet/screens/matches/matches_screen.dart';
import 'package:volleybet/services/sports_api_service.dart';
import 'package:volleybet/services/supabase_service.dart';
import 'package:volleybet/theme/app_theme.dart';
import 'package:volleybet/widgets/match_card.dart';
import 'package:volleybet/widgets/odds_button.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
    dotenv.loadFromString(
      envString: 'API_SPORTS_KEY=test-sports-key\nSPORTRADAR_API_KEY=test-sportradar-key',
    );
  });
  group('HU-01: Tema Anime Material 3 Tests', () {
    testWidgets('AppTheme usa Material 3 y paleta oficial VolleyBet', (tester) async {
      final theme = AppTheme.darkTheme;

      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, AppTheme.background);
      expect(theme.colorScheme.primary, AppTheme.primaryOrange);
      expect(theme.colorScheme.surface, AppTheme.surfaceColor);
    });
  });

  group('HU-01: UserProfile Model Tests', () {
    test('UserProfile serializa y deserializa correctamente desde JSON', () {
      final json = {
        'id': 'test-uuid-1234',
        'username': 'Lucas',
        'points_balance': 1500,
        'badges': ['Junior', 'Francotirador'],
        'updated_at': '2026-10-18T20:00:00.000Z',
      };

      final profile = UserProfile.fromJson(json);

      expect(profile.id, 'test-uuid-1234');
      expect(profile.username, 'Lucas');
      expect(profile.pointsBalance, 1500);
      expect(profile.badges, contains('Junior'));
      expect(profile.badges, contains('Francotirador'));
      expect(profile.updatedAt, isNotNull);

      final exported = profile.toJson();
      expect(exported['id'], 'test-uuid-1234');
      expect(exported['username'], 'Lucas');
      expect(exported['points_balance'], 1500);
    });

    test('UserProfile maneja valores por defecto si vienen nulos', () {
      final json = {
        'id': 'default-uuid',
      };

      final profile = UserProfile.fromJson(json);
      expect(profile.id, 'default-uuid');
      expect(profile.username, 'Usuario');
      expect(profile.pointsBalance, 1000);
      expect(profile.badges, isEmpty);
      expect(profile.updatedAt, isNull);
    });

    test('UserProfile convierte correctamente points_balance numérico o decimal a int sin error', () {
      final json = {
        'id': 'num-uuid',
        'points_balance': 2500.0,
      };

      final profile = UserProfile.fromJson(json);
      expect(profile.pointsBalance, 2500);
    });
  });

  group('HU-01: SupabaseService Configuration Tests', () {
    test('Perfiles sembrados de prueba incluyen a Lucas, Otue y Jesús', () {
      final profiles = SupabaseService.teamProfiles;

      expect(profiles.length, 3);
      final names = profiles.map((p) => p.name).toList();
      expect(names, contains('Lucas'));
      expect(names, contains('Otue'));
      expect(names, contains('Jesús'));

      final emails = profiles.map((p) => p.email).toList();
      expect(emails, contains('lucas@volleybet.udd'));
      expect(emails, contains('otue@volleybet.udd'));
      expect(emails, contains('jesus@volleybet.udd'));
    });
  });

  group('HU-01: LoginScreen Widget & Validation Tests', () {
    testWidgets('LoginScreen muestra título, formulario y accesos rápidos de equipo',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const LoginScreen(),
        ),
      );

      // Verificamos elementos clave de identidad y formulario
      expect(find.text('VOLLEYBET'), findsOneWidget);
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      expect(find.text('Correo electrónico'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
      expect(find.text('ENTRAR AL JUEGO'), findsOneWidget);

      // Verificamos los 3 perfiles de acceso rápido para la evaluación docente
      expect(find.text('Lucas'), findsOneWidget);
      expect(find.text('Otue'), findsOneWidget);
      expect(find.text('Jesús'), findsOneWidget);
    });

    testWidgets('LoginScreen valida campos vacíos al enviar formulario',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const LoginScreen(),
        ),
      );

      // Presionar el botón Entrar al juego sin llenar campos
      await tester.tap(find.text('ENTRAR AL JUEGO'));
      await tester.pump();

      // Debe mostrar mensajes de validación
      expect(
        find.text('Por favor ingresa tu correo electrónico'),
        findsOneWidget,
      );
      expect(
        find.text('Por favor ingresa tu contraseña'),
        findsOneWidget,
      );
    });

    testWidgets('LoginScreen valida formato inválido de correo',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const LoginScreen(),
        ),
      );

      // Ingresar email no válido y contraseña válida
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo electrónico'),
        'correo-invalido',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        'password123',
      );

      await tester.tap(find.text('ENTRAR AL JUEGO'));
      await tester.pump();

      expect(
        find.text('Ingresa un formato de correo válido'),
        findsOneWidget,
      );
    });

    testWidgets('LoginScreen valida contraseña menor a 6 caracteres',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const LoginScreen(),
        ),
      );

      // Ingresar email válido pero contraseña de 5 caracteres
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo electrónico'),
        'lucas@volleybet.udd',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        '12345',
      );

      await tester.tap(find.text('ENTRAR AL JUEGO'));
      await tester.pump();

      expect(
        find.text('La contraseña debe tener al menos 6 caracteres'),
        findsOneWidget,
      );
    });

    testWidgets('LoginScreen acepta formatos de correo con alias plus-addressing',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const LoginScreen(),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo electrónico'),
        'usuario+beta1@volleybet.udd',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        'password123',
      );

      await tester.tap(find.text('ENTRAR AL JUEGO'));
      await tester.pump();

      // No debe mostrar error de formato de correo
      expect(
        find.text('Ingresa un formato de correo válido'),
        findsNothing,
      );
    });

    testWidgets('Al alternar a modo registro se muestra el campo de Gamer Tag/Usuario',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const LoginScreen(),
        ),
      );

      // Inicialmente en login no existe el campo de nombre de usuario
      expect(find.text('Nombre de usuario / Gamer Tag'), findsNothing);

      // Alternar a modo registro
      await tester.tap(find.text('¿No tienes cuenta? Regístrate aquí'));
      await tester.pump();

      // Debe aparecer el título de registro y el campo de Gamer Tag
      expect(find.text('CREAR CUENTA'), findsOneWidget);
      expect(find.text('Nombre de usuario / Gamer Tag'), findsOneWidget);
      expect(find.text('REGISTRARME'), findsOneWidget);
    });

    testWidgets('Al presionar botón de acceso rápido de Lucas se cargan sus credenciales en el formulario',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const LoginScreen(),
        ),
      );

      final lucasButton = find.widgetWithText(OutlinedButton, 'Lucas');
      await tester.ensureVisible(lucasButton);
      await tester.tap(lucasButton);
      await tester.pump();

      // Verificar que los campos reflejen tanto el correo como la contraseña de Lucas
      expect(find.text('lucas@volleybet.udd'), findsOneWidget);
      expect(find.text('volleybet123'), findsOneWidget);
    });
  });

  group('HU-01: AuthGate & HomeScreen Tests', () {
    testWidgets('AuthGate redirige a LoginScreen cuando no existe sesión activa',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AuthGate(),
        ),
      );

      await tester.pump();

      // Debe montar LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('VOLLEYBET'), findsOneWidget);
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
    });

    testWidgets('HomeScreen muestra branding, balance de puntos y botón de cerrar sesión',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => BettingProvider(),
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const HomeScreen(),
          ),
        ),
      );

      // Esperar resolución de microtareas iniciales
      await tester.pump();
      await tester.pump();

      // Branding y saldo
      expect(find.text('VOLLEYBET'), findsOneWidget);
      expect(find.text('1000 PTS VIRTUALES'), findsOneWidget);
      expect(find.text('HU-01: Setup & Auth Completado'), findsOneWidget);

      // Botón de cerrar sesión en AppBar y al final
      expect(find.byTooltip('Cerrar Sesión'), findsOneWidget);
      expect(find.text('Cerrar Sesión'), findsOneWidget);

      // Verificamos botón de navegación a la Cartelera de Partidos (HU-02)
      expect(find.text('CARTELERA DE VOLEIBOL'), findsOneWidget);
      expect(find.text('EXPLORAR CARTELERA'), findsOneWidget);
    });

    testWidgets('Al presionar EXPLORAR CARTELERA en HomeScreen navega a MatchesScreen',
        (WidgetTester tester) async {
      final mockDio = Dio();
      mockDio.httpClientAdapter = MockDioAdapter((options) async {
        return ResponseBody.fromString('{"response":[]}', 200, headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        });
      });
      SportsApiService.instance = SportsApiService(
        dio: mockDio,
        overrideApiSportsKey: 'test-key',
      );

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => BettingProvider(),
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const HomeScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      final exploreButton = find.text('EXPLORAR CARTELERA');
      await tester.ensureVisible(exploreButton);
      await tester.tap(exploreButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(MatchesScreen), findsOneWidget);
    });
  });

  // ===========================================================================
  // HU-02: Consumo de API Deportiva con dio, FutureBuilder y Detalle con Hero
  // ===========================================================================

  group('HU-02: MatchModel & Deserialization Tests', () {
    test('MatchModel deserializa correctamente formato API-Sports', () {
      final json = {
        'id': 214958,
        'date': '2026-10-20T18:00:00+00:00',
        'league': {'name': 'Superliga Women'},
        'teams': {
          'home': {'name': 'SESC-RJ W', 'logo': 'https://api-sports.io/sesc.png'},
          'away': {'name': 'Barueri W', 'logo': 'https://api-sports.io/barueri.png'},
        },
        'status': {'short': 'FT', 'long': 'Finished'},
        'scores': {'home': 3, 'away': 0},
        'periods': {
          'first': {'home': 25, 'away': 19},
          'second': {'home': 25, 'away': 21},
          'third': {'home': 25, 'away': 14},
        },
      };

      final match = MatchModel.fromApiSports(json);

      expect(match.id, '214958');
      expect(match.tournament, 'Superliga Women');
      expect(match.homeTeam, 'SESC-RJ W');
      expect(match.awayTeam, 'Barueri W');
      expect(match.homeLogo, 'https://api-sports.io/sesc.png');
      expect(match.awayLogo, 'https://api-sports.io/barueri.png');
      expect(match.status, 'FT');
      expect(match.isFinished, isTrue);
      expect(match.isLive, isFalse);
      expect(match.scores?.home, 3);
      expect(match.scores?.away, 0);
      expect(match.sourceProvider, 'api-sports');
      expect(match.homeOdds, greaterThan(1.0));
      expect(match.awayOdds, greaterThan(1.0));
    });

    test('MatchModel deserializa correctamente formato Sportradar Volleyball v2', () {
      final json = {
        'sport_event': {
          'id': 'sr:sport_event:9999',
          'start_time': '2026-10-20T20:00:00+00:00',
          'sport_event_context': {
            'competition': {'name': 'CEV Champions League'},
          },
          'competitors': [
            {'name': 'Trentino Volley', 'qualifier': 'home'},
            {'name': 'Perugia', 'qualifier': 'away'},
          ],
        },
        'sport_event_status': {
          'status': 'closed',
          'home_score': 3,
          'away_score': 2,
          'period_scores': [
            {'home_score': 25, 'away_score': 20, 'number': 1},
            {'home_score': 23, 'away_score': 25, 'number': 2},
            {'home_score': 25, 'away_score': 21, 'number': 3},
            {'home_score': 20, 'away_score': 25, 'number': 4},
            {'home_score': 15, 'away_score': 12, 'number': 5},
          ],
        },
      };

      final match = MatchModel.fromSportradar(json);

      expect(match.id, 'sr:sport_event:9999');
      expect(match.tournament, 'CEV Champions League');
      expect(match.homeTeam, 'Trentino Volley');
      expect(match.awayTeam, 'Perugia');
      expect(match.status, 'closed');
      expect(match.isFinished, isTrue);
      expect(match.scores?.home, 3);
      expect(match.scores?.away, 2);
      expect(match.scores?.periods?['first']?['home'], 25);
      expect(match.scores?.periods?['first']?['away'], 20);
      expect(match.scores?.periods?['fifth']?['home'], 15);
      expect(match.sourceProvider, 'sportradar');
      expect(match.homeOdds, greaterThan(1.0));
      expect(match.awayOdds, greaterThan(1.0));
    });

    test('MatchModel mapea correctamente estados started y ended de Sportradar', () {
      final startedMatch = MatchModel.fromSportradar({
        'sport_event': {'id': 'sr:1'},
        'sport_event_status': {'status': 'started'},
      });
      expect(startedMatch.isLive, isTrue);
      expect(startedMatch.isFinished, isFalse);
      expect(startedMatch.statusDisplay, 'EN VIVO');

      final endedMatch = MatchModel.fromSportradar({
        'sport_event': {'id': 'sr:2'},
        'sport_event_status': {'status': 'ended'},
      });
      expect(endedMatch.isLive, isFalse);
      expect(endedMatch.isFinished, isTrue);
      expect(endedMatch.statusDisplay, 'FINALIZADO');
    });

    test('MatchModel genera tags Hero conformes a la especificación docente (Requisito 4)', () {
      const match = MatchModel(
        id: '214958',
        tournament: 'Superliga',
        homeTeam: 'Brasil',
        awayTeam: 'Polonia',
        homeOdds: 1.75,
        awayOdds: 2.10,
        matchDate: _dummyDate,
        status: 'NS',
        sourceProvider: 'mock-local',
      );

      expect(match.homeHeroTag, 'team-logo-214958-home');
      expect(match.awayHeroTag, 'team-logo-214958-away');
      expect(match.heroTagFor(isHome: true), 'team-logo-214958-home');
      expect(match.heroTagFor(isHome: false), 'team-logo-214958-away');
    });

    test('MatchModel genera cuotas deterministas y estables ante la ausencia de odds en la API', () {
      final (home1, away1) = MatchModel.generateDeterministicOdds('match-1', 'Equipo A', 'Equipo B');
      final (home2, away2) = MatchModel.generateDeterministicOdds('match-1', 'Equipo A', 'Equipo B');
      final (home3, away3) = MatchModel.generateDeterministicOdds('match-2', 'Equipo C', 'Equipo D');

      // Mismo partido = exactamente las mismas cuotas
      expect(home1, home2);
      expect(away1, away2);

      // Partidos diferentes = cuotas calculadas independientemente
      expect(home1, isNot(equals(home3)));

      // Valores en rangos realistas de cuotas deportivas
      expect(home1, inInclusiveRange(1.20, 4.00));
      expect(away1, inInclusiveRange(1.20, 4.00));
    });

    test('MatchModel identifica correctamente estados en vivo, finalizado y por jugar', () {
      final liveMatch = MatchModel(
        id: '1',
        tournament: 'Liga',
        homeTeam: 'A',
        awayTeam: 'B',
        homeOdds: 1.8,
        awayOdds: 2.0,
        matchDate: _dummyDate,
        status: 'S2',
        sourceProvider: 'api-sports',
      );
      expect(liveMatch.isLive, isTrue);
      expect(liveMatch.isFinished, isFalse);
      expect(liveMatch.statusDisplay, 'SET 2 (EN VIVO)');

      final finishedMatch = MatchModel(
        id: '2',
        tournament: 'Liga',
        homeTeam: 'A',
        awayTeam: 'B',
        homeOdds: 1.8,
        awayOdds: 2.0,
        matchDate: _dummyDate,
        status: 'FT',
        sourceProvider: 'api-sports',
      );
      expect(finishedMatch.isLive, isFalse);
      expect(finishedMatch.isFinished, isTrue);
      expect(finishedMatch.statusDisplay, 'FINALIZADO');

      final pendingMatch = MatchModel(
        id: '3',
        tournament: 'Liga',
        homeTeam: 'A',
        awayTeam: 'B',
        homeOdds: 1.8,
        awayOdds: 2.0,
        matchDate: _dummyDate,
        status: 'NS',
        sourceProvider: 'api-sports',
      );
      expect(pendingMatch.isLive, isFalse);
      expect(pendingMatch.isFinished, isFalse);
      expect(pendingMatch.statusDisplay, 'POR JUGAR');
    });
  });

  group('HU-02: SportsApiService Failover & Cache Tests', () {
    test('Caché en memoria con TTL de 15 min evita llamadas de red sucesivas', () async {
      int requestCount = 0;
      final dio = Dio();
      dio.httpClientAdapter = MockDioAdapter((options) async {
        requestCount++;
        final payload = jsonEncode({
          'get': 'games',
          'errors': [],
          'results': 1,
          'response': [
            {
              'id': 101,
              'date': '2026-10-20T18:00:00+00:00',
              'league': {'name': 'Caché League'},
              'teams': {
                'home': {'name': 'Local'},
                'away': {'name': 'Visita'},
              },
              'status': {'short': 'NS'},
            }
          ],
        });
        return ResponseBody.fromString(payload, 200, headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        });
      });

      final service = SportsApiService(
        dio: dio,
        overrideApiSportsKey: 'test-key',
        cacheTtl: const Duration(minutes: 15),
      );

      // Primera llamada: debe realizar petición de red
      final matches1 = await service.getMatches();
      expect(matches1.length, 1);
      expect(requestCount, 1);
      expect(service.hasValidCache, isTrue);

      // Segunda llamada dentro del TTL: debe servir desde caché
      final matches2 = await service.getMatches();
      expect(matches2.length, 1);
      expect(requestCount, 1); // No incrementa

      // Tercera llamada con forceRefresh: true debe saltarse el caché
      final matches3 = await service.getMatches(forceRefresh: true);
      expect(matches3.length, 1);
      expect(requestCount, 2); // Incrementa
    });

    test('Failover dinámico: conmutación a Sportradar si API-Sports falla', () async {
      final dio = Dio();
      dio.httpClientAdapter = MockDioAdapter((options) async {
        // Fallo en API-Sports
        if (options.uri.host.contains('api-sports.io')) {
          expect(options.headers['x-apisports-key'], 'test-api-sports-key');
          return ResponseBody.fromString('{"errors":{"requests":"Rate limit exceeded"}}', 200, headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          });
        }
        // Éxito en Sportradar
        if (options.uri.host.contains('sportradar.com')) {
          expect(options.queryParameters['api_key'], 'test-sportradar-key');
          expect(options.headers['Accept'], 'application/json');
          final payload = jsonEncode({
            'summaries': [
              {
                'sport_event': {
                  'id': 'sr:sport_event:4444',
                  'start_time': '2026-10-20T19:00:00+00:00',
                  'sport_event_context': {
                    'competition': {'name': 'Sportradar Failover Cup'},
                  },
                  'competitors': [
                    {'name': 'Team Alpha', 'qualifier': 'home'},
                    {'name': 'Team Beta', 'qualifier': 'away'},
                  ],
                },
                'sport_event_status': {'status': 'live', 'home_score': 1, 'away_score': 0},
              }
            ]
          });
          return ResponseBody.fromString(payload, 200, headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          });
        }
        throw Exception('Host no reconocido');
      });

      final service = SportsApiService(
        dio: dio,
        overrideApiSportsKey: 'test-api-sports-key',
        overrideSportradarKey: 'test-sportradar-key',
      );

      final matches = await service.getMatches(forceRefresh: true);
      expect(matches.length, 1);
      expect(matches.first.id, 'sr:sport_event:4444');
      expect(matches.first.sourceProvider, 'sportradar');
      expect(service.activeSource, 'sportradar');
    });

    test('Failover dinámico: conmutación a assets/mock_matches.json si ambas APIs fallan', () async {
      final dio = Dio();
      dio.httpClientAdapter = MockDioAdapter((options) async {
        // Ambas APIs devuelven error de conexión/cuota
        throw DioException(
          requestOptions: options,
          error: 'Connection refused / Quota exceeded',
          type: DioExceptionType.connectionError,
        );
      });

      const mockJson = '''
      {
        "get": "games",
        "errors": [],
        "results": 2,
        "response": [
          {
            "id": 9001,
            "date": "2026-10-20T12:00:00+00:00",
            "league": {"name": "Mock League"},
            "teams": {
              "home": {"name": "Mock Home"},
              "away": {"name": "Mock Away"}
            },
            "status": {"short": "FT"},
            "scores": {"home": 3, "away": 1}
          }
        ]
      }
      ''';

      final fakeBundle = FakeAssetBundle(mockJson);
      final service = SportsApiService(
        dio: dio,
        assetBundle: fakeBundle,
        overrideApiSportsKey: 'test-key',
        overrideSportradarKey: 'test-key',
      );

      final matches = await service.getMatches(forceRefresh: true);
      expect(matches.length, 1);
      expect(matches.first.id, '9001');
      expect(matches.first.homeTeam, 'Mock Home');
      expect(matches.first.sourceProvider, 'mock-local');
      expect(service.activeSource, 'mock-local');
    });
  });

  group('HU-02: OddsButton & MatchCard Widget Tests', () {
    testWidgets('OddsButton muestra etiqueta, cuota formateada y responde al tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Center(
              child: OddsButton(
                label: '1 (Local)',
                odds: 1.85,
                isSelected: false,
                onPressed: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('1 (LOCAL)'), findsOneWidget);
      expect(find.text('1.85'), findsOneWidget);

      await tester.tap(find.byType(OddsButton));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('MatchCard renderiza datos, cuotas y tags Hero correspondientes (Requisito 4)', (tester) async {
      const match = MatchModel(
        id: '777',
        tournament: 'Copa Libertadores Voley',
        homeTeam: 'Sada Cruzeiro',
        awayTeam: 'UPCN San Juan',
        homeOdds: 1.45,
        awayOdds: 2.80,
        matchDate: _dummyDate,
        status: 'FT',
        scores: MatchScores(home: 3, away: 0),
        sourceProvider: 'mock-local',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: MatchCard(match: match),
          ),
        ),
      );

      expect(find.text('COPA LIBERTADORES VOLEY'), findsOneWidget);
      expect(find.text('Sada Cruzeiro'), findsOneWidget);
      expect(find.text('UPCN San Juan'), findsOneWidget);
      expect(find.text('3 - 0'), findsOneWidget);
      expect(find.text('FINALIZADO'), findsOneWidget);
      expect(find.text('1.45'), findsOneWidget);
      expect(find.text('2.80'), findsOneWidget);

      // Verificamos presencia de los dos widgets Hero con tags exactos
      final heroes = tester.widgetList<Hero>(find.byType(Hero)).toList();
      final heroTags = heroes.map((h) => h.tag).toList();
      expect(heroTags, contains('team-logo-777-home'));
      expect(heroTags, contains('team-logo-777-away'));
    });

    testWidgets('MatchCard navega a MatchDetailScreen pasando MatchModel por constructor (Requisito 3)',
        (tester) async {
      const match = MatchModel(
        id: '888',
        tournament: 'Superliga Masculina',
        homeTeam: 'SESI-SP',
        awayTeam: 'Campinas',
        homeOdds: 1.65,
        awayOdds: 2.25,
        matchDate: _dummyDate,
        status: 'NS',
        sourceProvider: 'mock-local',
      );

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => BettingProvider(),
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: MatchCard(match: match),
            ),
          ),
        ),
      );

      // Tocar la tarjeta
      await tester.tap(find.byType(MatchCard));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Debe haber navegado a MatchDetailScreen
      expect(find.byType(MatchDetailScreen), findsOneWidget);
      expect(find.text('DETALLE DEL ENCUENTRO'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(MatchDetailScreen),
          matching: find.text('SESI-SP'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(MatchDetailScreen),
          matching: find.text('Campinas'),
        ),
        findsOneWidget,
      );
    });
  });

  group('HU-02: MatchesScreen 3 States (FutureBuilder) Tests', () {
    testWidgets('Estado 1 (waiting): Muestra spinner anime centrado mientras carga (Requisito 2)',
        (tester) async {
      final completer = Completer<List<MatchModel>>();
      final service = DelayedSportsApiService(completer);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: MatchesScreen(apiService: service),
        ),
      );

      // En el primer render debe estar en ConnectionState.waiting
      expect(find.byKey(const ValueKey('matches-waiting-state')), findsOneWidget);
      expect(find.text('CARGANDO CARTELERA DEPORTIVA'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete([]);
      await tester.pumpAndSettle();

      // Debe mostrar el estado vacío amigable
      expect(find.text('NO HAY PARTIDOS PROGRAMADOS'), findsOneWidget);
      expect(find.byType(MatchCard), findsNothing);
    });

    testWidgets('Estado 2 (error): Muestra mensaje de error y botón REINTENTAR ante fallo crítico',
        (tester) async {
      final dio = Dio();
      dio.httpClientAdapter = MockDioAdapter((options) async {
        throw DioException(
          requestOptions: options,
          error: 'Red inalcanzable',
          type: DioExceptionType.connectionError,
        );
      });

      // Asset bundle que también falla para forzar error en los 3 niveles
      final errorBundle = ErrorThrowingAssetBundle();
      final service = SportsApiService(
        dio: dio,
        assetBundle: errorBundle,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: MatchesScreen(apiService: service),
        ),
      );

      await tester.pumpAndSettle();

      // Debe mostrar el estado de error con el botón de reintento
      expect(find.byKey(const ValueKey('matches-error-state')), findsOneWidget);
      expect(find.text('ERROR AL CARGAR PARTIDOS'), findsOneWidget);
      expect(find.text('REINTENTAR'), findsOneWidget);
    });

    testWidgets('Estado 3 (data): Renderiza lista de MatchCard y badge de proveedor con datos válidos',
        (tester) async {
      const mockJson = '''
      {
        "get": "games",
        "errors": [],
        "results": 2,
        "response": [
          {
            "id": 111,
            "date": "2026-10-20T18:00:00+00:00",
            "league": {"name": "Champions League"},
            "teams": {
              "home": {"name": "Berlin Recycling"},
              "away": {"name": "Sir Safety Perugia"}
            },
            "status": {"short": "NS"}
          },
          {
            "id": 222,
            "date": "2026-10-20T20:00:00+00:00",
            "league": {"name": "Champions League"},
            "teams": {
              "home": {"name": "Zaksa"},
              "away": {"name": "Lube Civitanova"}
            },
            "status": {"short": "FT"},
            "scores": {"home": 3, "away": 2}
          }
        ]
      }
      ''';

      final service = SportsApiService(
        dio: Dio(),
        assetBundle: FakeAssetBundle(mockJson),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: MatchesScreen(apiService: service),
        ),
      );

      await tester.pumpAndSettle();

      // Verifica lista con 2 tarjetas
      expect(find.byType(MatchCard), findsNWidgets(2));
      expect(find.text('2 PARTIDOS DISPONIBLES'), findsOneWidget);
      expect(find.text('MODO DATOS LOCALES'), findsOneWidget);
      expect(find.text('Berlin Recycling'), findsOneWidget);
      expect(find.text('Zaksa'), findsOneWidget);
    });

    testWidgets('Al presionar botón REINTENTAR en estado de error se reejecuta la carga',
        (tester) async {
      int attempts = 0;
      final dio = Dio();
      dio.httpClientAdapter = MockDioAdapter((options) async {
        attempts++;
        if (attempts == 1) {
          throw DioException(
            requestOptions: options,
            error: 'Fallo de red temporal',
            type: DioExceptionType.connectionError,
          );
        }
        final payload = jsonEncode({
          'get': 'games',
          'errors': [],
          'results': 1,
          'response': [
            {
              'id': 333,
              'date': '2026-10-20T18:00:00+00:00',
              'league': {'name': 'Recuperado League'},
              'teams': {
                'home': {'name': 'Equipo Recuperado'},
                'away': {'name': 'Visita'},
              },
              'status': {'short': 'NS'},
            }
          ],
        });
        return ResponseBody.fromString(payload, 200, headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        });
      });

      // Asset bundle que falla inicialmente
      final errorBundle = ErrorThrowingAssetBundle();
      final service = SportsApiService(
        dio: dio,
        assetBundle: errorBundle,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: MatchesScreen(apiService: service),
        ),
      );

      await tester.pumpAndSettle();

      // Debe estar en estado de error
      expect(find.byKey(const ValueKey('matches-error-state')), findsOneWidget);
      final retryButton = find.text('REINTENTAR');
      expect(retryButton, findsOneWidget);

      // Presionar botón REINTENTAR
      await tester.tap(retryButton);
      await tester.pump();
      await tester.pumpAndSettle();

      // Ahora debe haber recuperado los datos y mostrar MatchCard
      expect(find.byType(MatchCard), findsOneWidget);
      expect(find.text('Equipo Recuperado'), findsOneWidget);
    });

    testWidgets('Interacción de pull-to-refresh en MatchesScreen ejecuta recarga forzada',
        (tester) async {
      int fetchCount = 0;
      final dio = Dio();
      dio.httpClientAdapter = MockDioAdapter((options) async {
        fetchCount++;
        final payload = jsonEncode({
          'get': 'games',
          'errors': [],
          'results': 1,
          'response': [
            {
              'id': 555,
              'date': '2026-10-20T18:00:00+00:00',
              'league': {'name': 'Pull-to-refresh League'},
              'teams': {
                'home': {'name': 'Home PTR'},
                'away': {'name': 'Away PTR'},
              },
              'status': {'short': 'NS'},
            }
          ],
        });
        return ResponseBody.fromString(payload, 200, headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        });
      });

      final service = SportsApiService(
        dio: dio,
        overrideApiSportsKey: 'test-key',
        assetBundle: ErrorThrowingAssetBundle(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: MatchesScreen(apiService: service),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Home PTR'), findsOneWidget);
      expect(fetchCount, 1);

      // Ejecutar gesto pull-to-refresh
      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(fetchCount, greaterThanOrEqualTo(2));
      expect(find.text('Cartelera de partidos actualizada.'), findsOneWidget);
    });

    testWidgets('Fallo en pull-to-refresh preserva datos previos y notifica al usuario con SnackBar',
        (tester) async {
      int fetchCount = 0;
      final dio = Dio();
      dio.httpClientAdapter = MockDioAdapter((options) async {
        fetchCount++;
        if (fetchCount == 1) {
          final payload = jsonEncode({
            'get': 'games',
            'errors': [],
            'results': 1,
            'response': [
              {
                'id': 777,
                'date': '2026-10-20T18:00:00+00:00',
                'league': {'name': 'Resilience League'},
                'teams': {
                  'home': {'name': 'Home Resilient'},
                  'away': {'name': 'Away Resilient'},
                },
                'status': {'short': 'NS'},
              }
            ],
          });
          return ResponseBody.fromString(payload, 200, headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          });
        }
        // Segunda llamada (pull-to-refresh) falla
        throw DioException(
          requestOptions: options,
          error: 'Conexión interrumpida',
        );
      });

      final service = SportsApiService(
        dio: dio,
        overrideApiSportsKey: 'test-key',
        assetBundle: ErrorThrowingAssetBundle(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: MatchesScreen(apiService: service),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Home Resilient'), findsOneWidget);
      expect(find.byType(MatchCard), findsOneWidget);

      // Ejecutar gesto pull-to-refresh que fallará
      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 300));

      // Debe preservar los datos anteriores sin sustituir por la vista de error
      expect(find.byType(MatchCard), findsOneWidget);
      expect(find.text('Home Resilient'), findsOneWidget);
      expect(find.textContaining('Manteniendo datos anteriores'), findsOneWidget);
    });
  });

  group('HU-02: MatchDetailScreen & Hero Animation Tests', () {
    testWidgets('MatchDetailScreen muestra cabecera Hero, parciales y selector interactivo de cuotas',
        (tester) async {
      const match = MatchModel(
        id: '333',
        tournament: 'Superliga Italiana',
        homeTeam: 'Trentino',
        awayTeam: 'Modena',
        homeOdds: 1.55,
        awayOdds: 2.45,
        matchDate: _dummyDate,
        status: 'FT',
        scores: MatchScores(
          home: 3,
          away: 1,
          periods: {
            'first': {'home': 25, 'away': 21},
            'second': {'home': 22, 'away': 25},
            'third': {'home': 25, 'away': 18},
            'fourth': {'home': 25, 'away': 20},
          },
        ),
        sourceProvider: 'mock-local',
      );

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => BettingProvider(),
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const MatchDetailScreen(match: match),
          ),
        ),
      );

      // Verificar pantalla de detalle y Hero tags
      expect(find.text('DETALLE DEL ENCUENTRO'), findsOneWidget);
      expect(find.text('SUPERLIGA ITALIANA'), findsOneWidget);
      expect(find.text('3 : 1'), findsOneWidget);
      expect(find.text('PARCIALES POR SET'), findsOneWidget);
      expect(find.text('25 - 21'), findsOneWidget);

      // Hero tags correspondientes en el detalle
      final heroes = tester.widgetList<Hero>(find.byType(Hero)).toList();
      final tags = heroes.map((h) => h.tag).toList();
      expect(tags, contains('team-logo-333-home'));
      expect(tags, contains('team-logo-333-away'));

      // Probar interacción con cuotas colectivas
      expect(find.text('CUOTAS DE VICTORIA (1X2)'), findsOneWidget);
      final localButton = find.widgetWithText(OddsButton, '1 (LOCAL)');
      await tester.tap(localButton);
      await tester.pump();

      // Debe aparecer el pronóstico seleccionado
      expect(find.textContaining('Pronóstico seleccionado: Trentino'), findsOneWidget);
    });
  });
}

const _dummyDate = _StaticDate();

class _StaticDate implements DateTime {
  const _StaticDate();
  @override
  DateTime toLocal() => this;
  @override
  String toIso8601String() => '2026-10-20T18:00:00.000Z';
  @override
  int get year => 2026;
  @override
  int get month => 10;
  @override
  int get day => 20;
  @override
  int get hour => 18;
  @override
  int get minute => 0;
  @override
  int get second => 0;
  @override
  int get millisecond => 0;
  @override
  int get microsecond => 0;
  @override
  bool isAfter(DateTime other) => false;
  @override
  bool isBefore(DateTime other) => false;
  @override
  bool isAtSameMomentAs(DateTime other) => true;
  @override
  int compareTo(DateTime other) => 0;
  @override
  DateTime add(Duration duration) => this;
  @override
  DateTime subtract(Duration duration) => this;
  @override
  Duration difference(DateTime other) => Duration.zero;
  @override
  int get millisecondsSinceEpoch => 1792519200000;
  @override
  int get microsecondsSinceEpoch => 1792519200000000;
  @override
  String get timeZoneName => 'UTC';
  @override
  Duration get timeZoneOffset => Duration.zero;
  @override
  DateTime toUtc() => this;
  @override
  int get weekday => DateTime.tuesday;
  @override
  bool get isUtc => true;
}

class MockDioAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;
  MockDioAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

class FakeAssetBundle extends Fake implements AssetBundle {
  final String jsonString;
  FakeAssetBundle(this.jsonString);

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    return jsonString;
  }
}

class ErrorThrowingAssetBundle extends Fake implements AssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    throw Exception('Error cargando asset mock');
  }
}

class DelayedSportsApiService extends Fake implements SportsApiService {
  final Completer<List<MatchModel>> completer;
  DelayedSportsApiService(this.completer);

  @override
  String get activeSource => 'api-sports';

  @override
  Future<List<MatchModel>> getMatches({bool forceRefresh = false, DateTime? date}) {
    return completer.future;
  }
}

