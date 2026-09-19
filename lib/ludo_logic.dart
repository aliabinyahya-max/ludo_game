import 'dart:math';

import 'ludo_data.dart';
import 'ludo_models.dart';

class MoveResult {
  final LudoToken moved;
  final List<LudoToken> captured;
  final bool finishedGame;

  MoveResult(
    this.moved,
    this.captured,
    this.finishedGame,
  );
}

/// Core rules engine for a Ludo match.
///
/// This class contains game rules only. UI code should not need to know
/// how path indexes, home columns, captures, or legal moves are calculated.
class LudoEngine {
  final List<LudoPlayer> players;
  final Random _rng = Random();

  LudoEngine(this.players);

  LudoPlayer playerOf(PlayerColor color) {
    return players.firstWhere((player) => player.color == color);
  }

  int rollDice() {
    return _rng.nextInt(6) + 1;
  }

  /// Returns the shared-board index occupied by [token].
  ///
  /// Returns null when the token is in base, home column, or finished.
  int? globalPathIndexOf(LudoToken token) {
    return token.globalPathIndex;
  }

  bool isSafeGlobalCell(int globalIndex) {
    return safeIndices.contains(globalIndex);
  }

  /// Returns all tokens currently occupying a shared-path cell.
  List<LudoToken> tokensAtGlobalCell(int globalIndex) {
    final result = <LudoToken>[];

    for (final player in players) {
      for (final token in player.tokens) {
        if (token.onPath && globalPathIndexOf(token) == globalIndex) {
          result.add(token);
        }
      }
    }

    return result;
  }

  /// A block is formed by two or more tokens of the same color
  /// occupying the same shared-path cell.
  bool isBlockAtGlobalCell(int globalIndex) {
    final tokens = tokensAtGlobalCell(globalIndex);

    if (tokens.length < 2) {
      return false;
    }

    return tokens.every((token) => token.color == tokens.first.color);
  }

  /// Returns true when an opponent block occupies the given cell.
  bool isOpponentBlockAtGlobalCell(
    LudoToken movingToken,
    int globalIndex,
  ) {
    final tokens = tokensAtGlobalCell(globalIndex);

    if (tokens.length < 2) {
      return false;
    }

    return tokens.any((token) => token.color != movingToken.color);
  }

  /// Checks every shared-path cell crossed by [token].
  ///
  /// An opponent block cannot be landed on or crossed.
  bool crossesOpponentBlock(LudoToken token, int dice) {
    if (dice < 1 || token.finished || token.inBase) {
      return false;
    }

    for (var offset = 1; offset <= dice; offset++) {
      final step = token.step + offset;

      // Once the token enters its home column, it no longer uses
      // shared-path cells.
      if (step >= homeEntryStep) {
        break;
      }

      final globalIndex = (startIndex[token.color]! + step) % mainPathLength;

      if (isOpponentBlockAtGlobalCell(token, globalIndex)) {
        return true;
      }
    }

    return false;
  }

  /// Checks whether [token] can legally move with [dice].
  bool canMoveToken(LudoToken token, int dice) {
    if (dice < 1 || dice > 6) {
      return false;
    }

    if (token.finished) {
      return false;
    }

    // A token leaves base only on a 6.
    if (token.inBase) {
      final startCell = startIndex[token.color]!;

      // A token cannot enter an opponent block.
      return !isOpponentBlockAtGlobalCell(token, startCell) && dice == 6;
    }

    // Exact finish is required. The token may not pass step 57.
    final targetStep = token.step + dice;

    if (targetStep > finishedStep) {
      return false;
    }

    // An opponent block cannot be crossed or landed on.
    return !crossesOpponentBlock(token, dice);
  }

  /// Returns all tokens belonging to [player] that can legally move.
  List<LudoToken> movableTokens(LudoPlayer player, int dice) {
    return player.tokens.where((token) => canMoveToken(token, dice)).toList();
  }

  /// Calculates the destination step without changing the token.
  int destinationStep(LudoToken token, int dice) {
    if (!canMoveToken(token, dice)) {
      throw StateError(
        'Illegal move: token ${token.id} cannot move with dice $dice.',
      );
    }

    if (token.inBase) {
      return 0;
    }

    return token.step + dice;
  }

  /// Applies a legal move and handles captures.
  MoveResult applyMove(LudoToken token, int dice) {
    if (!canMoveToken(token, dice)) {
      throw StateError(
        'Illegal move: token ${token.id} cannot move with dice $dice.',
      );
    }

    token.step = destinationStep(token, dice);

    final captured = <LudoToken>[];
    final destinationGlobal = globalPathIndexOf(token);

    // Captures are possible only on shared path cells that are not safe.
    if (destinationGlobal != null && !isSafeGlobalCell(destinationGlobal)) {
      for (final player in players) {
        if (player.color == token.color) {
          continue;
        }

        for (final opponentToken in player.tokens) {
          if (opponentToken.onPath &&
              globalPathIndexOf(opponentToken) == destinationGlobal) {
            opponentToken.step = baseStep;
            captured.add(opponentToken);
          }
        }
      }
    }

    final playerWon = playerOf(token.color).hasWon;

    return MoveResult(
      token,
      captured,
      playerWon,
    );
  }

  /// Basic AI move selection.
  ///
  /// Priority:
  /// 1. Capture an opponent.
  /// 2. Finish a token.
  /// 3. Bring a token out of base.
  /// 4. Advance the most progressed token.
  /// 5. Fallback to the first legal token.
  LudoToken chooseAIMove(LudoPlayer player, int dice) {
    final options = movableTokens(player, dice);

    if (options.isEmpty) {
      throw StateError(
        'No legal move available for ${player.color.label} with dice $dice.',
      );
    }

    // 1. Prefer a capture.
    for (final token in options) {
      final targetStep = destinationStep(token, dice);

      if (targetStep >= homeEntryStep) {
        continue;
      }

      final targetGlobal = token.inBase
          ? startIndex[token.color]!
          : (startIndex[token.color]! + targetStep) % mainPathLength;

      if (isSafeGlobalCell(targetGlobal)) {
        continue;
      }

      if (isOpponentBlockAtGlobalCell(token, targetGlobal)) {
        continue;
      }

      final capturesOpponent = players.any(
        (otherPlayer) =>
            otherPlayer.color != token.color &&
            otherPlayer.tokens.any(
              (opponentToken) =>
                  opponentToken.onPath &&
                  globalPathIndexOf(opponentToken) == targetGlobal,
            ),
      );

      if (capturesOpponent) {
        return token;
      }
    }

    // 2. Prefer finishing a token.
    for (final token in options) {
      if (destinationStep(token, dice) == finishedStep) {
        return token;
      }
    }

    // 3. Prefer bringing a token out of base on a 6.
    final activeTokenCount =
        player.tokens.where((token) => token.onBoard).length;

    if (dice == 6 && activeTokenCount < 2) {
      final baseTokens = options.where((token) => token.inBase).toList();

      if (baseTokens.isNotEmpty) {
        return baseTokens.first;
      }
    }

    // 4. Advance the most progressed token.
    final movingTokens = options.where((token) => !token.inBase).toList();

    if (movingTokens.isNotEmpty) {
      movingTokens.sort(
        (a, b) => b.step.compareTo(a.step),
      );

      return movingTokens.first;
    }

    // 5. Fallback.
    return options.first;
  }
}
