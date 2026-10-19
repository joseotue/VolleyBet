import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/supabase_service.dart';
import 'screens/auth/auth_gate.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  // Asegurar la inicialización del binding de Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno desde .env
  await dotenv.load(fileName: ".env");

  // Inicializar cliente de Supabase con URL y Anon Key del .env
  await SupabaseService.initialize();

  runApp(const VolleyBetApp());
}

/// Aplicación principal VolleyBet
class VolleyBetApp extends StatelessWidget {
  const VolleyBetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VolleyBet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthGate(),
    );
  }
}
