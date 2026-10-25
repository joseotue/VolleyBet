import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/bet_model.dart';
import '../models/trivia_reward_result.dart';
import '../models/user_profile.dart';
import 'betting_repository.dart';

/// Perfil de acceso rápido para demostración y evaluación con el equipo docente.
class TeamQuickProfile {
  final String name;
  final String email;
  final String password;
  final String role;

  const TeamQuickProfile({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });
}

/// Servicio singleton para la integración y operaciones con Supabase Auth y Database.
class SupabaseService implements BettingRepository {
  SupabaseService._internal();
  static final SupabaseService instance = SupabaseService._internal();

  /// Perfiles sembrados del equipo para acceso rápido en la demo docente UDD.
  static const List<TeamQuickProfile> teamProfiles = [
    TeamQuickProfile(
      name: 'Lucas',
      email: 'lucas@volleybet.udd',
      password: 'volleybet123',
      role: 'Backend, Auth & Persistencia',
    ),
    TeamQuickProfile(
      name: 'Otue',
      email: 'otue@volleybet.udd',
      password: 'volleybet123',
      role: 'UI, API & Navegación',
    ),
    TeamQuickProfile(
      name: 'Jesús',
      email: 'jesus@volleybet.udd',
      password: 'volleybet123',
      role: 'Estado Global & Simulación',
    ),
  ];

  /// Inicializa el cliente Supabase utilizando las variables de entorno cargadas por dotenv.
  /// Nunca expone la Secret Key (Service Role).
  static Future<void> initialize() async {
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey =
        dotenv.env['SUPABASE_ANON_KEY'] ??
        dotenv.env['SUPABASE_PUBLISHABLE_KEY'];

    if (supabaseUrl == null || supabaseUrl.isEmpty) {
      throw Exception('Falta la variable SUPABASE_URL en el archivo .env');
    }
    if (supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
      throw Exception('Falta la variable SUPABASE_ANON_KEY en el archivo .env');
    }

    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  SupabaseClient? _clientOverride;

  /// Permite inyectar o mockear el cliente para pruebas unitarias y de widgets.
  void setClientForTesting(SupabaseClient? client) {
    _clientOverride = client;
  }

  /// Comprueba si Supabase ha sido inicializado correctamente
  bool get isInitialized {
    if (_clientOverride != null) return true;
    try {
      Supabase.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Instancia del cliente de Supabase
  SupabaseClient get client {
    if (_clientOverride != null) return _clientOverride!;
    return Supabase.instance.client;
  }

  /// Usuario autenticado actual en Supabase
  User? get currentUser => isInitialized ? client.auth.currentUser : null;

  @override
  String? get currentUserId => currentUser?.id;

  /// Sesión activa actual
  Session? get currentSession =>
      isInitialized ? client.auth.currentSession : null;

  /// Stream reactivo de cambios en el estado de autenticación
  Stream<AuthState> get authStateChanges =>
      isInitialized ? client.auth.onAuthStateChange : const Stream.empty();

  /// Iniciar sesión con email y contraseña
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Registro de nuevo usuario en Supabase Auth
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? username,
  }) async {
    final response = await client.auth.signUp(
      email: email.trim(),
      password: password,
      data: username != null ? {'username': username} : null,
    );

    // Si se crea el usuario, asegurar entrada en profiles si aún no existe sin sobrescribir puntos
    if (response.user != null) {
      try {
        await client
            .from('profiles')
            .upsert(
              {
                'id': response.user!.id,
                'username': username ?? email.split('@').first,
                'points_balance': 1000,
              },
              onConflict: 'id',
              ignoreDuplicates: true,
            );
      } catch (e) {
        // En caso de que RLS o trigger de DB lo gestione
      }
    }

    return response;
  }

  /// Iniciar sesión rápidamente con uno de los perfiles del equipo
  Future<AuthResponse> signInWithQuickProfile(TeamQuickProfile profile) async {
    return await signInWithPassword(
      email: profile.email,
      password: profile.password,
    );
  }

  /// Cierra la sesión activa actual en Supabase
  Future<void> signOut() async {
    if (!isInitialized) return;
    await client.auth.signOut();
  }

  /// Obtener el perfil del usuario desde public.profiles
  @override
  Future<UserProfile?> getUserProfile(String userId) async {
    if (!isInitialized) return null;
    try {
      final data = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data != null) {
        return UserProfile.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<UserProfile>> getRankingProfiles() async {
    final data = await client
        .from('profiles')
        .select()
        .order('points_balance', ascending: false);

    return data.map(UserProfile.fromJson).toList();
  }

  /// Entrega 200 puntos por acierto sin superar la capacidad acumulada.
  /// Supabase calcula y suma la recompensa en una transacción atómica.
  Future<TriviaRewardResult> claimTriviaReward({
    required int correctAnswers,
  }) async {
    if (correctAnswers < 0 || correctAnswers > 5) {
      throw ArgumentError.value(
        correctAnswers,
        'correctAnswers',
        'Debe estar entre 0 y 5',
      );
    }

    final data = await client.rpc(
      'claim_trivia_reward',
      params: {'p_correct_answers': correctAnswers},
    );

    return TriviaRewardResult.fromJson(Map<String, dynamic>.from(data as Map));
  }

  // ===========================================================================
  // HU-03: CRUD de apuestas sobre la tabla `bets` protegida con RLS
  // (auth.uid() = user_id). El trigger `bets_apply_balance` mueve el saldo
  // de `profiles` en la misma transacción.
  // ===========================================================================

  /// CREATE — Inserta una apuesta PENDING del usuario autenticado.
  @override
  Future<BetModel> createBet(BetModel bet) async {
    final data = await client
        .from('bets')
        .insert(bet.toInsertJson())
        .select()
        .single();
    return BetModel.fromJson(data);
  }

  /// READ — Historial propio; RLS impide ver apuestas de otros usuarios.
  @override
  Future<List<BetModel>> getUserBets() async {
    final data = await client
        .from('bets')
        .select()
        .order('created_at', ascending: false);
    return data.map(BetModel.fromJson).toList();
  }

  /// UPDATE — Modifica el monto de una apuesta pendiente.
  @override
  Future<BetModel> updateBetAmount({
    required String betId,
    required int amount,
  }) async {
    final data = await client
        .from('bets')
        .update({'points_staked': amount})
        .eq('id', betId)
        .eq('status', BetStatus.pending.value)
        .select()
        .single();
    return BetModel.fromJson(data);
  }

  /// DELETE — Cancela una apuesta pendiente y el trigger reembolsa el monto.
  @override
  Future<void> cancelBet(String betId) async {
    await client
        .from('bets')
        .delete()
        .eq('id', betId)
        .eq('status', BetStatus.pending.value);
  }

  /// Liquida una apuesta tras la simulación (HU-04). El premio lo calcula el trigger.
  @override
  Future<BetModel> settleBet({required String betId, required bool won}) async {
    final status = won ? BetStatus.won : BetStatus.lost;
    final data = await client
        .from('bets')
        .update({'status': status.value})
        .eq('id', betId)
        .eq('status', BetStatus.pending.value)
        .select()
        .single();
    return BetModel.fromJson(data);
  }

  /// Anula una apuesta pendiente de un partido cancelado; el trigger la reembolsa.
  @override
  Future<BetModel> voidBet(String betId) async {
    final data = await client
        .from('bets')
        .update({'status': BetStatus.cancelled.value})
        .eq('id', betId)
        .eq('status', BetStatus.pending.value)
        .select()
        .single();
    return BetModel.fromJson(data);
  }

  /// Persiste las insignias del usuario en `profiles.badges`.
  @override
  Future<void> updateBadges({
    required String userId,
    required List<String> badges,
  }) async {
    await client.from('profiles').update({'badges': badges}).eq('id', userId);
  }
}
