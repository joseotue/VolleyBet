import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/betting_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/badge_tile.dart';
import '../../widgets/points_badge.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final betting = context.watch<BettingProvider>();
    final username = betting.username ?? 'Usuario';
    final unlockedBadges = betting.badges.toSet();
    final badgeDefinitions = [
      const _BadgeDefinition(
        name: BettingProvider.juniorBadge,
        description: 'Completa una trivia perfecta de voleibol.',
        icon: Icons.school_rounded,
      ),
      const _BadgeDefinition(
        name: BettingProvider.sniperBadge,
        description: 'Acierta tres apuestas consecutivas.',
        icon: Icons.gps_fixed_rounded,
      ),
      const _BadgeDefinition(
        name: BettingProvider.leaderBadge,
        description: 'Alcanza el primer lugar del ranking.',
        icon: Icons.emoji_events_rounded,
      ),
    ];
    final unlockedCount = badgeDefinitions
        .where((badge) => unlockedBadges.contains(badge.name))
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MI PERFIL'),
        actions: [
          IconButton(
            tooltip: 'Actualizar perfil',
            onPressed: betting.isLoading ? null : betting.loadUserData,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: betting.loadUserData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: AppTheme.primaryOrange.withValues(
                        alpha: 0.18,
                      ),
                      child: Text(
                        username.isEmpty ? 'V' : username[0].toUpperCase(),
                        style: GoogleFonts.teko(
                          color: AppTheme.primaryOrange,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      username,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    const PointsBadge(),
                  ],
                ),
              ),
            ),
            if (betting.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                betting.errorMessage!,
                style: const TextStyle(color: AppTheme.errorRed),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'INSIGNIAS',
                  style: GoogleFonts.teko(
                    color: AppTheme.primaryOrange,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  '$unlockedCount DE ${badgeDefinitions.length}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final badge in badgeDefinitions)
              BadgeTile(
                title: badge.name,
                description: badge.description,
                icon: badge.icon,
                unlocked: unlockedBadges.contains(badge.name),
              ),
          ],
        ),
      ),
    );
  }
}

class _BadgeDefinition {
  final String name;
  final String description;
  final IconData icon;

  const _BadgeDefinition({
    required this.name,
    required this.description,
    required this.icon,
  });
}
