import 'dart:async';
import 'package:flutter/material.dart';
import 'ludo_data.dart';
import 'ludo_models.dart';
import 'ludo_logic.dart';
import 'ludo_board.dart';

class GameScreen extends StatefulWidget {
  /// Map of color -> isAI. Colors not present are not in the game.
  final Map<PlayerColor, bool> seats;

  final int Function()? diceRoller;

  const GameScreen({super.key, required this.seats, this.diceRoller});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late LudoEngine engine;
  late List<LudoPlayer> players;
  final LudoTurnTracker turnTracker = LudoTurnTracker();
  int currentPlayerIndex = 0;
  int? lastDice;
  List<LudoToken> movable = [];
  bool rolling = false;
  bool turnTransitioning = false;
  bool gameOver = false;
  String message = '';

  @override
  void initState() {
    super.initState();
    players = widget.seats.entries
        .map((e) => LudoPlayer(color: e.key, isAI: e.value))
        .toList()
      ..sort((a, b) => a.color.index.compareTo(b.color.index));
    engine = LudoEngine(players);
    message = 'دور ${players[currentPlayerIndex].color.label}: ارمِ النرد';
    _maybeTriggerAI();
  }

  LudoPlayer get currentPlayer => players[currentPlayerIndex];

  void _nextTurn({bool extraTurn = false}) {
    setState(() {
      lastDice = null;
      movable = [];
      rolling = false;
      turnTransitioning = false;
      if (!extraTurn) {
        currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
        turnTracker.reset();
      }
      message = 'دور ${currentPlayer.color.label}: ارمِ النرد';
    });
    _maybeTriggerAI();
  }

  void _maybeTriggerAI() {
    if (gameOver) return;
    if (currentPlayer.isAI) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted || gameOver) return;
        _roll();
      });
    }
  }

  void _roll() {
    if (rolling || turnTransitioning || gameOver) return;
    setState(() => rolling = true);
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final dice = widget.diceRoller?.call() ?? engine.rollDice();
      final turnCancelled = turnTracker.registerRoll(dice);
      if (turnCancelled) {
        setState(() {
          rolling = false;
          turnTransitioning = true;
          lastDice = null;
          movable = [];
          message = '${currentPlayer.color.label} رمى 6 للمرة الثالثة — تم إلغاء الدور';
        });
        Future.delayed(const Duration(milliseconds: 700), () {
          if (!mounted) return;
          _nextTurn();
        });
        return;
      }

      final opts = engine.movableTokens(currentPlayer, dice);
      setState(() {
        rolling = false;
        lastDice = dice;
        movable = opts;
      });
      if (opts.isEmpty) {
        setState(() => message =
            '${currentPlayer.color.label} رمى $dice — لا توجد نقلة ممكنة');
        Future.delayed(const Duration(milliseconds: 700), () {
          if (!mounted) return;
          // A six grants another roll even when no legal move exists.
          _nextTurn(extraTurn: dice == 6);
        });
        return;
      }
      if (currentPlayer.isAI) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          final choice = engine.chooseAIMove(currentPlayer, dice);
          _performMove(choice, dice);
        });
      } else if (opts.length == 1) {
        // Auto-play the only option for smoother human UX.
        Future.delayed(const Duration(milliseconds: 250), () {
          if (!mounted) return;
          _performMove(opts.first, dice);
        });
      } else {
        setState(() => message =
            '${currentPlayer.color.label} رمى $dice — اختر مهرة للتحريك');
      }
    });
  }

  Future<void> _performMove(LudoToken token, int dice) async {
    movable = [];

    final startStep = token.step;
    final targetStep = engine.destinationStep(token, dice);

    if (token.inBase) {
      token.step = targetStep;
      if (mounted) setState(() {});
      await Future.delayed(const Duration(milliseconds: 140));
    } else {
      for (var step = startStep + 1; step <= targetStep; step++) {
        token.step = step;
        if (mounted) setState(() {});
        await Future.delayed(const Duration(milliseconds: 120));
      }
    }

    if (!mounted) return;

    // The step-by-step movement above is only the visual animation.
    // Restore the original logical state before applying the real move
    // through the rules engine exactly once.
    token.step = startStep;
    final result = engine.applyMove(token, dice);

    setState(() {
      if (result.captured.isNotEmpty) {
        message = '${currentPlayer.color.label} أكل مهرة! 🎉';
      } else if (token.finished) {
        message = '${currentPlayer.color.label} أوصل مهرة للبيت 🏠';
      } else {
        message = '${currentPlayer.color.label} حرّك مهرة';
      }
    });

    if (currentPlayer.hasWon) {
      setState(() {
        gameOver = true;
        message = '🏆 ${currentPlayer.color.label} فاز باللعبة!';
      });
      return;
    }

    final extra = turnTracker.grantsExtraRoll(
      dice: dice,
      captured: result.captured.isNotEmpty,
    );
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    _nextTurn(extraTurn: extra);
  }

  void _onTokenTap(LudoToken token) {
    if (currentPlayer.isAI || lastDice == null || turnTransitioning) return;
    if (!movable.contains(token)) return;
    _performMove(token, lastDice!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('لودو')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: players.map((p) {
                  final isTurn = p == currentPlayer && !gameOver;
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: p.color.color.withValues(alpha: isTurn ? 0.85 : 0.25),
                        borderRadius: BorderRadius.circular(8),
                        border: isTurn
                            ? Border.all(color: Colors.black, width: 2)
                            : null,
                      ),
                      child: Column(
                        children: [
                          Text(p.color.label,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isTurn ? Colors.white : Colors.black87)),
                          Text(p.isAI ? 'كمبيوتر' : 'لاعب',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: isTurn
                                      ? Colors.white70
                                      : Colors.black54)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: LudoBoard(
                    players: players,
                    highlightedTokens: movable,
                    onTokenTap: _onTokenTap,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: (!gameOver &&
                            !currentPlayer.isAI &&
                            lastDice == null &&
                            !rolling &&
                            !turnTransitioning)
                        ? _roll
                        : null,
                    icon: const Icon(Icons.casino),
                    label: Text(rolling
                        ? '...'
                        : (lastDice?.toString() ?? 'ارمِ النرد')),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                  if (gameOver) ...[
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('رجوع للقائمة'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
