import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Formulario de monto de apuesta con validación estricta (HU-03 / Requisito 6).
/// Usa `Form` + `GlobalKey<FormState>` + `TextFormField` con teclado numérico
/// y validación en tiempo real. Solo llama a [onSubmit] si `validate()` es true.
class BetForm extends StatefulWidget {
  /// Puntos disponibles para esta apuesta (al editar incluye el monto ya apostado).
  final int availableBalance;
  final double odds;
  final int? initialAmount;
  final String submitLabel;
  final Future<void> Function(int amount) onSubmit;

  const BetForm({
    super.key,
    required this.availableBalance,
    required this.odds,
    required this.onSubmit,
    this.initialAmount,
    this.submitLabel = 'CONFIRMAR APUESTA',
  });

  /// Validador del monto (criterio 3.1). Público para pruebas unitarias.
  static String? validateAmount(String? value, int availableBalance) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Ingresa un monto';
    final amount = int.tryParse(text);
    if (amount == null) return 'Ingresa un monto válido';
    if (amount <= 0) return 'El monto mínimo es 1 punto';
    if (amount > availableBalance) {
      return 'Saldo insuficiente (disponibles: $availableBalance pts)';
    }
    return null;
  }

  @override
  State<BetForm> createState() => _BetFormState();
}

class _BetFormState extends State<BetForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  bool _isSubmitting = false;
  bool _isSubmitPressed = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.initialAmount?.toString() ?? '',
    );
    _amountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _isSubmitPressed = false;
    });
    try {
      await widget.onSubmit(int.parse(_amountController.text.trim()));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _handleSubmitHighlight(bool isHighlighted) {
    if (_isSubmitting) return;
    setState(() => _isSubmitPressed = isHighlighted);
  }

  @override
  Widget build(BuildContext context) {
    final amount = int.tryParse(_amountController.text.trim());
    final payout = (amount != null && amount > 0)
        ? (amount * widget.odds).round()
        : null;

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const Key('bet-amount-field'),
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            enabled: !_isSubmitting,
            decoration: InputDecoration(
              labelText: 'Monto a apostar',
              hintText: 'Ej: 100',
              prefixIcon: const Icon(Icons.monetization_on_rounded),
              suffixText: 'pts',
              helperText: 'Disponibles: ${widget.availableBalance} pts',
            ),
            validator: (value) =>
                BetForm.validateAmount(value, widget.availableBalance),
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 10),
          Text(
            payout != null
                ? 'Premio potencial: $payout pts (cuota ${widget.odds.toStringAsFixed(2)})'
                : 'Cuota ${widget.odds.toStringAsFixed(2)}',
            style: GoogleFonts.rajdhani(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedScale(
            scale: _isSubmitPressed ? 0.97 : 1,
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: _isSubmitting
                    ? AppTheme.secondaryOrange
                    : _isSubmitPressed
                    ? AppTheme.secondaryOrange
                    : AppTheme.primaryOrange,
                borderRadius: BorderRadius.circular(12),
                boxShadow: _isSubmitPressed
                    ? const []
                    : [
                        BoxShadow(
                          color: AppTheme.primaryOrange.withValues(alpha: 0.22),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  key: const Key('animated-submit-button'),
                  onTap: _isSubmitting ? null : _submit,
                  onHighlightChanged: _handleSubmitHighlight,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isSubmitting)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                          ),
                        const SizedBox(width: 8),
                        Text(
                          widget.submitLabel,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
