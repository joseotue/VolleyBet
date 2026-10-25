import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_profile.dart';
import '../../providers/betting_provider.dart';
import '../../services/supabase_service.dart';
import '../../widgets/ranking_row.dart';
import '../profile/profile_screen.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  late Future<List<UserProfile>> _rankingFuture;

  @override
  void initState() {
    super.initState();
    _rankingFuture = _loadRanking();
  }

  void _reloadRanking() {
    setState(() {
      _rankingFuture = _loadRanking();
    });
  }

  Future<List<UserProfile>> _loadRanking() async {
    final profiles = await SupabaseService.instance.getRankingProfiles();
    if (!mounted) return profiles;

    await context.read<BettingProvider>().unlockLeaderBadgeIfRankingLeader(
      profiles,
    );
    return profiles;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RANKING'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_rounded),
            tooltip: 'Ver perfil',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar ranking',
            onPressed: _reloadRanking,
          ),
        ],
      ),
      body: FutureBuilder<List<UserProfile>>(
        future: _rankingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final profiles = snapshot.data ?? [];

          final currentUserId = SupabaseService.instance.currentUserId;

          if (profiles.isEmpty) {
            return const Center(child: Text('No hay perfiles en el ranking'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index];

              return RankingRow(
                key: ValueKey('${profile.id}-${index + 1}'),
                position: index + 1,
                profile: profile,
                isCurrentUser: profile.id == currentUserId,
              );
            },
          );
        },
      ),
    );
  }
}
