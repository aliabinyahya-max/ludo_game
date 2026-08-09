import 'dart:async';
import 'package:flutter/material.dart';
import 'ludo_data.dart';
import 'ludo_models.dart';
import 'ludo_logic.dart';
import 'ludo_board.dart';

class GameScreen extends StatefulWidget {
  /// Map of color -> isAI. Colors not present are not in the game.
  final Map<PlayerColor, bool> seats;

  const GameScreen({super.key, required this.seats});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late LudoEngine engine;
  late List<LudoPlayer> players;
  int currentPlayerIndex = 0;
  int? lastDice;
  List<LudoToken> movable = [];
  bool rolling = false;
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
      if (!extraTurn) {
        currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
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
    if (rolling || gameOver) return;
    setState(() => rolling = true);
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final dice = engine.rollDice();
      final opts = engine.movableTokens(currentPlayer, dice);
      setState(() {
        rolling = false;
        lastDice = dice;
        movable = opts;
      });
      if (opts.isEmpty) {
        setState(() => message = '${currentPlayer.color.label} رمى $dice — لا توجد نقلة ممكنة');
        Future.delayed(const Duration(milliseconds: 700), () {
          if (!mounted) return;
          _nextTurn(extraTurn: false);
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
        setState(() => message = '${currentPlayer.color.label} رمى $dice — اختر مهرة للتحريك');
      }
    });
  }

  void _performMove(LudoToken token, int dice) {
    final result = engine.applyMove(token, dice);
    setState(() {
      movable = [];
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

    final extra = dice == 6;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _nextTurn(extraTurn: extra);
    });
  }

  void _onTokenTap(LudoToken token) {
    if (currentPlayer.isAI || lastDice == null) return;
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
                        color: p.color.color.withOpacity(isTurn ? 0.85 : 0.25),
                        borderRadius: BorderRadius.circular(8),
                        border: isTurn ? Border.all(color: Colors.black, width: 2) : null,
                      ),
                      child: Column(
                        children: [
                          Text(p.color.label,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isTurn ? Colors.white : Colors.black87)),
                          Text(p.isAI ? 'كمبيوتر' : 'لاعب',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: isTurn ? Colors.white70 : Colors.black54)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(message, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
                    onPressed: (!gameOver && !currentPlayer.isAI && lastDice == null && !rolling)
                        ? _roll
                        : null,
                    icon: const Icon(Icons.casino),
                    label: Text(rolling ? '...' : (lastDice?.toString() ?? 'ارمِ النرد')),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
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
