import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/trivia_reward_result.dart';
import '../../providers/betting_provider.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

class TriviaScreen extends StatefulWidget {
  const TriviaScreen({super.key});

  @override
  State<TriviaScreen> createState() => _TriviaScreenState();
}

class _TriviaScreenState extends State<TriviaScreen> {
  static const List<_TriviaQuestion> _questions = [
    _TriviaQuestion(
      statement: '¿Cuántos jugadores de cada equipo están en la cancha?',
      options: ['5 jugadores', '6 jugadores', '7 jugadores', '8 jugadores'],
      correctAnswerIndex: 1,
    ),
    _TriviaQuestion(
      statement: '¿A cuántos puntos se juega normalmente un set?',
      options: ['15 puntos', '21 puntos', '25 puntos', '30 puntos'],
      correctAnswerIndex: 2,
    ),
    _TriviaQuestion(
      statement: '¿Cuántos contactos puede realizar un equipo antes de pasar el balón?',
      options: ['2 contactos', '3 contactos', '4 contactos', '5 contactos'],
      correctAnswerIndex: 1,
    ),
    _TriviaQuestion(
      statement: '¿En qué dirección rotan los jugadores al recuperar el saque?',
      options: [
        'En el sentido de las agujas del reloj',
        'En sentido contrario',
        'Hacia el centro',
        'No cambian de posición',
      ],
      correctAnswerIndex: 0,
    ),
    _TriviaQuestion(
      statement: '¿A cuántos puntos se juega el quinto set decisivo?',
      options: ['10 puntos', '12 puntos', '15 puntos', '25 puntos'],
      correctAnswerIndex: 2,
    ),
  ];

  late List<_TriviaQuestion> _roundQuestions;
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  int _correctAnswers = 0;
  int _triviaPointsEarned = 0;
  int _triviaPointsCapacity = 1000;
  bool _isFinished = false;
  bool _isLoadingStatus = true;
  bool _isClaimingReward = false;
  String? _rewardError;
  TriviaRewardResult? _rewardResult;

  _TriviaQuestion get _currentQuestion =>
      _roundQuestions[_currentQuestionIndex];
  bool get _isLastQuestion =>
      _currentQuestionIndex == _roundQuestions.length - 1;
  bool get _passed => _correctAnswers == _roundQuestions.length;
  double get _triviaProgress {
    if (_triviaPointsCapacity <= 0) return 1;
    return (_triviaPointsEarned / _triviaPointsCapacity)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  @override
  void initState() {
    super.initState();
    _roundQuestions = List<_TriviaQuestion>.of(_questions)..shuffle();
    _loadTriviaStatus();
  }

  Future<void> _loadTriviaStatus() async {
    final userId = SupabaseService.instance.currentUserId;
    if (userId == null) {
      if (mounted) setState(() => _isLoadingStatus = false);
      return;
    }

    final profile = await SupabaseService.instance.getUserProfile(userId);
    if (!mounted) return;

    setState(() {
      _triviaPointsEarned = profile?.triviaPointsEarned ?? 0;
      _triviaPointsCapacity = profile?.triviaPointsCapacity ?? 1000;
      _isLoadingStatus = false;
    });
  }

  void _selectAnswer(int answerIndex) {
    if (_selectedAnswerIndex != null) return;

    setState(() {
      _selectedAnswerIndex = answerIndex;
      if (answerIndex == _currentQuestion.correctAnswerIndex) {
        _correctAnswers++;
      }
    });
  }

  Future<void> _continueTrivia() async {
    if (_selectedAnswerIndex == null) return;

    if (_isLastQuestion) {
      setState(() => _isFinished = true);
      await _claimReward();
      return;
    }

    setState(() {
      _currentQuestionIndex++;
      _selectedAnswerIndex = null;
    });
  }

  Future<void> _claimReward() async {
    if (_isClaimingReward) return;
    final betting = context.read<BettingProvider>();

    setState(() {
      _isClaimingReward = true;
      _rewardError = null;
    });

    try {
      final result = await SupabaseService.instance.claimTriviaReward(
        correctAnswers: _correctAnswers,
      );
      await betting.loadUserData();
      if (!mounted) return;

      setState(() {
        _rewardResult = result;
        _triviaPointsEarned = result.triviaPointsEarned;
        _triviaPointsCapacity = result.triviaPointsCapacity;
        _isClaimingReward = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _rewardError = BettingProvider.describeError(error);
        _isClaimingReward = false;
      });
    }
  }

  void _restartTrivia() {
    setState(() {
      _roundQuestions = List<_TriviaQuestion>.of(_questions)..shuffle();
      _currentQuestionIndex = 0;
      _selectedAnswerIndex = null;
      _correctAnswers = 0;
      _isFinished = false;
      _rewardError = null;
      _rewardResult = null;
    });
  }

  Color _optionColor(int optionIndex) {
    if (_selectedAnswerIndex == null) return AppTheme.cardColor;
    if (optionIndex == _currentQuestion.correctAnswerIndex) {
      return AppTheme.successGreen.withValues(alpha: 0.22);
    }
    if (optionIndex == _selectedAnswerIndex) {
      return AppTheme.errorRed.withValues(alpha: 0.22);
    }
    return AppTheme.cardColor;
  }

  Color _optionBorderColor(int optionIndex) {
    if (_selectedAnswerIndex == null) return AppTheme.dividerColor;
    if (optionIndex == _currentQuestion.correctAnswerIndex) {
      return AppTheme.successGreen;
    }
    if (optionIndex == _selectedAnswerIndex) return AppTheme.errorRed;
    return AppTheme.dividerColor;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingStatus) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('MODO APRENDER')),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isFinished ? _buildResult() : _buildQuestion(),
        ),
      ),
    );
  }

  Widget _buildQuestion() {
    final questionNumber = _currentQuestionIndex + 1;

    return SingleChildScrollView(
      key: ValueKey('question-$questionNumber'),
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'PUNTOS DE TRIVIA: '
                        '$_triviaPointsEarned / $_triviaPointsCapacity',
                        style: GoogleFonts.teko(
                          color: AppTheme.primaryOrange,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _triviaProgress,
                        minHeight: 7,
                        borderRadius: BorderRadius.circular(8),
                        backgroundColor: AppTheme.dividerColor,
                        color: AppTheme.primaryOrange,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PREGUNTA $questionNumber DE ${_roundQuestions.length}',
                    style: GoogleFonts.teko(
                      color: AppTheme.primaryOrange,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    '$_correctAnswers correctas',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: questionNumber / _roundQuestions.length,
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
                backgroundColor: AppTheme.dividerColor,
                color: AppTheme.primaryOrange,
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _currentQuestion.statement,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              for (
                var index = 0;
                index < _currentQuestion.options.length;
                index++
              )
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _selectAnswer(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: _optionColor(index),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _optionBorderColor(index),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppTheme.background,
                            child: Text(String.fromCharCode(65 + index)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(_currentQuestion.options[index]),
                          ),
                          if (_selectedAnswerIndex != null &&
                              index == _currentQuestion.correctAnswerIndex)
                            const Icon(
                              Icons.check_circle,
                              color: AppTheme.successGreen,
                            )
                          else if (_selectedAnswerIndex == index)
                            const Icon(Icons.cancel, color: AppTheme.errorRed),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _selectedAnswerIndex == null
                    ? null
                    : _continueTrivia,
                icon: Icon(
                  _isLastQuestion
                      ? Icons.flag_rounded
                      : Icons.arrow_forward_rounded,
                ),
                label: Text(
                  _isLastQuestion ? 'VER RESULTADO' : 'SIGUIENTE PREGUNTA',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResult() {
    return SingleChildScrollView(
      key: const ValueKey('result'),
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _passed
                        ? Icons.emoji_events_rounded
                        : Icons.menu_book_rounded,
                    color: _passed
                        ? AppTheme.primaryOrange
                        : AppTheme.textSecondary,
                    size: 72,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _passed ? '¡TRIVIA SUPERADA!' : 'SIGUE APRENDIENDO',
                    style: GoogleFonts.teko(
                      color: _passed
                          ? AppTheme.primaryOrange
                          : AppTheme.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Respondiste correctamente $_correctAnswers de '
                    '${_roundQuestions.length} preguntas.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Cada acierto vale 200 puntos. La insignia Experto Junior requiere cinco respuestas correctas.',
                    style: const TextStyle(color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _buildRewardStatus(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRewardStatus() {
    if (_isClaimingReward) {
      return const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Guardando recompensa...'),
        ],
      );
    }

    if (_rewardError != null) {
      return Column(
        children: [
          Text(
            _rewardError!,
            style: const TextStyle(color: AppTheme.errorRed),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _claimReward,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('REINTENTAR GUARDADO'),
          ),
        ],
      );
    }

    final reward = _rewardResult;
    if (reward == null) return const SizedBox.shrink();

    final rewardMessage = reward.pointsAwarded > 0
        ? 'Ganaste ${reward.pointsAwarded} puntos.'
        : reward.capacityReached
        ? 'Ya alcanzaste el máximo de puntos mediante trivia.'
        : 'Esta ronda no entregó puntos.';

    return Column(
      children: [
        Text(
          rewardMessage,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        if (reward.calculatedPoints > reward.pointsAwarded) ...[
          const SizedBox(height: 8),
          Text(
            'La recompensa se ajustó al espacio restante del límite.',
            style: const TextStyle(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
        if (_passed && reward.badges.contains(BettingProvider.juniorBadge)) ...[
          const SizedBox(height: 12),
          const Chip(
            avatar: Icon(Icons.military_tech_rounded),
            label: Text('Experto Junior en Voleibol'),
          ),
        ],
        const SizedBox(height: 8),
        Text('Saldo actual: ${reward.pointsBalance} pts'),
        const SizedBox(height: 6),
        Text(
          'Progreso de trivia: ${reward.triviaPointsEarned} / '
          '${reward.triviaPointsCapacity} pts',
        ),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton.icon(
              onPressed: _restartTrivia,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('JUGAR OTRA VEZ'),
            ),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.home_rounded),
              label: const Text('VOLVER AL INICIO'),
            ),
          ],
        ),
      ],
    );
  }
}

class _TriviaQuestion {
  final String statement;
  final List<String> options;
  final int correctAnswerIndex;

  const _TriviaQuestion({
    required this.statement,
    required this.options,
    required this.correctAnswerIndex,
  });
}
