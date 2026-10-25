import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BadgeTile extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool unlocked;

  const BadgeTile({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = unlocked
        ? AppTheme.primaryOrange
        : AppTheme.textSecondary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unlocked
            ? AppTheme.primaryOrange.withValues(alpha: 0.12)
            : AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: unlocked ? AppTheme.primaryOrange : AppTheme.dividerColor,
          width: unlocked ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              Icon(
                unlocked
                    ? Icons.check_circle_rounded
                    : Icons.lock_outline_rounded,
                color: accentColor,
              ),
              const SizedBox(height: 4),
              Text(
                unlocked ? 'DESBLOQUEADA' : 'BLOQUEADA',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: accentColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
