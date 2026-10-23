import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/bet_model.dart';
import '../providers/betting_provider.dart';
import '../theme/app_theme.dart';

/// Diálogo de control del motor de simulación acelerada (HU-04 / CAP-4).
/// Confirma, ejecuta la simulación vía `BettingProvider`, revela set a set el
/// marcador y resume la liquidación de las apuestas.
class SimulationControlDialog extends StatefulWidget {
  final String matchId;
  final String homeTeam;
  final String awayTeam;
  final Future<SimulationOutcome> Function(BettingProvider provider) runSimulation;
  final Duration revealInterval;

  const SimulationControlDialog({
    super.key,
    required this.matchId,
    required this.homeTeam,
    required this.awayTeam,
    required this.runSimulation,
    this.revealInterval = const Duration(milliseconds: 450),
  });

  static Future<SimulationOutcome?> show(
    BuildContext context, {
    required String matchId,
    required String homeTeam,
    required String awayTeam,
    required Future<SimulationOutcome> Function(BettingProvider provider) runSimulation,
  }) {
    return showDialog<SimulationOutcome>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SimulationControlDialog(
        matchId: matchId,
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        runSimulation: runSimulation,
      ),
    );
  }

  @override
  State<SimulationControlDialog> createState() => _SimulationControlDialogState();
}

class _SimulationControlDialogState extends State<SimulationControlDialog> {
  SimulationOutcome? _outcome;
  String? _error;
  bool _running = false;
  int _revealedSets = 0;
  Timer? _revealTimer;

  @override
  void dispose() {
    _revealTimer?.cancel();
    super.dispose();
  }

  Future<void> _run() async {
    setState(() {
      _running = true;
      _error = null;
    });
    try {
      final outcome = await widget.runSimulation(context.read<BettingProvider>());
      if (!mounted) return;
      setState(() {
        _outcome = outcome;
        _running = false;
        _revealedSets = 0;
      });
      _startReveal(outcome.result.sets.length);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _running = false;
        _error = BettingProvider.describeError(e);
      });
    }
  }

  void _startReveal(int totalSets) {
    _revealTimer = Timer.periodic(widget.revealInterval, (timer) {
      if (!mounted || _revealedSets >= totalSets) {
        timer.cancel();
        return;
      }
      setState(() => _revealedSets++);
    });
  }

  bool get _revealDone =>
      _outcome != null && _revealedSets >= _outcome!.result.sets.length;

  @override
  Widget build(BuildContext context) {
    final pendingCount = context
        .watch<BettingProvider>()
        .pendingBetsForMatch(widget.matchId)
        .length;

    return AlertDialog(
      backgroundColor: AppTheme.cardColor,
      title: Text(
        'SIMULACIÓN ACELERADA',
        style: GoogleFonts.teko(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryOrange,
          letterSpacing: 1.2,
        ),
      ),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${widget.homeTeam} vs ${widget.awayTeam}',
                textAlign: TextAlign.center,
                style: GoogleFonts.barlowCondensed(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              if (_outcome == null && !_running)
                Text(
                  pendingCount > 0
                      ? 'Se simulará el partido completo y se liquidarán tus $pendingCount apuesta(s) pendiente(s).'
                      : 'No tienes apuestas pendientes en este partido. Igual puedes simular el resultado.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.rajdhani(fontSize: 15, color: AppTheme.textSecondary),
                ),
              if (_running) ...[
                const SizedBox(height: 8),
                const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryOrange),
                ),
                const SizedBox(height: 12),
                Text(
                  'Jugando el partido...',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.rajdhani(fontSize: 15, color: AppTheme.textSecondary),
                ),
              ],
              if (_outcome != null) _buildOutcome(_outcome!),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.rajdhani(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.errorRed,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (_outcome == null && !_running)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        if (_outcome == null)
          ElevatedButton.icon(
            icon: const Icon(Icons.fast_forward_rounded),
            label: Text(_error != null ? 'REINTENTAR' : 'SIMULAR PARTIDO'),
            onPressed: _running ? null : _run,
          ),
        if (_outcome != null)
          ElevatedButton(
            onPressed: _revealDone ? () => Navigator.of(context).pop(_outcome) : null,
            child: const Text('LISTO'),
          ),
      ],
    );
  }

  Widget _buildOutcome(SimulationOutcome outcome) {
    final result = outcome.result;
    final visibleSets = result.sets.take(_revealedSets).toList();
    final homeSets = visibleSets.where((s) => s.homeWon).length;
    final awaySets = visibleSets.length - homeSets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(
            '$homeSets - $awaySets',
            style: GoogleFonts.teko(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            for (var i = 0; i < visibleSets.length; i++)
              Chip(
                label: Text('Set ${i + 1}: ${visibleSets[i]}'),
                backgroundColor: AppTheme.background,
                side: const BorderSide(color: AppTheme.dividerColor),
              ),
          ],
        ),
        if (_revealDone) ...[
          const SizedBox(height: 12),
          Text(
            'GANADOR: ${result.winner.toUpperCase()} (${result.scoreLabel})',
            textAlign: TextAlign.center,
            style: GoogleFonts.barlowCondensed(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryOrange,
            ),
          ),
          const SizedBox(height: 8),
          if (outcome.settledBets.isEmpty)
            Text(
              'Sin apuestas que liquidar.',
              textAlign: TextAlign.center,
              style: GoogleFonts.rajdhani(fontSize: 14, color: AppTheme.textSecondary),
            )
          else
            for (final bet in outcome.settledBets)
              Text(
                bet.status == BetStatus.won
                    ? '✓ ${bet.selectedTeam}: GANADA +${bet.pointsWon} pts'
                    : '✗ ${bet.selectedTeam}: PERDIDA (0 pts)',
                textAlign: TextAlign.center,
                style: GoogleFonts.rajdhani(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: bet.status == BetStatus.won
                      ? AppTheme.successGreen
                      : AppTheme.errorRed,
                ),
              ),
          if (outcome.sniperUnlocked) ...[
            const SizedBox(height: 10),
            Text(
              '🎯 ¡Insignia "Francotirador" desbloqueada! 3 aciertos seguidos.',
              textAlign: TextAlign.center,
              style: GoogleFonts.rajdhani(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.secondaryOrange,
              ),
            ),
          ],
        ],
      ],
    );
  }
}
