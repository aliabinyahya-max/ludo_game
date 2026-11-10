import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ludo_data.dart';
import 'ludo_models.dart';
import 'ludo_logic.dart';
import 'ludo_board.dart';
import 'ludo_board_3d.dart';
import 'local_game_store.dart';

class GameScreen extends StatefulWidget {
  /// Map of color -> isAI. Colors not present are not in the game.
  final Map<PlayerColor, bool> seats;

  final int Function()? diceRoller;
  final bool use3DBoard;
  final AIDifficulty aiDifficulty;
  final bool soundEnabled;
  final Map<String, dynamic>? resumeData;

  const GameScreen({
    super.key,
    required this.seats,
    this.diceRoller,
    this.use3DBoard = true,
    this.aiDifficulty = AIDifficulty.medium,
    this.soundEnabled = true,
    this.resumeData,
  });

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
  final LocalGameStore _store = LocalGameStore();
  int captureCount = 0;
  late DateTime _startedAt;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    final savedPlayers = widget.resumeData?['players'];
    if (savedPlayers is List) {
      players = savedPlayers.map((entry) {
        final data = Map<String, dynamic>.from(entry as Map);
        final color = PlayerColor.values.firstWhere(
          (value) => value.name == data['color'],
        );
        final player = LudoPlayer(
          color: color,
          isAI: data['isAI'] == true,
        );
        final steps = data['steps'] as List;
        for (var i = 0; i < player.tokens.length && i < steps.length; i++) {
          player.tokens[i].step = (steps[i] as num).toInt();
        }
        return player;
      }).toList();
    } else {
      players = widget.seats.entries
          .map((e) => LudoPlayer(color: e.key, isAI: e.value))
          .toList()
        ..sort((a, b) => a.color.index.compareTo(b.color.index));
    }
    engine = LudoEngine(players);
    final saved = widget.resumeData;
    if (saved != null) {
      currentPlayerIndex =
          ((saved['currentPlayerIndex'] as num?)?.toInt() ?? 0)
              .clamp(0, players.length - 1)
              .toInt();
      turnTracker.consecutiveSixes =
          (saved['consecutiveSixes'] as num?)?.toInt() ?? 0;
      lastDice = (saved['lastDice'] as num?)?.toInt();
      captureCount = (saved['captureCount'] as num?)?.toInt() ?? 0;
      gameOver = saved['gameOver'] == true;
      final started = saved['startedAt'];
      if (started is String) {
        _startedAt = DateTime.tryParse(started) ?? _startedAt;
      }
      if (lastDice != null) {
        movable = engine.movableTokens(currentPlayer, lastDice!);
      }
    }
    message = 'دور ${players[currentPlayerIndex].color.label}: ارمِ النرد';
    _maybeTriggerAI();
  }

  LudoPlayer get currentPlayer => players[currentPlayerIndex];

  void _playSound({bool alert = false}) {
    if (!widget.soundEnabled) return;
    unawaited(SystemSound.play(
      alert ? SystemSoundType.alert : SystemSoundType.click,
    ));
  }

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
    unawaited(_persistMatch());
    _maybeTriggerAI();
  }

  void _maybeTriggerAI() {
    if (gameOver) return;
    if (currentPlayer.isAI) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted || gameOver) return;
        if (lastDice != null && movable.isNotEmpty) {
          _performMove(
            engine.chooseAIMove(
              currentPlayer,
              lastDice!,
              difficulty: widget.aiDifficulty,
            ),
            lastDice!,
          );
        } else {
          _roll();
        }
      });
    }
  }

  Future<void> _persistMatch() async {
    if (gameOver) return;
    await _store.saveMatch({
      'version': 1,
      'players': players.map((player) => {
        'color': player.color.name,
        'isAI': player.isAI,
        'steps': player.tokens.map((token) => token.step).toList(),
      }).toList(),
      'currentPlayerIndex': currentPlayerIndex,
      'consecutiveSixes': turnTracker.consecutiveSixes,
      'lastDice': lastDice,
      'captureCount': captureCount,
      'gameOver': gameOver,
      'startedAt': _startedAt.toIso8601String(),
    });
  }

  void _roll() {
    if (rolling || turnTransitioning || gameOver) return;
    _playSound();
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
      unawaited(_persistMatch());
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
          final choice = engine.chooseAIMove(currentPlayer, dice, difficulty: widget.aiDifficulty);
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
    captureCount += result.captured.length;
    _playSound(alert: result.captured.isNotEmpty);

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
      _playSound(alert: true);
      await _store.recordCompletedMatch({
        'winner': currentPlayer.color.name,
        'playerCount': players.length,
        'captures': captureCount,
        'durationSeconds': DateTime.now().difference(_startedAt).inSeconds,
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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.18),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: Text(
                  message,
                  key: ValueKey(message),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: widget.use3DBoard
                      ? LudoBoard3D(
                          players: players,
                          highlightedTokens: movable,
                          onTokenTap: _onTokenTap,
                          rolling: rolling,
                        )
                      : LudoBoard(
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
                    icon: AnimatedRotation(
                      turns: rolling ? 0.5 : 0,
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeInOut,
                      child: const Icon(Icons.casino),
                    ),
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
