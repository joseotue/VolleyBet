import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../services/supabase_service.dart';
import '../../widgets/ranking_row.dart';

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
    _rankingFuture = SupabaseService.instance.getRankingProfiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RANKING')),
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
