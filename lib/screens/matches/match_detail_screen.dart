import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/match_model.dart';
import '../../providers/betting_provider.dart';
import '../../services/simulation_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bet_form.dart';
import '../../widgets/odds_button.dart';
import '../../widgets/points_badge.dart';
import '../../widgets/simulation_control_dialog.dart';

/// Pantalla de detalle de un partido de voleibol (HU-02).
/// Recibe obligatoriamente la entidad por constructor: `required MatchModel match` (Requisito 3).
/// Implementa animación Hero en los escudos de los equipos (Requisito 4).
class MatchDetailScreen extends StatefulWidget {
  final MatchModel match;
  final String? initialSelectedTeam;

  const MatchDetailScreen({
    super.key,
    required this.match,
    this.initialSelectedTeam,
  });

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  String? _selectedTeam;
  int? _selectedTeamIndex;

  @override
  void initState() {
    super.initState();
    if (widget.initialSelectedTeam != null) {
      if (widget.initialSelectedTeam == widget.match.homeTeam) {
        _selectedTeam = widget.match.homeTeam;
        _selectedTeamIndex = 0;
      } else if (widget.initialSelectedTeam == widget.match.awayTeam) {
        _selectedTeam = widget.match.awayTeam;
        _selectedTeamIndex = 1;
      }
    }
  }

  Widget _buildDetailLogo({
    required String? logoUrl,
    required String teamName,
    required bool isHome,
  }) {
    final heroTag = widget.match.heroTagFor(isHome: isHome);
    final initials = teamName.isNotEmpty ? teamName.substring(0, 1).toUpperCase() : '?';

    Widget fallback = CircleAvatar(
      radius: 36,
      backgroundColor: AppTheme.background,
      child: Text(
        initials,
        style: GoogleFonts.teko(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryOrange,
        ),
      ),
    );

    return Hero(
      tag: heroTag,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: const Color(0xFF1E2330),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.primaryOrange,
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryOrange.withValues(alpha: 0.25),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
        clipBehavior: Clip.antiAlias,
        child: (logoUrl != null && logoUrl.startsWith('http'))
            ? Image.network(
                logoUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => fallback,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                  );
                },
              )
            : fallback,
        ),
      ),
    );
  }

  Widget _buildPeriodsBreakdown(SimulationResult? simulation) {
    final validPeriods = <MapEntry<String, Map>>[];

    if (simulation != null) {
      for (var i = 0; i < simulation.sets.length; i++) {
        final set = simulation.sets[i];
        validPeriods.add(MapEntry('Set ${i + 1}', {'home': set.home, 'away': set.away}));
      }
    } else {
      final periods = widget.match.scores?.periods;
      if (periods == null || periods.isEmpty) {
        return const SizedBox.shrink();
      }

      final periodKeys = ['first', 'second', 'third', 'fourth', 'fifth'];
      for (var i = 0; i < periodKeys.length; i++) {
        final key = periodKeys[i];
        if (periods.containsKey(key) && periods[key] is Map) {
          final periodMap = periods[key] as Map;
          if (periodMap['home'] != null || periodMap['away'] != null) {
            validPeriods.add(MapEntry('Set ${i + 1}', periodMap));
          }
        }
      }
    }

    if (validPeriods.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(top: 16),
      color: AppTheme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PARCIALES POR SET',
              style: GoogleFonts.barlowCondensed(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryOrange,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: validPeriods.map((entry) {
                  final p = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      children: [
                        Text(
                          entry.key,
                          style: GoogleFonts.barlowCondensed(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.dividerColor),
                          ),
                          child: Text(
                            '${p['home'] ?? 0} - ${p['away'] ?? 0}',
                            style: GoogleFonts.teko(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderBadge() {
    String label = 'API-SPORTS';
    Color color = AppTheme.primaryOrange;

    if (widget.match.sourceProvider == 'sportradar') {
      label = 'SPORTRADAR VOLLEYBALL';
      color = Colors.blueAccent;
    } else if (widget.match.sourceProvider == 'mock-local') {
      label = 'RESPALDO LOCAL OFFLINE';
      color = Colors.amberAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: GoogleFonts.barlowCondensed(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  bool get _isCancelled =>
      widget.match.status == 'CANC' || widget.match.status == 'CANCELLED';

  Future<void> _placeBet(BettingProvider betting, int amount) async {
    final team = _selectedTeam;
    if (team == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bet = await betting.placeBet(
        match: widget.match,
        selectedTeam: team,
        amount: amount,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Apuesta registrada: ${bet.pointsStaked} pts a ${bet.selectedTeam} '
            '(premio potencial ${bet.potentialPayout} pts)',
          ),
        ),
      );
      if (mounted) {
        setState(() {
          _selectedTeam = null;
          _selectedTeamIndex = null;
        });
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(BettingProvider.describeError(e)),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  Future<void> _openSimulation() {
    final match = widget.match;
    return SimulationControlDialog.show(
      context,
      matchId: match.id,
      homeTeam: match.homeTeam,
      awayTeam: match.awayTeam,
      runSimulation: (provider) => provider.simulateMatch(
        matchId: match.id,
        homeTeam: match.homeTeam,
        awayTeam: match.awayTeam,
        homeOdds: match.homeOdds,
        awayOdds: match.awayOdds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final betting = context.watch<BettingProvider>();
    final simulation = betting.simulationFor(match.id);
    final scores = match.scores;
    final homeScore = simulation?.homeSets ?? scores?.home;
    final awayScore = simulation?.awaySets ?? scores?.away;
    final hasScores = homeScore != null || awayScore != null;
    final isFinished = match.isFinished || simulation != null;
    final statusLabel = simulation != null ? 'FINALIZADO (SIMULADO)' : match.statusDisplay;
    // Solo se apuesta antes del inicio: con resultados reales, apostar en vivo sería ventajoso.
    final canBet = match.isUpcoming && simulation == null;
    final matchBets = betting.betsForMatch(match.id);
    final pendingBets = matchBets.where((b) => b.isPending).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'DETALLE DEL ENCUENTRO',
          style: GoogleFonts.teko(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryOrange,
            letterSpacing: 1.5,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: PointsBadge(compact: true)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tarjeta principal del marcador con escudos Hero
              Card(
                color: AppTheme.cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Nombre del torneo y fuente
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              match.tournament.toUpperCase(),
                              style: GoogleFonts.barlowCondensed(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryOrange,
                                letterSpacing: 0.8,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildProviderBadge(),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Enfrentamiento central con Hero
                      Row(
                        children: [
                          // Equipo Local
                          Expanded(
                            child: Column(
                              children: [
                                _buildDetailLogo(
                                  logoUrl: match.homeLogo,
                                  teamName: match.homeTeam,
                                  isHome: true,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  match.homeTeam,
                                  style: GoogleFonts.barlowCondensed(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // Marcador o VS
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Column(
                              children: [
                                if (hasScores)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.background,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppTheme.primaryOrange,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Text(
                                      '${homeScore ?? 0} : ${awayScore ?? 0}',
                                      style: GoogleFonts.teko(
                                        fontSize: 34,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                else
                                  Text(
                                    'VS',
                                    style: GoogleFonts.teko(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: match.isLive
                                        ? AppTheme.primaryOrange.withValues(alpha: 0.2)
                                        : AppTheme.dividerColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: GoogleFonts.barlowCondensed(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: match.isLive
                                          ? AppTheme.primaryOrange
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Equipo Visitante
                          Expanded(
                            child: Column(
                              children: [
                                _buildDetailLogo(
                                  logoUrl: match.awayLogo,
                                  teamName: match.awayTeam,
                                  isHome: false,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  match.awayTeam,
                                  style: GoogleFonts.barlowCondensed(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Parciales por set si existen
              _buildPeriodsBreakdown(simulation),

              const SizedBox(height: 16),

              // Selector interactivo de cuotas colectivas
              Card(
                color: AppTheme.cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'CUOTAS DE VICTORIA (1X2)',
                            style: GoogleFonts.barlowCondensed(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryOrange,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            _isCancelled
                                ? 'APUESTAS CANCELADAS'
                                : (isFinished ? 'PARTIDO FINALIZADO' : 'CUOTA COLECTIVA'),
                            style: GoogleFonts.barlowCondensed(
                              fontSize: 12,
                              color: _isCancelled
                                  ? AppTheme.errorRed
                                  : AppTheme.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OddsButton(
                              label: '1 (Local)',
                              odds: match.homeOdds,
                              isSelected: _selectedTeamIndex == 0,
                              onPressed: (_isCancelled || simulation != null)
                                  ? null
                                  : () {
                                      setState(() {
                                        if (_selectedTeamIndex == 0) {
                                          _selectedTeam = null;
                                          _selectedTeamIndex = null;
                                        } else {
                                          _selectedTeam = match.homeTeam;
                                          _selectedTeamIndex = 0;
                                        }
                                      });
                                    },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OddsButton(
                              label: '2 (Visita)',
                              odds: match.awayOdds,
                              isSelected: _selectedTeamIndex == 1,
                              onPressed: (_isCancelled || simulation != null)
                                  ? null
                                  : () {
                                      setState(() {
                                        if (_selectedTeamIndex == 1) {
                                          _selectedTeam = null;
                                          _selectedTeamIndex = null;
                                        } else {
                                          _selectedTeam = match.awayTeam;
                                          _selectedTeamIndex = 1;
                                        }
                                      });
                                    },
                            ),
                          ),
                        ],
                      ),
                      if (_selectedTeam != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryOrange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.primaryOrange.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.sports_volleyball_rounded,
                                color: AppTheme.primaryOrange,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Pronóstico seleccionado: $_selectedTeam (Cuota: ${_selectedTeam == match.homeTeam ? match.homeOdds : match.awayOdds})',
                                  style: GoogleFonts.rajdhani(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Formulario de apuesta con validación (HU-03 / Requisito 6)
                        if (canBet)
                          BetForm(
                            key: ValueKey('bet-form-$_selectedTeam'),
                            availableBalance: betting.pointsBalance,
                            odds: _selectedTeam == match.homeTeam
                                ? match.homeOdds
                                : match.awayOdds,
                            onSubmit: (amount) => _placeBet(betting, amount),
                          )
                        else
                          Text(
                            match.isLive
                                ? 'Las apuestas se cierran al comenzar el partido.'
                                : 'Las apuestas están cerradas para este partido.',
                            style: GoogleFonts.rajdhani(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Apuestas del usuario en este partido y motor de simulación (HU-04)
              Card(
                color: AppTheme.cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'TUS APUESTAS EN ESTE PARTIDO',
                        style: GoogleFonts.barlowCondensed(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryOrange,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (matchBets.isEmpty)
                        Text(
                          'Aún no apuestas en este encuentro.',
                          style: GoogleFonts.rajdhani(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        )
                      else
                        for (final bet in matchBets)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              '${bet.selectedTeam} · ${bet.pointsStaked} pts @ '
                              '${bet.odds.toStringAsFixed(2)} · ${bet.status.label}'
                              '${bet.pointsWon > 0 ? ' (+${bet.pointsWon} pts)' : ''}',
                              style: GoogleFonts.rajdhani(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                      if (simulation != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Resultado simulado: ${simulation.winner} gana ${simulation.scoreLabel}',
                          style: GoogleFonts.rajdhani(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondaryOrange,
                          ),
                        ),
                      ] else if (!match.isFinished && !_isCancelled) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          icon: betting.isSimulating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primaryOrange,
                                  ),
                                )
                              : const Icon(Icons.fast_forward_rounded),
                          label: Text(
                            pendingBets.isEmpty
                                ? 'Simular Partido'
                                : 'Simular Partido (${pendingBets.length} pendiente(s))',
                          ),
                          onPressed: betting.isSimulating ? null : _openSimulation,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Información del partido
              Card(
                color: AppTheme.cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'INFORMACIÓN DEL ENCUENTRO',
                        style: GoogleFonts.barlowCondensed(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryOrange,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildInfoRow('ID del Partido', match.id),
                      _buildInfoRow('Fecha', _formatDateTime(match.matchDate)),
                      _buildInfoRow('Estado', statusLabel),
                      _buildInfoRow('Fuente', match.sourceProvider),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final l = dt.toLocal();
    final y = l.year.toString().padLeft(4, '0');
    final m = l.month.toString().padLeft(2, '0');
    final d = l.day.toString().padLeft(2, '0');
    final hh = l.hour.toString().padLeft(2, '0');
    final mm = l.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.rajdhani(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.rajdhani(
                fontSize: 14,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
