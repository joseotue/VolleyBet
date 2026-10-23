import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/betting_provider.dart';
import '../theme/app_theme.dart';

/// Insignia de saldo de puntos reactiva (HU-04 / Requisito 7).
/// Escucha `BettingProvider` con `context.watch` y se redibuja con cada
/// `notifyListeners()` al apostar, cancelar o cobrar premios.
class PointsBadge extends StatelessWidget {
  /// Versión compacta para el AppBar.
  final bool compact;

  const PointsBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final betting = context.watch<BettingProvider>();
    final label = compact
        ? '${betting.pointsBalance} PTS'
        : '${betting.pointsBalance} PTS VIRTUALES';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 18,
        vertical: compact ? 4 : 10,
      ),
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
          Icon(
            Icons.monetization_on_rounded,
            color: AppTheme.primaryOrange,
            size: compact ? 18 : 22,
          ),
          SizedBox(width: compact ? 4 : 8),
          if (betting.isLoading && betting.bets.isEmpty)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryOrange,
              ),
            )
          else
            Text(
              label,
              style: GoogleFonts.barlowCondensed(
                fontSize: compact ? 15 : 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryOrange,
                letterSpacing: 1,
              ),
            ),
        ],
      ),
    );
  }
}
