import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import 'login_screen.dart';
import '../home/home_screen.dart';

/// Widget guardián de autenticación (Requisito Docente 1).
/// Escucha en tiempo real los cambios de sesión de Supabase Auth a través de un StreamBuilder.
/// Redirige automáticamente a LoginScreen si no hay sesión activa, o a HomeScreen si el usuario está autenticado.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: SupabaseService.instance.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Error en el servicio de autenticación',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const AuthGate()),
                        );
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Si el stream tiene datos, su sesión es la fuente autoritativa de verdad.
        // Solo usamos la sesión en caché antes de recibir el primer evento del stream.
        final session = snapshot.hasData
            ? snapshot.data?.session
            : SupabaseService.instance.currentSession;

        if (session != null) {
          return const HomeScreen();
        }

        // Si el stream está conectando por primera vez y no hay sesión en caché
        if (snapshot.connectionState == ConnectionState.waiting && session == null) {
          return const Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryOrange,
              ),
            ),
          );
        }

        // Sin sesión -> Pantalla de Login/Registro
        return const LoginScreen();
      },
    );
  }
}
