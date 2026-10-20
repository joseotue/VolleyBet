import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/supabase_service.dart';
import '../../models/user_profile.dart';
import '../../theme/app_theme.dart';
import '../matches/matches_screen.dart';

/// Pantalla protegida temporal de VolleyBet para verificar sesión autenticada.
/// Cumple con la validación de transición de AuthGate y Cierre de Sesión (HU-01).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserProfile? _userProfile;
  bool _isLoadingProfile = true;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = SupabaseService.instance.currentUser;
    if (user != null) {
      final profile = await SupabaseService.instance.getUserProfile(user.id);
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoadingProfile = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  Future<void> _handleSignOut() async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);

    try {
      await SupabaseService.instance.signOut();
      // AuthGate escuchará el cambio de auth y redirigirá de inmediato al Login
    } catch (e) {
      if (mounted) {
        setState(() => _isSigningOut = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.instance.currentUser;
    final email = user?.email ?? 'Sin correo';
    final username = _userProfile?.username ??
        user?.userMetadata?['username']?.toString() ??
        email.split('@').first;
    final points = _userProfile?.pointsBalance ?? 1000;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sports_volleyball, color: AppTheme.primaryOrange, size: 28),
            const SizedBox(width: 8),
            Text(
              'VOLLEYBET',
              style: GoogleFonts.teko(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryOrange,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.textSecondary),
            tooltip: 'Cerrar Sesión',
            onPressed: _isSigningOut ? null : _handleSignOut,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tarjeta de bienvenida del usuario
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppTheme.primaryOrange.withValues(alpha: 0.2),
                        child: Text(
                          username.isNotEmpty ? username[0].toUpperCase() : 'V',
                          style: GoogleFonts.teko(
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryOrange,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '¡Bienvenido, $username!',
                        style: GoogleFonts.barlowCondensed(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: GoogleFonts.rajdhani(
                          fontSize: 15,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Badge de puntos virtuales
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primaryOrange.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.monetization_on_rounded,
                              color: AppTheme.primaryOrange,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            _isLoadingProfile
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.primaryOrange,
                                    ),
                                  )
                                : Text(
                                    '$points PTS VIRTUALES',
                                    style: GoogleFonts.barlowCondensed(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryOrange,
                                      letterSpacing: 1,
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Tarjeta de Acceso a Cartelera de Partidos (HU-02)
              Card(
                color: const Color(0xFF222838),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppTheme.primaryOrange, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryOrange.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.sports_volleyball_rounded,
                              color: AppTheme.primaryOrange,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CARTELERA DE VOLEIBOL',
                                  style: GoogleFonts.teko(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryOrange,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                Text(
                                  'Consumo de API deportiva con failover resiliente y cuotas colectivas.',
                                  style: GoogleFonts.rajdhani(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('EXPLORAR CARTELERA'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryOrange,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MatchesScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Tarjeta de estado de arquitectura y requisitos docentes
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppTheme.successGreen,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'HU-01: Setup & Auth Completado',
                              style: GoogleFonts.barlowCondensed(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '✓ Material 3 Anime Theme (#1B1F29 / #FF6A1A)\n'
                        '✓ Supabase Auth con variables de entorno (.env)\n'
                        '✓ AuthGate reactivo con StreamBuilder\n'
                        '✓ Consumo API con dio, FutureBuilder (3 estados) y TTL 15m\n'
                        '✓ Failover dual: API-Sports -> Sportradar -> Mock Local\n'
                        '✓ Navegación por constructor a MatchDetailScreen con Hero\n'
                        '✓ Widgets modulares: MatchCard y OddsButton',
                        style: GoogleFonts.rajdhani(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Botón de cerrar sesión
              ElevatedButton.icon(
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Cerrar Sesión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cardColor,
                  foregroundColor: AppTheme.errorRed,
                  side: const BorderSide(color: AppTheme.errorRed, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isSigningOut ? null : _handleSignOut,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
