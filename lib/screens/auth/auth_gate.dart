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
        // Si hay una sesión activa en Supabase o en el evento de auth
        final session = snapshot.data?.session ?? SupabaseService.instance.currentSession;

        if (session != null) {
          return const HomeScreen();
        }

        // Si el stream está conectando por primera vez y no hay sesión en caché
        if (snapshot.connectionState == ConnectionState.waiting &&
            SupabaseService.instance.currentUser == null) {
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
