import 'dart:math';
import 'ludo_data.dart';
import 'ludo_models.dart';

class MoveResult {
  final LudoToken moved;
  final List<LudoToken> captured;
  final bool finishedGame;
  MoveResult(this.moved, this.captured, this.finishedGame);
}

class LudoEngine {
  final List<LudoPlayer> players;
  final Random _rng = Random();

  LudoEngine(this.players);

  LudoPlayer playerOf(PlayerColor c) => players.firstWhere((p) => p.color == c);

  int rollDice() => _rng.nextInt(6) + 1;

  /// Tokens that can legally move for [player] given [dice].
  List<LudoToken> movableTokens(LudoPlayer player, int dice) {
    final result = <LudoToken>[];
    for (final t in player.tokens) {
      if (t.finished) continue;
      if (t.inBase) {
        if (dice == 6) result.add(t);
      } else {
        final newStep = t.step + dice;
        if (newStep <= finishedStep) result.add(t);
      }
    }
    return result;
  }

  bool isSafeGlobalCell(int globalIndex) => safeIndices.contains(globalIndex);

  /// Returns the global path index a moving/opponent token occupies, or
  /// null if it's in its home column / base / finished (not capturable there).
  int? _globalIndexOf(LudoToken t) {
    if (t.step < 0 || t.step >= homeEntryStep) return null;
    return (startIndex[t.color]! + t.step) % mainPath.length;
  }

  /// Applies moving [token] by [dice] steps. Handles capturing opponents.
  MoveResult applyMove(LudoToken token, int dice) {
    final newStep = token.inBase ? 0 : token.step + dice;
    token.step = newStep;

    final captured = <LudoToken>[];
    final myGlobal = _globalIndexOf(token);
    if (myGlobal != null && !isSafeGlobalCell(myGlobal)) {
      for (final p in players) {
        if (p.color == token.color) continue;
        for (final t in p.tokens) {
          if (t.onBoard && _globalIndexOf(t) == myGlobal) {
            t.step = -1; // sent back to base
            captured.add(t);
          }
        }
      }
    }

    final wonGame = playerOf(token.color).hasWon;
    return MoveResult(token, captured, wonGame);
  }

  /// Simple AI: prefers captures, then finishing a token, then leaving
  /// base, then advancing the most-advanced token, else random.
  LudoToken chooseAIMove(LudoPlayer player, int dice) {
    final options = movableTokens(player, dice);
    assert(options.isNotEmpty);

    // 1) Prefer a move that captures an opponent.
    for (final t in options) {
      final simulatedGlobal = t.inBase
          ? startIndex[t.color]!
          : (startIndex[t.color]! + t.step + dice) % mainPath.length;
      final wouldBeHomeCol = !t.inBase && (t.step + dice) >= homeEntryStep;
      if (!wouldBeHomeCol && !isSafeGlobalCell(simulatedGlobal)) {
        final capturesHere = players.any((p) =>
            p.color != t.color &&
            p.tokens.any((ot) =>
                ot.onBoard && _globalIndexOf(ot) == simulatedGlobal));
        if (capturesHere) return t;
      }
    }

    // 2) Prefer a move that finishes a token.
    for (final t in options) {
      final target = t.inBase ? 0 : t.step + dice;
      if (target == finishedStep) return t;
    }

    // 3) Prefer bringing a new token out of base on a 6, if few tokens are out.
    final outCount = player.tokens.where((t) => t.onBoard).length;
    if (dice == 6 && outCount < 2) {
      final baseTokens = options.where((t) => t.inBase);
      if (baseTokens.isNotEmpty) return baseTokens.first;
    }

    // 4) Otherwise advance the most-advanced non-base token.
    final onBoardOptions = options.where((t) => !t.inBase).toList();
    if (onBoardOptions.isNotEmpty) {
      onBoardOptions.sort((a, b) => b.step.compareTo(a.step));
      return onBoardOptions.first;
    }

    // 5) Fallback: any option.
    return options.first;
  }
}
