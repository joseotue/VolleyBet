import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/bet_model.dart';
import '../../providers/betting_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bet_card.dart';
import '../../widgets/bet_form.dart';
import '../../widgets/points_badge.dart';
import '../../widgets/simulation_control_dialog.dart';

/// Historial de apuestas del usuario (HU-03: READ, UPDATE y DELETE bajo RLS).
/// Pestañas de apuestas pendientes y finalizadas.
class BetHistoryScreen extends StatelessWidget {
  const BetHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final betting = context.watch<BettingProvider>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'MIS APUESTAS',
            style: GoogleFonts.teko(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryOrange,
              letterSpacing: 1.5,
            ),
          ),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(child: PointsBadge(compact: true)),
            ),
          ],
          bottom: TabBar(
            indicatorColor: AppTheme.primaryOrange,
            labelColor: AppTheme.primaryOrange,
            unselectedLabelColor: AppTheme.textSecondary,
            tabs: [
              Tab(text: 'PENDIENTES (${betting.activeBets.length})'),
              Tab(text: 'FINALIZADAS (${betting.settledBets.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _BetList(
              bets: betting.activeBets,
              emptyMessage: 'No tienes apuestas pendientes.\nElige un partido en la cartelera para apostar.',
            ),
            _BetList(
              bets: betting.settledBets,
              emptyMessage: 'Aún no tienes apuestas finalizadas.\nSimula un partido para liquidarlas.',
            ),
          ],
        ),
      ),
    );
  }
}

class _BetList extends StatelessWidget {
  final List<BetModel> bets;
  final String emptyMessage;

  const _BetList({required this.bets, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    final betting = context.watch<BettingProvider>();

    Widget content;
    if (betting.isLoading && betting.bets.isEmpty) {
      content = const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryOrange),
      );
    } else if (betting.errorMessage != null && betting.bets.isEmpty) {
      content = _CenteredMessage(
        icon: Icons.cloud_off_rounded,
        message: 'No se pudo cargar tu historial:\n${betting.errorMessage}',
      );
    } else if (bets.isEmpty) {
      content = _CenteredMessage(
        icon: Icons.receipt_long_rounded,
        message: emptyMessage,
      );
    } else {
      content = ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: bets.length,
        itemBuilder: (context, index) {
          final bet = bets[index];
          return BetCard(
            bet: bet,
            onEdit: () => _editBet(context, bet),
            onCancel: () => _cancelBet(context, bet),
            onSimulate: () => _simulate(context, bet),
          );
        },
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryOrange,
      onRefresh: () => context.read<BettingProvider>().loadUserData(),
      child: content,
    );
  }

  Future<void> _editBet(BuildContext context, BetModel bet) async {
    final betting = context.read<BettingProvider>();
    final messenger = ScaffoldMessenger.of(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'MODIFICAR APUESTA',
              style: GoogleFonts.teko(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryOrange,
              ),
            ),
            Text(
              '${bet.matchLabel} · ${bet.selectedTeam}',
              style: GoogleFonts.rajdhani(fontSize: 15, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            BetForm(
              // El monto actual vuelve a estar disponible al editar.
              availableBalance: betting.pointsBalance + bet.pointsStaked,
              odds: bet.odds,
              initialAmount: bet.pointsStaked,
              submitLabel: 'GUARDAR CAMBIOS',
              onSubmit: (amount) async {
                try {
                  await betting.updateBetAmount(bet, amount);
                  if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                  messenger.showSnackBar(
                    SnackBar(content: Text('Apuesta actualizada a $amount pts')),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(BettingProvider.describeError(e)),
                      backgroundColor: AppTheme.errorRed,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelBet(BuildContext context, BetModel bet) async {
    final betting = context.read<BettingProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('¿Cancelar apuesta?'),
        content: Text(
          'Se eliminará tu apuesta de ${bet.pointsStaked} pts a ${bet.selectedTeam} '
          'y se devolverá el monto íntegro a tu saldo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Volver'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await betting.cancelBet(bet);
      messenger.showSnackBar(
        SnackBar(content: Text('Apuesta cancelada. +${bet.pointsStaked} pts devueltos')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(BettingProvider.describeError(e)),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  Future<void> _simulate(BuildContext context, BetModel bet) {
    return SimulationControlDialog.show(
      context,
      matchId: bet.matchId,
      homeTeam: bet.homeTeam ?? bet.selectedTeam,
      awayTeam: bet.awayTeam ?? bet.opponentTeam ?? 'Rival',
      runSimulation: (provider) => provider.simulateFromBet(bet),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  final IconData icon;
  final String message;

  const _CenteredMessage({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    // ListView para que el RefreshIndicator funcione también sin datos.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 60),
        Icon(icon, size: 56, color: AppTheme.textSecondary),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.rajdhani(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
