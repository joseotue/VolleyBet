// Modelo de datos para un Partido de Voleibol en VolleyBet (HU-02).
// Soporta deserialización desde API-Sports, Sportradar Volleyball v2 y mock local.

class MatchScores {
  final int? home;
  final int? away;
  final Map<String, dynamic>? periods;

  const MatchScores({
    this.home,
    this.away,
    this.periods,
  });

  factory MatchScores.fromJson(Map<String, dynamic> json) {
    return MatchScores(
      home: _parseScore(json['home']),
      away: _parseScore(json['away']),
      periods: json['periods'] is Map
          ? Map<String, dynamic>.from(json['periods'] as Map)
          : null,
    );
  }

  static int? _parseScore(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    return int.tryParse(val.toString());
  }

  Map<String, dynamic> toJson() => {
        'home': home,
        'away': away,
        if (periods != null) 'periods': periods,
      };
}

class MatchModel {
  final String id;
  final String tournament;
  final String homeTeam;
  final String awayTeam;
  final String? homeLogo;
  final String? awayLogo;
  final double homeOdds;
  final double awayOdds;
  final DateTime matchDate;
  final String status;
  final MatchScores? scores;
  final String sourceProvider;

  const MatchModel({
    required this.id,
    required this.tournament,
    required this.homeTeam,
    required this.awayTeam,
    this.homeLogo,
    this.awayLogo,
    required this.homeOdds,
    required this.awayOdds,
    required this.matchDate,
    required this.status,
    this.scores,
    required this.sourceProvider,
  });

  /// Tag requerido para la animación Hero en escudos:
  /// `team-logo-${match.id}-${isHome ? 'home' : 'away'}` (Requisito 4)
  String heroTagFor({required bool isHome}) =>
      'team-logo-${id.isEmpty ? identityHashCode(this).toString() : id}-${isHome ? 'home' : 'away'}';

  String get homeHeroTag => heroTagFor(isHome: true);
  String get awayHeroTag => heroTagFor(isHome: false);

  bool get isLive {
    final s = status.toUpperCase();
    return s == 'S1' ||
        s == 'S2' ||
        s == 'S3' ||
        s == 'S4' ||
        s == 'S5' ||
        s == 'LIVE' ||
        s == 'STARTED' ||
        s == 'IN_PROGRESS';
  }

  bool get isFinished {
    final s = status.toUpperCase();
    return s == 'FT' ||
        s == 'AET' ||
        s == 'AW' ||
        s == 'FINISHED' ||
        s == 'ENDED' ||
        s == 'CLOSED';
  }

  String get statusDisplay {
    final s = status.toUpperCase();
    if (isLive) {
      if (s.startsWith('S') && s.length == 2) {
        return 'SET ${s[1]} (EN VIVO)';
      }
      return 'EN VIVO';
    }
    if (isFinished) return 'FINALIZADO';
    if (s == 'NS' || s == 'NOT_STARTED') return 'POR JUGAR';
    if (s == 'CANC' || s == 'CANCELLED') return 'CANCELADO';
    if (s == 'POSTPONED') return 'POSPUESTO';
    if (s == 'SUSPENDED') return 'SUSPENDIDO';
    if (s == 'DELAYED') return 'RETRASADO';
    if (s == 'INTERRUPTED') return 'INTERRUMPIDO';
    return status;
  }

  /// Generador determinista de cuotas para equipos cuando la API no las suministre.
  static (double, double) generateDeterministicOdds(
    String id,
    String homeTeam,
    String awayTeam,
  ) {
    final combined = '$id-$homeTeam-$awayTeam';
    var hash = 0;
    for (var i = 0; i < combined.length; i++) {
      hash = (31 * hash + combined.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    // Determina cuota local entre 1.30 y 2.90
    final hVal = 1.30 + ((hash % 160) / 100.0);
    final impliedHomeProb = 1.0 / hVal;
    const targetMargin = 1.08;
    final impliedAwayProb = (targetMargin - impliedHomeProb).clamp(0.25, 0.75);
    final aVal = 1.0 / impliedAwayProb;

    final homeOdds = double.parse(hVal.toStringAsFixed(2));
    final awayOdds = double.parse(aVal.toStringAsFixed(2));
    return (homeOdds, awayOdds);
  }

  /// Deserializador para API-Sports (`https://v1.volleyball.api-sports.io`)
  factory MatchModel.fromApiSports(
    Map<String, dynamic> json, {
    String source = 'api-sports',
  }) {
    final rawId = json['id']?.toString() ?? '';
    final leagueMap =
        json['league'] is Map ? json['league'] as Map<String, dynamic> : null;
    final tournament =
        leagueMap?['name']?.toString() ?? 'Voleibol Internacional';

    final teamsMap =
        json['teams'] is Map ? json['teams'] as Map<String, dynamic> : null;
    final homeTeamMap = teamsMap?['home'] is Map
        ? teamsMap!['home'] as Map<String, dynamic>
        : null;
    final awayTeamMap = teamsMap?['away'] is Map
        ? teamsMap!['away'] as Map<String, dynamic>
        : null;

    final homeTeam = homeTeamMap?['name']?.toString() ?? 'Local';
    final awayTeam = awayTeamMap?['name']?.toString() ?? 'Visitante';
    final homeLogo = homeTeamMap?['logo']?.toString();
    final awayLogo = awayTeamMap?['logo']?.toString();

    final statusMap =
        json['status'] is Map ? json['status'] as Map<String, dynamic> : null;
    final status = statusMap?['short']?.toString() ??
        statusMap?['long']?.toString() ??
        json['status']?.toString() ??
        'NS';

    DateTime date;
    try {
      date = json['date'] != null
          ? DateTime.parse(json['date'].toString())
          : DateTime.now();
    } catch (_) {
      date = DateTime.now();
    }

    MatchScores? scores;
    if (json['scores'] is Map) {
      final scoresMap = Map<String, dynamic>.from(json['scores'] as Map);
      if (json['periods'] is Map) {
        scoresMap['periods'] = json['periods'];
      }
      scores = MatchScores.fromJson(scoresMap);
    }

    double? hOdds;
    double? aOdds;
    if (json['homeOdds'] != null) {
      hOdds = double.tryParse(json['homeOdds'].toString());
    }
    if (json['awayOdds'] != null) {
      aOdds = double.tryParse(json['awayOdds'].toString());
    }

    if (hOdds == null || aOdds == null) {
      final (calcH, calcA) =
          generateDeterministicOdds(rawId, homeTeam, awayTeam);
      hOdds = calcH;
      aOdds = calcA;
    }

    return MatchModel(
      id: rawId,
      tournament: tournament,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      homeLogo: homeLogo,
      awayLogo: awayLogo,
      homeOdds: hOdds,
      awayOdds: aOdds,
      matchDate: date,
      status: status,
      scores: scores,
      sourceProvider: source,
    );
  }

  /// Deserializador para Sportradar Volleyball v2
  factory MatchModel.fromSportradar(
    Map<String, dynamic> json, {
    String source = 'sportradar',
  }) {
    final sportEvent = json['sport_event'] is Map
        ? json['sport_event'] as Map<String, dynamic>
        : json;
    final statusObj = json['sport_event_status'] is Map
        ? json['sport_event_status'] as Map<String, dynamic>
        : null;

    final rawId =
        sportEvent['id']?.toString() ?? json['id']?.toString() ?? '';
    final contextMap = sportEvent['sport_event_context'] is Map
        ? sportEvent['sport_event_context'] as Map<String, dynamic>
        : null;
    final compMap = contextMap?['competition'] is Map
        ? contextMap!['competition'] as Map<String, dynamic>
        : null;
    final tournament =
        compMap?['name']?.toString() ?? 'Sportradar Volleyball';

    String homeTeam = 'Local';
    String awayTeam = 'Visitante';
    String? homeLogo;
    String? awayLogo;

    final competitors = sportEvent['competitors'] is List
        ? sportEvent['competitors'] as List
        : null;
    if (competitors != null && competitors.isNotEmpty) {
      for (final comp in competitors) {
        if (comp is Map) {
          final qualifier = comp['qualifier']?.toString();
          final name = comp['name']?.toString() ?? 'Equipo';
          if (qualifier == 'home') {
            homeTeam = name;
          } else if (qualifier == 'away') {
            awayTeam = name;
          }
        }
      }
      if (homeTeam == 'Local' && competitors.isNotEmpty && competitors[0] is Map) {
        homeTeam = competitors[0]['name']?.toString() ?? 'Local';
      }
      if (awayTeam == 'Visitante' &&
          competitors.length > 1 &&
          competitors[1] is Map) {
        awayTeam = competitors[1]['name']?.toString() ?? 'Visitante';
      }
    }

    final status = statusObj?['status']?.toString() ?? 'not_started';
    final homeScore = statusObj?['home_score'] is int
        ? statusObj!['home_score'] as int
        : int.tryParse('${statusObj?['home_score']}');
    final awayScore = statusObj?['away_score'] is int
        ? statusObj!['away_score'] as int
        : int.tryParse('${statusObj?['away_score']}');

    final periodScores = statusObj?['period_scores'] is List
        ? statusObj!['period_scores'] as List
        : null;
    Map<String, dynamic>? periodsMap;
    if (periodScores != null && periodScores.isNotEmpty) {
      final periodKeys = ['first', 'second', 'third', 'fourth', 'fifth'];
      periodsMap = {};
      for (var i = 0; i < periodScores.length; i++) {
        final ps = periodScores[i];
        if (ps is Map) {
          final key = i < periodKeys.length ? periodKeys[i] : 'period_${i + 1}';
          periodsMap[key] = {
            'home': ps['home_score'] is int ? ps['home_score'] as int : int.tryParse('${ps['home_score']}'),
            'away': ps['away_score'] is int ? ps['away_score'] as int : int.tryParse('${ps['away_score']}'),
          };
        }
      }
    }

    final scores = (homeScore != null || awayScore != null || periodsMap != null)
        ? MatchScores(
            home: homeScore,
            away: awayScore,
            periods: periodsMap,
          )
        : null;

    DateTime date;
    try {
      final dateStr =
          sportEvent['start_time'] ?? json['start_time'] ?? json['date'];
      date =
          dateStr != null ? DateTime.parse(dateStr.toString()) : DateTime.now();
    } catch (_) {
      date = DateTime.now();
    }

    final (calcH, calcA) = generateDeterministicOdds(rawId, homeTeam, awayTeam);

    return MatchModel(
      id: rawId,
      tournament: tournament,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      homeLogo: homeLogo,
      awayLogo: awayLogo,
      homeOdds: calcH,
      awayOdds: calcA,
      matchDate: date,
      status: status,
      scores: scores,
      sourceProvider: source,
    );
  }

  /// Deserializador flexible general
  factory MatchModel.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('sport_event')) {
      return MatchModel.fromSportradar(json);
    }
    if (json.containsKey('teams') || json.containsKey('league')) {
      return MatchModel.fromApiSports(
        json,
        source: json['sourceProvider']?.toString() ?? 'api-sports',
      );
    }

    final rawId = json['id']?.toString() ?? '';
    final homeTeam = json['homeTeam']?.toString() ?? 'Local';
    final awayTeam = json['awayTeam']?.toString() ?? 'Visitante';

    double? hOdds = json['homeOdds'] != null
        ? double.tryParse(json['homeOdds'].toString())
        : null;
    double? aOdds = json['awayOdds'] != null
        ? double.tryParse(json['awayOdds'].toString())
        : null;

    if (hOdds == null || aOdds == null) {
      final (calcH, calcA) =
          generateDeterministicOdds(rawId, homeTeam, awayTeam);
      hOdds = calcH;
      aOdds = calcA;
    }

    return MatchModel(
      id: rawId,
      tournament: json['tournament']?.toString() ?? 'Voleibol',
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      homeLogo: json['homeLogo']?.toString(),
      awayLogo: json['awayLogo']?.toString(),
      homeOdds: hOdds,
      awayOdds: aOdds,
      matchDate: json['matchDate'] != null
          ? DateTime.tryParse(json['matchDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: json['status']?.toString() ?? 'NS',
      scores: json['scores'] is Map
          ? MatchScores.fromJson(Map<String, dynamic>.from(json['scores'] as Map))
          : null,
      sourceProvider: json['sourceProvider']?.toString() ?? 'api-sports',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tournament': tournament,
        'homeTeam': homeTeam,
        'awayTeam': awayTeam,
        'homeLogo': homeLogo,
        'awayLogo': awayLogo,
        'homeOdds': homeOdds,
        'awayOdds': awayOdds,
        'matchDate': matchDate.toIso8601String(),
        'status': status,
        'scores': scores?.toJson(),
        'sourceProvider': sourceProvider,
      };
}
