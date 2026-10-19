import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/supabase_service.dart';
import 'screens/auth/auth_gate.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  // Asegurar la inicialización del binding de Flutter
  WidgetsFlutterBinding.ensureInitialized();

  String? initializationError;
  try {
    // Cargar variables de entorno desde .env
    await dotenv.load(fileName: ".env");

    // Inicializar cliente de Supabase con URL y Anon Key del .env
    await SupabaseService.initialize();
  } catch (e) {
    initializationError = e.toString();
  }

  if (initializationError != null) {
    runApp(ConfigErrorApp(error: initializationError));
    return;
  }

  runApp(const VolleyBetApp());
}

/// Pantalla informativa en caso de fallo crítico en variables de entorno o inicialización
class ConfigErrorApp extends StatelessWidget {
  final String error;
  const ConfigErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VolleyBet - Error de Configuración',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                color: AppTheme.cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.settings_suggest_rounded, color: AppTheme.primaryOrange, size: 54),
                      const SizedBox(height: 16),
                      Text(
                        'CONFIGURACIÓN REQUERIDA',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.primaryOrange,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No se pudo inicializar la conexión con Supabase. Verifica que el archivo .env exista en la raíz y contenga SUPABASE_URL y SUPABASE_ANON_KEY válidos.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          error,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
