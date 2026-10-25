import 'package:flutter/material.dart';

import 'animated_odds_button.dart';

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
    return AnimatedOddsButton(
      label: label,
      odds: odds,
      isSelected: isSelected,
      onPressed: onPressed,
    );
  }
}
