import '../models/bet_model.dart';
import '../models/user_profile.dart';

/// Contrato de persistencia de apuestas que consume `BettingProvider` (HU-04).
/// `SupabaseService` lo implementa contra la tabla `bets` con RLS; los tests
/// usan una implementación en memoria.
abstract class BettingRepository {
  String? get currentUserId;

  Future<UserProfile?> getUserProfile(String userId);

  /// READ: historial del usuario autenticado (RLS filtra por `auth.uid()`).
  Future<List<BetModel>> getUserBets();

  /// CREATE: inserta una apuesta PENDING. El trigger descuenta el saldo.
  Future<BetModel> createBet(BetModel bet);

  /// UPDATE: cambia el monto de una apuesta PENDING. El trigger ajusta la diferencia.
  Future<BetModel> updateBetAmount({required String betId, required int amount});

  /// DELETE: cancela una apuesta PENDING. El trigger reembolsa el monto.
  Future<void> cancelBet(String betId);

  /// Liquida una apuesta tras la simulación (WON abona monto * cuota).
  Future<BetModel> settleBet({required String betId, required bool won});

  /// Anula una apuesta de un partido cancelado (CANCELLED). El trigger reembolsa
  /// el monto y la apuesta queda visible en el historial.
  Future<BetModel> voidBet(String betId);

  Future<void> updateBadges({required String userId, required List<String> badges});
}
