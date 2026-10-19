import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:volleybet/models/user_profile.dart';
import 'package:volleybet/screens/auth/auth_gate.dart';
import 'package:volleybet/screens/auth/login_screen.dart';
import 'package:volleybet/screens/home/home_screen.dart';
import 'package:volleybet/services/supabase_service.dart';
import 'package:volleybet/theme/app_theme.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
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
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const HomeScreen(),
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
    });
  });
}
