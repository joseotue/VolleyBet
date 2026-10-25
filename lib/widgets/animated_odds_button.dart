import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Botón de cuota con rebote al presionar y transición de color al seleccionar.
class AnimatedOddsButton extends StatefulWidget {
  final String label;
  final double odds;
  final bool isSelected;
  final VoidCallback? onPressed;

  const AnimatedOddsButton({
    super.key,
    required this.label,
    required this.odds,
    this.isSelected = false,
    this.onPressed,
  });

  @override
  State<AnimatedOddsButton> createState() => _AnimatedOddsButtonState();
}

class _AnimatedOddsButtonState extends State<AnimatedOddsButton> {
  bool _isPressed = false;

  void _handleHighlight(bool isHighlighted) {
    if (!mounted) return;
    setState(() {
      _isPressed = isHighlighted && widget.onPressed != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;
    final borderColor = widget.isSelected
        ? AppTheme.primaryOrange
        : AppTheme.dividerColor;
    final backgroundColor = widget.isSelected
        ? AppTheme.primaryOrange.withValues(alpha: 0.18)
        : const Color(0xFF202532);

    return Opacity(
      opacity: isEnabled ? 1 : 0.5,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: widget.isSelected ? 2 : 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              onHighlightChanged: _handleHighlight,
              borderRadius: BorderRadius.circular(10),
              splashColor: AppTheme.primaryOrange.withValues(alpha: 0.3),
              highlightColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label.toUpperCase(),
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.isSelected
                            ? AppTheme.primaryOrange
                            : AppTheme.textSecondary,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.odds.toStringAsFixed(2),
                      style: GoogleFonts.teko(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: widget.isSelected
                            ? Colors.white
                            : AppTheme.primaryOrange,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
