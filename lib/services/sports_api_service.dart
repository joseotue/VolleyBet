import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/match_model.dart';

class _CacheEntry {
  final List<MatchModel> matches;
  final DateTime timestamp;
  final String source;

  _CacheEntry({
    required this.matches,
    required this.timestamp,
    required this.source,
  });
}

/// Servicio deportivo unificado con Dio, caché en memoria indexada por fecha (TTL 15 min),
/// failover jerárquico dual (API-Sports -> Sportradar) y respaldo local (HU-02).
class SportsApiService {
  static SportsApiService? _instance;
  static SportsApiService get instance => _instance ??= SportsApiService();
  static set instance(SportsApiService service) => _instance = service;

  final Dio dio;
  final AssetBundle? assetBundle;
  final Duration cacheTtl;
  final String? overrideApiSportsKey;
  final String? overrideSportradarKey;

  // Caché en memoria indexada por fecha YYYY-MM-DD
  final Map<String, _CacheEntry> _cacheByDate = {};
  String _activeSource = 'mock-local';

  // Caché de resultados por partido: los finalizados no se vuelven a consultar
  // y el resto respeta el mismo TTL, para cuidar la cuota diaria de la API.
  final Map<String, ({MatchModel match, DateTime timestamp})> _resultsById = {};

  SportsApiService({
    Dio? dio,
    this.assetBundle,
    this.cacheTtl = const Duration(minutes: 15),
    this.overrideApiSportsKey,
    this.overrideSportradarKey,
  }) : dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 5),
                receiveTimeout: const Duration(seconds: 5),
              ),
            );

  String get activeSource => _activeSource;

  DateTime? get lastFetchTime {
    final today = _formatDate(DateTime.now());
    return _cacheByDate[today]?.timestamp;
  }

  bool hasValidCacheFor(String dateStr) {
    final entry = _cacheByDate[dateStr];
    if (entry == null) return false;
    // Respaldo local usa TTL breve (2 min) para evitar latencias de 10s continuas offline
    // pero permitiendo reintentar red oportunistamente si la conectividad regresa.
    final effectiveTtl = entry.source == 'mock-local'
        ? const Duration(minutes: 2)
        : cacheTtl;
    return DateTime.now().difference(entry.timestamp) < effectiveTtl;
  }

  bool get hasValidCache {
    final today = _formatDate(DateTime.now());
    return hasValidCacheFor(today);
  }

  void clearCache() {
    _cacheByDate.clear();
    _resultsById.clear();
  }

  /// Estado y marcador actual de un partido por su id, para liquidar apuestas
  /// con el resultado real (HU-03/04). Los ids `sr:` se consultan en Sportradar
  /// y el resto en API-Sports. Devuelve null si el partido no existe.
  Future<MatchModel?> getMatchResult(String matchId) async {
    final cached = _resultsById[matchId];
    if (cached != null &&
        (cached.match.isFinished ||
            cached.match.isCancelled ||
            DateTime.now().difference(cached.timestamp) < cacheTtl)) {
      return cached.match;
    }

    final match = matchId.startsWith('sr:')
        ? await _fetchResultFromSportradar(matchId)
        : await _fetchResultFromApiSports(matchId);
    if (match != null) {
      _resultsById[matchId] = (match: match, timestamp: DateTime.now());
    }
    return match;
  }

  Future<MatchModel?> _fetchResultFromApiSports(String matchId) async {
    final apiKey = overrideApiSportsKey ??
        (dotenv.isInitialized ? dotenv.env['API_SPORTS_KEY'] : null);
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_api_sports_key_here') {
      throw Exception('API_SPORTS_KEY no configurada');
    }

    final response = await dio.get(
      'https://v1.volleyball.api-sports.io/games',
      queryParameters: {'id': matchId},
      options: Options(headers: {'x-apisports-key': apiKey}),
    );

    final data = response.data is String ? jsonDecode(response.data) : response.data;
    if (data is! Map<String, dynamic>) {
      throw Exception('Formato de respuesta inesperado de API-Sports');
    }
    final errors = data['errors'];
    if ((errors is Map && errors.isNotEmpty) || (errors is List && errors.isNotEmpty)) {
      throw Exception('API-Sports devolvió errores: $errors');
    }

    final rawList = data['response'];
    if (rawList is! List || rawList.isEmpty || rawList.first is! Map) return null;
    return MatchModel.fromApiSports(
      Map<String, dynamic>.from(rawList.first as Map),
      source: 'api-sports',
    );
  }

  Future<MatchModel?> _fetchResultFromSportradar(String matchId) async {
    final apiKey = overrideSportradarKey ??
        (dotenv.isInitialized ? dotenv.env['SPORTRADAR_API_KEY'] : null);
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_sportradar_api_key_here') {
      throw Exception('SPORTRADAR_API_KEY no configurada');
    }

    final response = await dio.get(
      'https://api.sportradar.com/volleyball/trial/v2/en/sport_events/$matchId/summary',
      queryParameters: {'api_key': apiKey},
      options: Options(headers: {'Accept': 'application/json'}),
    );

    final data = response.data is String ? jsonDecode(response.data) : response.data;
    if (data is! Map<String, dynamic>) {
      throw Exception('Formato de respuesta inesperado de Sportradar');
    }
    return MatchModel.fromSportradar(data, source: 'sportradar');
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Obtiene la lista de partidos aplicando la estrategia de failover:
  /// 1. Caché en memoria indexado por fecha (< 15 min)
  /// 2. Fuente Primaria: API-Sports (header `x-apisports-key`)
  /// 3. Fuente Secundaria: Sportradar Volleyball v2 (query param `api_key`)
  /// 4. Respaldo Offline: `assets/mock_matches.json` (sin bloquear TTL largo)
  Future<List<MatchModel>> getMatches({
    bool forceRefresh = false,
    DateTime? date,
  }) async {
    final queryDate = date ?? DateTime.now();
    final dateStr = _formatDate(queryDate);

    // 1. Verificar caché en memoria por fecha
    if (!forceRefresh && hasValidCacheFor(dateStr)) {
      final cached = _cacheByDate[dateStr]!;
      _activeSource = cached.source;
      debugPrint('⚡ [SportsApiService] Servido desde caché (${cached.matches.length} partidos para $dateStr)');
      return cached.matches;
    }

    // 2. Intentar Fuente Primaria: API-Sports
    try {
      final matches = await _fetchFromApiSports(dateStr);
      // Respuestas válidas (incluso listas vacías) se aceptan sin forzar fallback
      _cacheByDate[dateStr] = _CacheEntry(
        matches: matches,
        timestamp: DateTime.now(),
        source: 'api-sports',
      );
      _activeSource = 'api-sports';
      debugPrint('✅ [SportsApiService] Datos cargados de API-Sports (${matches.length} partidos)');
      return matches;
    } catch (e) {
      debugPrint('⚠️ [SportsApiService] Fallo en API-Sports: $e. Conmutando a Sportradar...');
    }

    // 3. Intentar Fuente Secundaria: Sportradar Volleyball v2
    try {
      final matches = await _fetchFromSportradar(dateStr);
      // Respuestas válidas se aceptan sin forzar fallback
      _cacheByDate[dateStr] = _CacheEntry(
        matches: matches,
        timestamp: DateTime.now(),
        source: 'sportradar',
      );
      _activeSource = 'sportradar';
      debugPrint('✅ [SportsApiService] Datos cargados de Sportradar (${matches.length} partidos)');
      return matches;
    } catch (e) {
      debugPrint('⚠️ [SportsApiService] Fallo en Sportradar: $e. Conmutando a respaldo offline...');
    }

    // 4. Respaldo Offline: assets/mock_matches.json
    try {
      final matches = await _loadMockMatches();
      _cacheByDate[dateStr] = _CacheEntry(
        matches: matches,
        timestamp: DateTime.now(),
        source: 'mock-local',
      );
      _activeSource = 'mock-local';
      debugPrint('📦 [SportsApiService] Datos cargados desde Respaldo Local Mock (${matches.length} partidos)');
      return matches;
    } catch (e) {
      debugPrint('❌ [SportsApiService] Error al cargar mock local: $e');
      rethrow;
    }
  }

  Future<List<MatchModel>> _fetchFromApiSports(String dateStr) async {
    final apiKey = overrideApiSportsKey ??
        (dotenv.isInitialized ? dotenv.env['API_SPORTS_KEY'] : null);
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_api_sports_key_here') {
      throw Exception('API_SPORTS_KEY no configurada');
    }

    final response = await dio.get(
      'https://v1.volleyball.api-sports.io/games',
      queryParameters: {'date': dateStr},
      options: Options(
        headers: {
          'x-apisports-key': apiKey,
        },
      ),
    );

    final data = response.data is String ? jsonDecode(response.data) : response.data;
    if (data is! Map<String, dynamic>) {
      throw Exception('Formato de respuesta inesperado de API-Sports');
    }

    // Verificar errores de cuota o clave
    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      throw Exception('API-Sports devolvió errores: $errors');
    }
    if (errors is List && errors.isNotEmpty) {
      throw Exception('API-Sports devolvió errores: $errors');
    }

    final rawList = data['response'];
    if (rawList is! List) {
      throw Exception('Campo response ausente o no es lista');
    }

    return rawList
        .whereType<Map>()
        .map((m) => MatchModel.fromApiSports(Map<String, dynamic>.from(m), source: 'api-sports'))
        .toList();
  }

  Future<List<MatchModel>> _fetchFromSportradar(String dateStr) async {
    final apiKey = overrideSportradarKey ??
        (dotenv.isInitialized ? dotenv.env['SPORTRADAR_API_KEY'] : null);
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_sportradar_api_key_here') {
      throw Exception('SPORTRADAR_API_KEY no configurada');
    }

    final response = await dio.get(
      'https://api.sportradar.com/volleyball/trial/v2/en/schedules/$dateStr/summaries',
      queryParameters: {'api_key': apiKey},
      options: Options(
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    final data = response.data is String ? jsonDecode(response.data) : response.data;
    if (data is! Map<String, dynamic>) {
      throw Exception('Formato de respuesta inesperado de Sportradar');
    }

    final summaries = data['summaries'];
    if (summaries is! List) {
      throw Exception('Campo summaries ausente en Sportradar');
    }

    return summaries
        .whereType<Map>()
        .map((m) => MatchModel.fromSportradar(Map<String, dynamic>.from(m), source: 'sportradar'))
        .toList();
  }

  Future<List<MatchModel>> _loadMockMatches() async {
    final bundle = assetBundle ?? rootBundle;
    final jsonString = await bundle.loadString('assets/mock_matches.json');
    final data = jsonDecode(jsonString);

    if (data is Map && data['response'] is List) {
      final list = data['response'] as List;
      return list
          .whereType<Map>()
          .map((m) => MatchModel.fromApiSports(Map<String, dynamic>.from(m), source: 'mock-local'))
          .toList();
    } else if (data is List) {
      return data
          .whereType<Map>()
          .map((m) => MatchModel.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
    throw Exception('Estructura no válida en mock_matches.json');
  }
}
