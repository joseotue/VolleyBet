import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/betting_provider.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/points_badge.dart';
import '../bets/bet_history_screen.dart';
import '../matches/matches_screen.dart';
import '../ranking/ranking_screen.dart';

/// Pantalla protegida temporal de VolleyBet para verificar sesión autenticada.
/// Cumple con la validación de transición de AuthGate y Cierre de Sesión (HU-01).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    // Saldo, insignias e historial se cargan en el estado global (HU-04).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BettingProvider>().loadUserData();
    });
  }

  Future<void> _handleSignOut() async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);
    final betting = context.read<BettingProvider>();

    try {
      await SupabaseService.instance.signOut();
      betting.reset();
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
    final betting = context.watch<BettingProvider>();
    final user = SupabaseService.instance.currentUser;
    final email = user?.email ?? 'Sin correo';
    final username =
        betting.username ??
        user?.userMetadata?['username']?.toString() ??
        email.split('@').first;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sports_volleyball,
              color: AppTheme.primaryOrange,
              size: 28,
            ),
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
          const Center(child: PointsBadge(compact: true)),
          IconButton(
            icon: const Icon(Icons.leaderboard_rounded),
            tooltip: 'Ver ranking',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RankingScreen()),
              );
            },
          ),
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
                        backgroundColor: AppTheme.primaryOrange.withValues(
                          alpha: 0.2,
                        ),
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
                      // Saldo reactivo con context.watch<BettingProvider>() (Requisito 7)
                      const PointsBadge(),
                      if (betting.badges.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          children: [
                            for (final badge in betting.badges)
                              Chip(
                                avatar: const Icon(
                                  Icons.military_tech_rounded,
                                  color: AppTheme.primaryOrange,
                                  size: 18,
                                ),
                                label: Text(badge),
                                backgroundColor: AppTheme.background,
                                side: const BorderSide(
                                  color: AppTheme.dividerColor,
                                ),
                              ),
                          ],
                        ),
                      ],
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
                  side: const BorderSide(
                    color: AppTheme.primaryOrange,
                    width: 1.5,
                  ),
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
                              color: AppTheme.primaryOrange.withValues(
                                alpha: 0.18,
                              ),
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

              // Tarjeta de acceso al historial de apuestas (HU-03 / HU-04)
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  leading: const Icon(
                    Icons.receipt_long_rounded,
                    color: AppTheme.primaryOrange,
                    size: 32,
                  ),
                  title: Text(
                    'MIS APUESTAS',
                    style: GoogleFonts.teko(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryOrange,
                      letterSpacing: 1.2,
                    ),
                  ),
                  subtitle: Text(
                    '${betting.activeBets.length} pendiente(s) · Racha actual: ${betting.streakCount} acierto(s)',
                    style: GoogleFonts.rajdhani(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.textSecondary,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BetHistoryScreen(),
                      ),
                    );
                  },
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
                        '✓ Widgets modulares: MatchCard y OddsButton\n'
                        '✓ HU-03: BetForm con validación y CRUD de bets bajo RLS\n'
                        '✓ HU-04: BettingProvider + motor de simulación acelerada',
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
