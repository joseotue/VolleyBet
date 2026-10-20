import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/match_model.dart';
import '../screens/matches/match_detail_screen.dart';
import '../theme/app_theme.dart';
import 'odds_button.dart';

/// Tarjeta modular de partido de voleibol con estética Anime M3 (HU-02 / Requisito 8).
/// Incluye animación Hero en los escudos (Requisito 4) y navegación al detalle por constructor (Requisito 3).
class MatchCard extends StatelessWidget {
  final MatchModel match;
  final VoidCallback? onTap;

  const MatchCard({
    super.key,
    required this.match,
    this.onTap,
  });

  Widget _buildTeamLogo({required String? logoUrl, required String teamName, required bool isHome}) {
    final heroTag = match.heroTagFor(isHome: isHome);
    final initials = teamName.isNotEmpty ? teamName.substring(0, 1).toUpperCase() : '?';

    Widget avatarFallback = CircleAvatar(
      radius: 22,
      backgroundColor: AppTheme.background,
      child: Text(
        initials,
        style: GoogleFonts.teko(
          fontSize: 20,
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
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF1E2330),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.primaryOrange.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: (logoUrl != null && logoUrl.startsWith('http'))
              ? Image.network(
                  logoUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => avatarFallback,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryOrange,
                        ),
                      ),
                    );
                  },
                )
              : avatarFallback,
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color badgeColor = AppTheme.textSecondary;
    Color textColor = Colors.white;

    if (match.isLive) {
      badgeColor = AppTheme.primaryOrange;
    } else if (match.isFinished) {
      badgeColor = AppTheme.successGreen;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (match.isLive) ...[
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppTheme.primaryOrange,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            match.statusDisplay,
            style: GoogleFonts.barlowCondensed(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scores = match.scores;
    final hasScores = scores != null && (scores.home != null || scores.away != null);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.dividerColor),
      ),
      child: InkWell(
        onTap: onTap ??
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MatchDetailScreen(match: match),
                ),
              );
            },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabecera: Torneo y Estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.sports_volleyball_rounded,
                          size: 16,
                          color: AppTheme.primaryOrange,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            match.tournament.toUpperCase(),
                            style: GoogleFonts.barlowCondensed(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryOrange,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(),
                ],
              ),

              const SizedBox(height: 14),

              // Cuerpo: Equipos y Marcador
              Row(
                children: [
                  // Equipo Local
                  Expanded(
                    child: Column(
                      children: [
                        _buildTeamLogo(
                          logoUrl: match.homeLogo,
                          teamName: match.homeTeam,
                          isHome: true,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          match.homeTeam,
                          style: GoogleFonts.barlowCondensed(
                            fontSize: 16,
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

                  // Marcador central o VS
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasScores)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B1F29),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.primaryOrange.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              '${scores.home ?? 0} - ${scores.away ?? 0}',
                              style: GoogleFonts.teko(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          )
                        else
                          Text(
                            'VS',
                            style: GoogleFonts.teko(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          '${match.matchDate.toLocal().hour.toString().padLeft(2, '0')}:${match.matchDate.toLocal().minute.toString().padLeft(2, '0')} HRS',
                          style: GoogleFonts.rajdhani(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Equipo Visitante
                  Expanded(
                    child: Column(
                      children: [
                        _buildTeamLogo(
                          logoUrl: match.awayLogo,
                          teamName: match.awayTeam,
                          isHome: false,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          match.awayTeam,
                          style: GoogleFonts.barlowCondensed(
                            fontSize: 16,
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

              const SizedBox(height: 16),
              const Divider(color: AppTheme.dividerColor, height: 1),
              const SizedBox(height: 12),

              // Botones de Cuotas Colectivas
              Row(
                children: [
                  Expanded(
                    child: OddsButton(
                      label: '1 (Local)',
                      odds: match.homeOdds,
                      onPressed: (match.status == 'CANC' || match.status == 'CANCELLED')
                          ? null
                          : () {
                              // Al tocar cuota, navega al detalle preseleccionando el equipo local
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MatchDetailScreen(
                                    match: match,
                                    initialSelectedTeam: match.homeTeam,
                                  ),
                                ),
                              );
                            },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OddsButton(
                      label: '2 (Visita)',
                      odds: match.awayOdds,
                      onPressed: (match.status == 'CANC' || match.status == 'CANCELLED')
                          ? null
                          : () {
                              // Al tocar cuota, navega al detalle preseleccionando el equipo visitante
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MatchDetailScreen(
                                    match: match,
                                    initialSelectedTeam: match.awayTeam,
                                  ),
                                ),
                              );
                            },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
