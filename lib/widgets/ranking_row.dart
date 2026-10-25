import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../theme/app_theme.dart';

class RankingRow extends StatelessWidget {
  final int position;
  final UserProfile profile;
  final bool isCurrentUser;

  const RankingRow({
    super.key,
    required this.position,
    required this.profile,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + (position * 90)),
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) {
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(32 * (1 - progress), 0),
            child: child,
          ),
        );
      },
      child: Card(
        color: isCurrentUser
            ? AppTheme.primaryOrange.withValues(alpha: 0.18)
            : AppTheme.cardColor,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.primaryOrange,
            child: Text('$position'),
          ),
          title: Text(profile.username),
          subtitle: isCurrentUser ? const Text('TÚ') : null,
          trailing: Text('${profile.pointsBalance} pts'),
        ),
      ),
    );
  }
}
