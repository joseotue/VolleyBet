/// Estados posibles de una apuesta en la tabla `bets` (HU-03).
enum BetStatus {
  pending('PENDING'),
  won('WON'),
  lost('LOST'),
  cancelled('CANCELLED');

  final String value;
  const BetStatus(this.value);

  static BetStatus fromValue(String? value) {
    final upper = value?.toUpperCase();
    return BetStatus.values.firstWhere(
      (s) => s.value == upper,
      orElse: () => BetStatus.pending,
    );
  }

  String get label {
    switch (this) {
      case BetStatus.pending:
        return 'PENDIENTE';
      case BetStatus.won:
        return 'GANADA';
      case BetStatus.lost:
        return 'PERDIDA';
      case BetStatus.cancelled:
        return 'CANCELADA';
    }
  }
}

/// Modelo de un pronóstico/apuesta del usuario en Supabase (HU-03 / Requisito 5).
class BetModel {
  final String id;
  final String userId;
  final String matchId;
  final String selectedTeam;
  final String? homeTeam;
  final String? awayTeam;
  final double odds;
  final int pointsStaked;
  final BetStatus status;
  final int pointsWon;
  final DateTime? createdAt;
  final DateTime? settledAt;

  const BetModel({
    required this.id,
    required this.userId,
    required this.matchId,
    required this.selectedTeam,
    this.homeTeam,
    this.awayTeam,
    required this.odds,
    required this.pointsStaked,
    this.status = BetStatus.pending,
    this.pointsWon = 0,
    this.createdAt,
    this.settledAt,
  });

  bool get isPending => status == BetStatus.pending;

  /// Premio potencial si el pronóstico acierta (monto * cuota).
  int get potentialPayout => (pointsStaked * odds).round();

  /// Texto "Local vs Visitante" para listas e historial.
  String get matchLabel {
    if (homeTeam != null && awayTeam != null) return '$homeTeam vs $awayTeam';
    return 'Partido #$matchId';
  }

  /// Equipo rival al pronosticado, si se conoce el enfrentamiento.
  String? get opponentTeam {
    if (homeTeam == null || awayTeam == null) return null;
    return selectedTeam == homeTeam ? awayTeam : homeTeam;
  }

  factory BetModel.fromJson(Map<String, dynamic> json) {
    return BetModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      matchId: json['match_id']?.toString() ?? '',
      selectedTeam: json['selected_team']?.toString() ?? '',
      homeTeam: json['home_team']?.toString(),
      awayTeam: json['away_team']?.toString(),
      odds: (json['odds'] is num)
          ? (json['odds'] as num).toDouble()
          : double.tryParse('${json['odds']}') ?? 1.0,
      pointsStaked: (json['points_staked'] as num?)?.toInt() ?? 0,
      status: BetStatus.fromValue(json['status']?.toString()),
      pointsWon: (json['points_won'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      settledAt: json['settled_at'] != null
          ? DateTime.tryParse(json['settled_at'].toString())
          : null,
    );
  }

  /// Campos que el cliente envía al crear la apuesta. `user_id` y `status`
  /// se fijan explícitamente para que la política RLS los verifique.
  Map<String, dynamic> toInsertJson() => {
        'user_id': userId,
        'match_id': matchId,
        'selected_team': selectedTeam,
        'home_team': homeTeam,
        'away_team': awayTeam,
        'odds': odds,
        'points_staked': pointsStaked,
        'status': BetStatus.pending.value,
      };

  BetModel copyWith({
    int? pointsStaked,
    BetStatus? status,
    int? pointsWon,
    DateTime? settledAt,
  }) {
    return BetModel(
      id: id,
      userId: userId,
      matchId: matchId,
      selectedTeam: selectedTeam,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      odds: odds,
      pointsStaked: pointsStaked ?? this.pointsStaked,
      status: status ?? this.status,
      pointsWon: pointsWon ?? this.pointsWon,
      createdAt: createdAt,
      settledAt: settledAt ?? this.settledAt,
    );
  }
}
