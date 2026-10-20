import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/match_model.dart';
import '../../services/sports_api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/match_card.dart';

/// Pantalla de cartelera de partidos de voleibol con FutureBuilder (HU-02 / Requisito 2).
/// Gestiona explícitamente los 3 estados:
/// 1. `ConnectionState.waiting`: Spinner centrado anime naranja
/// 2. `snapshot.hasError`: Mensaje amigable con botón de reintento
/// 3. `snapshot.hasData`: Lista interactiva de tarjetas `MatchCard`
class MatchesScreen extends StatefulWidget {
  final SportsApiService apiService;

  MatchesScreen({
    super.key,
    SportsApiService? apiService,
  }) : apiService = apiService ?? SportsApiService.instance;

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  late Future<List<MatchModel>> _matchesFuture;
  List<MatchModel>? _lastLoadedMatches;

  @override
  void initState() {
    super.initState();
    _loadMatches(forceRefresh: false);
  }

  void _loadMatches({bool forceRefresh = false}) {
    final future = widget.apiService.getMatches(forceRefresh: forceRefresh);
    future.then((matches) {
      if (mounted && _matchesFuture == future) {
        setState(() {
          _lastLoadedMatches = matches;
        });
      }
    }).catchError((e) {
      if (mounted && _matchesFuture == future && _lastLoadedMatches != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo actualizar: $e. Manteniendo datos anteriores.'),
            backgroundColor: AppTheme.errorRed,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

    setState(() {
      _matchesFuture = future;
    });
  }

  Future<void> _handlePullToRefresh() async {
    try {
      final updated = await widget.apiService.getMatches(forceRefresh: true);
      if (mounted) {
        setState(() {
          _lastLoadedMatches = updated;
          _matchesFuture = Future.value(updated);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cartelera de partidos actualizada.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo actualizar: $e. Manteniendo datos anteriores.'),
            backgroundColor: AppTheme.errorRed,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildWaitingState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            alignment: Alignment.center,
            child: Center(
              key: const ValueKey('matches-waiting-state'),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        strokeWidth: 3.5,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'CARGANDO CARTELERA DEPORTIVA',
                      style: GoogleFonts.teko(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryOrange,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Consultando API deportiva con failover resiliente...',
                      style: GoogleFonts.rajdhani(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(Object? error) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            key: const ValueKey('matches-error-state'),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                color: AppTheme.cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.signal_wifi_connected_no_internet_4_rounded,
                        color: AppTheme.errorRed,
                        size: 54,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'ERROR AL CARGAR PARTIDOS',
                        style: GoogleFonts.teko(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.errorRed,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No se pudo conectar a los proveedores deportivos ni al respaldo local.\n($error)',
                        style: GoogleFonts.rajdhani(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => _loadMatches(forceRefresh: true),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('REINTENTAR'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryOrange,
                          foregroundColor: Colors.white,
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

  Widget _buildSourceBadge(String source) {
    String label = 'API-SPORTS';
    Color color = AppTheme.primaryOrange;
    IconData icon = Icons.cloud_done_rounded;

    if (source == 'sportradar') {
      label = 'SPORTRADAR (FAILOVER)';
      color = Colors.blueAccent;
      icon = Icons.swap_horiz_rounded;
    } else if (source == 'mock-local') {
      label = 'MODO DATOS LOCALES';
      color = Colors.amberAccent;
      icon = Icons.offline_bolt_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.barlowCondensed(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataState(List<MatchModel> matches) {
    final source = matches.isNotEmpty
        ? matches.first.sourceProvider
        : widget.apiService.activeSource;

    if (matches.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.sports_volleyball_rounded,
                      size: 48,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'NO HAY PARTIDOS PROGRAMADOS',
                      style: GoogleFonts.teko(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'No se encontraron partidos para la fecha seleccionada.',
                      style: GoogleFonts.rajdhani(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
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

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: matches.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          // Encabezado con conteo y badge de proveedor
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${matches.length} PARTIDOS DISPONIBLES',
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                    letterSpacing: 1.0,
                  ),
                ),
                _buildSourceBadge(source),
              ],
            ),
          );
        }

        final match = matches[index - 1];
        return MatchCard(match: match);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sports_volleyball_rounded,
              color: AppTheme.primaryOrange,
              size: 26,
            ),
            const SizedBox(width: 8),
            Text(
              'CARTELERA DE VOLEIBOL',
              style: GoogleFonts.teko(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryOrange,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryOrange),
            tooltip: 'Actualizar Partidos',
            onPressed: () => _loadMatches(forceRefresh: true),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryOrange,
        backgroundColor: AppTheme.cardColor,
        onRefresh: _handlePullToRefresh,
        child: FutureBuilder<List<MatchModel>>(
          future: _matchesFuture,
          builder: (context, snapshot) {
            final isReloading =
                snapshot.connectionState == ConnectionState.waiting &&
                    _lastLoadedMatches != null;

            Widget content;
            // Estado 1: Espera / Carga
            if (snapshot.connectionState == ConnectionState.waiting &&
                _lastLoadedMatches == null) {
              content = _buildWaitingState();
            } else if (snapshot.hasError && _lastLoadedMatches == null) {
              // Estado 2: Error
              content = _buildErrorState(snapshot.error);
            } else if (snapshot.hasData) {
              // Estado 3: Datos
              content = _buildDataState(snapshot.data!);
            } else if (_lastLoadedMatches != null) {
              // Si hay datos previos durante recarga
              content = _buildDataState(_lastLoadedMatches!);
            } else {
              content = _buildWaitingState();
            }

            if (isReloading) {
              return Column(
                children: [
                  const LinearProgressIndicator(
                    minHeight: 2.5,
                    color: AppTheme.primaryOrange,
                    backgroundColor: AppTheme.background,
                  ),
                  Expanded(child: content),
                ],
              );
            }

            return content;
          },
        ),
      ),
    );
  }
}
