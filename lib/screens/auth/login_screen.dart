import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

/// Pantalla de Autenticación de VolleyBet (HU-01 / Requisito 1).
/// Implementa formulario validado para inicio de sesión y registro,
/// además de un selector de acceso rápido para los 3 perfiles del equipo (Lucas, Otue, Jesús).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoginMode = true; // true = Login, false = Registro
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      if (_isLoginMode) {
        await SupabaseService.instance.signInWithPassword(
          email: email,
          password: password,
        );
        // AuthGate interceptará la nueva sesión automáticamente
      } else {
        final response = await SupabaseService.instance.signUp(
          email: email,
          password: password,
          username: email.split('@').first,
        );
        if (mounted) {
          if (response.session == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Registro exitoso. Si tienes confirmación de correo activa, revisa tu bandeja.',
                ),
                backgroundColor: AppTheme.primaryOrange,
              ),
            );
          }
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        // En caso de credenciales inválidas, limpiar contraseña y mostrar error
        _passwordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.message.isNotEmpty
                  ? e.message
                  : 'Credenciales inválidas. Verifica tu correo y contraseña.',
            ),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _passwordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado de autenticación: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Autenticación automática de perfiles de prueba para la evaluación docente
  Future<void> _quickLogin(TeamQuickProfile profile) async {
    setState(() => _isLoading = true);
    _emailController.text = profile.email;
    _passwordController.text = profile.password;

    try {
      await SupabaseService.instance.signInWithQuickProfile(profile);
      // AuthGate transicionará automáticamente al HomeScreen
    } on AuthException catch (e) {
      if (mounted) {
        _passwordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al ingresar con perfil ${profile.name}: ${e.message}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _passwordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión con perfil ${profile.name}: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo e Identidad Visual Anime
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryOrange,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryOrange.withValues(alpha: 0.3),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.sports_volleyball_rounded,
                        size: 54,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'VOLLEYBET',
                      style: GoogleFonts.teko(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryOrange,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      'PRONÓSTICOS DE VOLEIBOL GAMIFICADOS',
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Tarjeta con Formulario
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _isLoginMode ? 'INICIAR SESIÓN' : 'CREAR CUENTA',
                              style: GoogleFonts.barlowCondensed(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Campo de Email
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              style: GoogleFonts.rajdhani(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Correo electrónico',
                                prefixIcon: Icon(Icons.email_outlined),
                                hintText: 'tu.correo@ejemplo.com',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Por favor ingresa tu correo electrónico';
                                }
                                final emailRegex = RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[a-zA-Z]{2,}$',
                                );
                                if (!emailRegex.hasMatch(value.trim())) {
                                  return 'Ingresa un formato de correo válido';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Campo de Contraseña
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: GoogleFonts.rajdhani(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon: const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa tu contraseña';
                                }
                                if (value.length < 6) {
                                  return 'La contraseña debe tener al menos 6 caracteres';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 22),

                            // Botón de Enviar (Login / Registro)
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submitForm,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        _isLoginMode
                                            ? 'ENTRAR AL JUEGO'
                                            : 'REGISTRARME',
                                      ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Alternar entre Login y Registro
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _isLoginMode = !_isLoginMode;
                                      });
                                    },
                              child: Text(
                                _isLoginMode
                                    ? '¿No tienes cuenta? Regístrate aquí'
                                    : '¿Ya tienes cuenta? Inicia sesión',
                                style: GoogleFonts.rajdhani(
                                  color: AppTheme.primaryOrange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sección de Acceso Rápido del Equipo (Evaluación UDD)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.bolt_rounded,
                                color: AppTheme.primaryOrange,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'ACCESO RÁPIDO DE EVALUACIÓN (EQUIPO UDD)',
                                  style: GoogleFonts.barlowCondensed(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Ingresa directamente con 1 toque sin escribir credenciales en la demo:',
                            style: GoogleFonts.rajdhani(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Botones de los 3 integrantes
                          ...SupabaseService.teamProfiles.map((profile) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: OutlinedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => _quickLogin(profile),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  backgroundColor:
                                      AppTheme.primaryOrange.withValues(alpha: 0.06),
                                  side: BorderSide(
                                    color: AppTheme.primaryOrange.withValues(alpha: 0.7),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: AppTheme.primaryOrange,
                                      child: Text(
                                        profile.name[0],
                                        style: GoogleFonts.teko(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            profile.name,
                                            style: GoogleFonts.barlowCondensed(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            profile.role,
                                            style: GoogleFonts.rajdhani(
                                              fontSize: 11,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 14,
                                      color: AppTheme.primaryOrange,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
