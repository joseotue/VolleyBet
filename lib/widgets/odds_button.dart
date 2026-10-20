import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Botón modular reutilizable de cuota deportiva con estética Anime M3 (HU-02 / Requisito 8).
/// Modela exclusivamente cuotas colectivas de equipo (victoria local o visitante).
class OddsButton extends StatelessWidget {
  final String label;
  final double odds;
  final bool isSelected;
  final VoidCallback? onPressed;

  const OddsButton({
    super.key,
    required this.label,
    required this.odds,
    this.isSelected = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    final borderColor = isSelected
        ? AppTheme.primaryOrange
        : AppTheme.dividerColor;
    final backgroundColor = isSelected
        ? AppTheme.primaryOrange.withValues(alpha: 0.18)
        : const Color(0xFF202532);

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          splashColor: AppTheme.primaryOrange.withValues(alpha: 0.3),
          highlightColor: AppTheme.primaryOrange.withValues(alpha: 0.1),
          child: Ink(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: borderColor,
                width: isSelected ? 2.0 : 1.0,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppTheme.primaryOrange : AppTheme.textSecondary,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  odds.toStringAsFixed(2),
                  style: GoogleFonts.teko(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppTheme.primaryOrange,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
