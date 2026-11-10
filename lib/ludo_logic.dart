import 'dart:math';

import 'ludo_data.dart';
import 'ludo_models.dart';

/// Four selectable computer skill profiles.
enum AIDifficulty { easy, medium, hard, expert }

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

/// Tracks consecutive sixes and determines extra-roll eligibility.
class LudoTurnTracker {
  int consecutiveSixes = 0;

  /// Returns true when the third consecutive six cancels the player's turn.
  bool registerRoll(int dice) {
    if (dice != 6) {
      consecutiveSixes = 0;
      return false;
    }

    consecutiveSixes++;
    if (consecutiveSixes >= 3) {
      consecutiveSixes = 0;
      return true;
    }
    return false;
  }

  /// A six or a capture grants an additional roll.
  bool grantsExtraRoll({required int dice, required bool captured}) {
    return dice == 6 || captured;
  }

  void reset() {
    consecutiveSixes = 0;
  }
}

/// Core rules engine for a Ludo match.
///
/// This class contains game rules only. UI code should not need to know
/// how path indexes, home columns, captures, or legal moves are calculated.
class LudoEngine {
  final List<LudoPlayer> players;
  final Random _rng = Random();

  LudoEngine(this.players) {
    if (players.length < 2 || players.length > 4) {
      throw ArgumentError.value(
        players.length,
        'players.length',
        'A Ludo match requires between two and four players.',
      );
    }

    final colors = players.map((player) => player.color).toSet();
    if (colors.length != players.length) {
      throw ArgumentError.value(
        players,
        'players',
        'Each player must have a unique color.',
      );
    }
  }

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

    // A block exists when any one color has at least two tokens in the cell.
    // An additional token of another color does not dissolve that pair.
    return tokens.any((token) =>
        tokens.where((other) => other.color == token.color).length >= 2);
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

    // A blocking pair must contain two or more tokens of one opponent color.
    // A third token of another color does not dissolve the opponent pair.
    return tokens.any((token) =>
        token.color != movingToken.color &&
        tokens.where((other) => other.color == token.color).length >= 2);
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
    // A token must be one of the actual objects owned by this match.
    // Matching only color/id is insufficient because external token objects
    // could otherwise be moved and mutated outside the registered roster.
    final belongsToMatch = players.any(
      (player) => player.tokens.any((ownedToken) => identical(ownedToken, token)),
    );
    if (!belongsToMatch) {
      return false;
    }

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

  /// Selects a legal move using one of four distinct decision profiles.
  LudoToken chooseAIMove(
    LudoPlayer player,
    int dice, {
    AIDifficulty difficulty = AIDifficulty.medium,
  }) {
    final options = movableTokens(player, dice);
    if (options.isEmpty) {
      throw StateError(
        'No legal move available for ${player.color.label} with dice $dice.',
      );
    }

    if (difficulty == AIDifficulty.easy) {
      return options[_rng.nextInt(options.length)];
    }
    if (difficulty == AIDifficulty.medium) {
      return _chooseMediumMove(player, options, dice);
    }

    LudoToken? best;
    var bestScore = double.negativeInfinity;
    for (final token in options) {
      final targetStep = destinationStep(token, dice);
      final targetGlobal = targetStep < homeEntryStep
          ? (startIndex[token.color]! + targetStep) % mainPathLength
          : null;
      var score = targetStep * 2.0;

      if (targetStep == finishedStep) score += 1200;
      if (targetStep >= homeEntryStep) score += 35;
      if (token.inBase) {
        final active = player.tokens.where((t) => t.onBoard).length;
        score += active < 2 ? 90 : 18;
      }

      if (targetGlobal != null) {
        if (isSafeGlobalCell(targetGlobal)) score += 55;
        final captures = players.any((other) =>
            other.color != player.color &&
            other.tokens.any((enemy) =>
                enemy.onPath && enemy.globalPathIndex == targetGlobal));
        if (captures) score += 850;

        final createsOwnStack = player.tokens.any((other) =>
            !identical(other, token) &&
            other.onPath &&
            other.globalPathIndex == targetGlobal);
        if (createsOwnStack) {
          score += difficulty == AIDifficulty.expert ? 42 : 24;
        }

        final exposed = !isSafeGlobalCell(targetGlobal) &&
            players.where((other) => other.color != player.color).any((other) =>
                other.tokens.any((enemy) {
                  if (!enemy.onPath) return false;
                  for (var roll = 1; roll <= 6; roll++) {
                    final enemyTarget = enemy.step + roll;
                    if (enemyTarget < homeEntryStep &&
                        (startIndex[enemy.color]! + enemyTarget) %
                                mainPathLength ==
                            targetGlobal) {
                      return true;
                    }
                  }
                  return false;
                }));
        if (exposed) {
          score -= difficulty == AIDifficulty.expert ? 115 : 48;
        }
      }

      if (difficulty == AIDifficulty.expert && token.inHomeColumn) {
        score += 12;
      }
      if (score > bestScore) {
        bestScore = score;
        best = token;
      }
    }
    return best!;
  }

  LudoToken _chooseMediumMove(
    LudoPlayer player,
    List<LudoToken> options,
    int dice,
  ) {
    for (final token in options) {
      final targetStep = destinationStep(token, dice);
      if (targetStep >= homeEntryStep) continue;
      final targetGlobal = (startIndex[token.color]! + targetStep) %
          mainPathLength;
      if (isSafeGlobalCell(targetGlobal)) continue;
      final captures = players.any((other) =>
          other.color != token.color &&
          other.tokens.any((enemy) =>
              enemy.onPath && enemy.globalPathIndex == targetGlobal));
      if (captures) return token;
    }

    for (final token in options) {
      if (destinationStep(token, dice) == finishedStep) return token;
    }

    final activeTokenCount =
        player.tokens.where((token) => token.onBoard).length;
    if (dice == 6 && activeTokenCount < 2) {
      final baseTokens = options.where((token) => token.inBase).toList();
      if (baseTokens.isNotEmpty) return baseTokens.first;
    }

    final movingTokens = options.where((token) => !token.inBase).toList()
      ..sort((a, b) => b.step.compareTo(a.step));
    if (movingTokens.isNotEmpty) return movingTokens.first;
    return options.first;
  }
}
