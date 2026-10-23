import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/bet_model.dart';
import '../theme/app_theme.dart';

/// Tarjeta modular de una apuesta del historial (HU-03 / Requisito 8).
/// Las apuestas PENDING muestran las acciones Modificar, Cancelar y Simular.
class BetCard extends StatelessWidget {
  final BetModel bet;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;
  final VoidCallback? onSimulate;

  const BetCard({
    super.key,
    required this.bet,
    this.onEdit,
    this.onCancel,
    this.onSimulate,
  });

  Color get _statusColor {
    switch (bet.status) {
      case BetStatus.pending:
        return AppTheme.primaryOrange;
      case BetStatus.won:
        return AppTheme.successGreen;
      case BetStatus.lost:
        return AppTheme.errorRed;
      case BetStatus.cancelled:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    bet.matchLabel,
                    style: GoogleFonts.barlowCondensed(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withValues(alpha: 0.6)),
                  ),
                  child: Text(
                    bet.status.label,
                    style: GoogleFonts.barlowCondensed(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Pronóstico: ${bet.selectedTeam} @ ${bet.odds.toStringAsFixed(2)}',
              style: GoogleFonts.rajdhani(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _amountLine,
              style: GoogleFonts.rajdhani(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            if (bet.isPending) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Modificar Apuesta'),
                    onPressed: onEdit,
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Cancelar Apuesta'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorRed,
                      side: const BorderSide(color: AppTheme.errorRed, width: 1.5),
                    ),
                    onPressed: onCancel,
                  ),
                  if (onSimulate != null)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.fast_forward_rounded, size: 18),
                      label: const Text('Simular Partido'),
                      onPressed: onSimulate,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String get _amountLine {
    switch (bet.status) {
      case BetStatus.pending:
        return 'Apostado: ${bet.pointsStaked} pts · Premio potencial: ${bet.potentialPayout} pts';
      case BetStatus.won:
        return 'Apostado: ${bet.pointsStaked} pts · Ganaste: +${bet.pointsWon} pts';
      case BetStatus.lost:
        return 'Apostado: ${bet.pointsStaked} pts · Ganancia: 0 pts';
      case BetStatus.cancelled:
        return 'Apostado: ${bet.pointsStaked} pts · Reembolsado';
    }
  }
}
