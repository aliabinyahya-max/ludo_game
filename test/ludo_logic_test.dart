import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_game/ludo_data.dart';
import 'package:ludo_game/ludo_logic.dart';
import 'package:ludo_game/ludo_models.dart';

void placeOnGlobalCell(LudoToken token, int globalIndex) {
  token.step =
      (globalIndex - startIndex[token.color]! + mainPathLength) %
          mainPathLength;
}

void main() {
  group('LudoEngine opponent blocks', () {
    late LudoPlayer red;
    late LudoPlayer green;
    late LudoPlayer yellow;
    late LudoEngine engine;

    setUp(() {
      red = LudoPlayer(color: PlayerColor.red, isAI: false);
      green = LudoPlayer(color: PlayerColor.green, isAI: false);
      yellow = LudoPlayer(color: PlayerColor.yellow, isAI: false);
      engine = LudoEngine([red, green, yellow]);
    });

    test('two tokens of one opponent color form a block', () {
      placeOnGlobalCell(green.tokens[0], 1);
      placeOnGlobalCell(green.tokens[1], 1);

      expect(engine.isBlockAtGlobalCell(1), isTrue);
      expect(engine.isOpponentBlockAtGlobalCell(red.tokens[0], 1), isTrue);
    });

    test('tokens of different colors do not form an opponent block', () {
      placeOnGlobalCell(green.tokens[0], 1);
      placeOnGlobalCell(yellow.tokens[0], 1);

      expect(engine.isBlockAtGlobalCell(1), isFalse);
      expect(engine.isOpponentBlockAtGlobalCell(red.tokens[0], 1), isFalse);
    });

    test('a move cannot cross a genuine opponent block', () {
      placeOnGlobalCell(red.tokens[0], 0);
      placeOnGlobalCell(green.tokens[0], 1);
      placeOnGlobalCell(green.tokens[1], 1);

      expect(engine.crossesOpponentBlock(red.tokens[0], 2), isTrue);
      expect(engine.canMoveToken(red.tokens[0], 2), isFalse);
    });

    test('a mixed-color stack is not treated as a blocking pair', () {
      placeOnGlobalCell(red.tokens[0], 0);
      placeOnGlobalCell(green.tokens[0], 1);
      placeOnGlobalCell(yellow.tokens[0], 1);

      expect(engine.crossesOpponentBlock(red.tokens[0], 2), isFalse);
      expect(engine.canMoveToken(red.tokens[0], 2), isTrue);
    });
  });

  group('LudoEngine movement and capture rules', () {
    late LudoPlayer red;
    late LudoPlayer green;
    late LudoEngine engine;

    setUp(() {
      red = LudoPlayer(color: PlayerColor.red, isAI: false);
      green = LudoPlayer(color: PlayerColor.green, isAI: false);
      engine = LudoEngine([red, green]);
    });

    test('a token in base can leave only with a six', () {
      expect(engine.canMoveToken(red.tokens[0], 5), isFalse);
      expect(engine.canMoveToken(red.tokens[0], 6), isTrue);
    });

    test('a token must roll the exact number to finish', () {
      red.tokens[0].step = finishedStep - 1;

      expect(engine.canMoveToken(red.tokens[0], 1), isTrue);
      expect(engine.canMoveToken(red.tokens[0], 2), isFalse);
    });

    test('landing on an unsafe cell captures an opponent token', () {
      red.tokens[0].step = 1; // Global cell 1.
      placeOnGlobalCell(green.tokens[0], 2);

      final result = engine.applyMove(red.tokens[0], 1);

      expect(result.captured, contains(green.tokens[0]));
      expect(green.tokens[0].inBase, isTrue);
    });

    test('landing on a safe cell does not capture an opponent token', () {
      red.tokens[0].step = 7; // Moves to safe global cell 8.
      placeOnGlobalCell(green.tokens[0], 8);

      final result = engine.applyMove(red.tokens[0], 1);

      expect(result.captured, isEmpty);
      expect(green.tokens[0].onPath, isTrue);
    });

    test('finishing the last token reports a completed game', () {
      for (final token in red.tokens.skip(1)) {
        token.step = finishedStep;
      }
      red.tokens[0].step = finishedStep - 1;

      final result = engine.applyMove(red.tokens[0], 1);

      expect(result.finishedGame, isTrue);
      expect(red.hasWon, isTrue);
    });
  });

  group('LudoEngine boundary and invariant rules', () {
    late LudoPlayer red;
    late LudoPlayer green;
    late LudoPlayer yellow;
    late LudoPlayer blue;
    late LudoEngine engine;

    setUp(() {
      red = LudoPlayer(color: PlayerColor.red, isAI: false);
      green = LudoPlayer(color: PlayerColor.green, isAI: false);
      yellow = LudoPlayer(color: PlayerColor.yellow, isAI: false);
      blue = LudoPlayer(color: PlayerColor.blue, isAI: false);
      engine = LudoEngine([red, green, yellow, blue]);
    });

    test('a mixed stack with no matching-color pair is not a block', () {
      placeOnGlobalCell(green.tokens[0], 8);
      placeOnGlobalCell(yellow.tokens[0], 8);
      placeOnGlobalCell(blue.tokens[0], 8);

      expect(engine.isBlockAtGlobalCell(8), isFalse);
      expect(engine.isOpponentBlockAtGlobalCell(red.tokens[0], 8), isFalse);
    });

    test('a same-color pair remains a block beside a different-color token', () {
      placeOnGlobalCell(green.tokens[0], 8);
      placeOnGlobalCell(green.tokens[1], 8);
      placeOnGlobalCell(yellow.tokens[0], 8);

      expect(engine.isBlockAtGlobalCell(8), isTrue);
      expect(engine.isOpponentBlockAtGlobalCell(red.tokens[0], 8), isTrue);
    });

    test('a same-color opponent pair blocks even with moving color present', () {
      placeOnGlobalCell(green.tokens[0], 8);
      placeOnGlobalCell(green.tokens[1], 8);
      placeOnGlobalCell(red.tokens[0], 8);

      expect(engine.isOpponentBlockAtGlobalCell(red.tokens[0], 8), isTrue);
    });

    test('a single opponent token never forms a block', () {
      placeOnGlobalCell(green.tokens[0], 8);

      expect(engine.isBlockAtGlobalCell(8), isFalse);
      expect(engine.isOpponentBlockAtGlobalCell(red.tokens[0], 8), isFalse);
    });

    test('dice values outside one through six are rejected', () {
      for (final dice in [-1, 0, 7, 99]) {
        expect(engine.canMoveToken(red.tokens[0], dice), isFalse);
      }
    });

    test('a finished token cannot move again', () {
      red.tokens[0].step = finishedStep;

      for (final dice in [1, 2, 3, 4, 5, 6]) {
        expect(engine.canMoveToken(red.tokens[0], dice), isFalse);
      }
    });

    test('a token cannot overshoot the final home cell', () {
      red.tokens[0].step = finishedStep - 2;

      expect(engine.canMoveToken(red.tokens[0], 1), isTrue);
      expect(engine.canMoveToken(red.tokens[0], 2), isTrue);
      expect(engine.canMoveToken(red.tokens[0], 3), isFalse);
    });

    test('an opponent block on the final shared cell still blocks entry home', () {
      red.tokens[0].step = mainPathLength - 2;
      final lastRedPathCell =
          (startIndex[PlayerColor.red]! + mainPathLength - 1) %
              mainPathLength;
      placeOnGlobalCell(green.tokens[0], lastRedPathCell);
      placeOnGlobalCell(green.tokens[1], lastRedPathCell);

      expect(engine.canMoveToken(red.tokens[0], 2), isFalse);
    });

    test('a move may enter the home column after crossing its final path cell', () {
      red.tokens[0].step = mainPathLength - 2;

      expect(engine.canMoveToken(red.tokens[0], 2), isTrue);
      expect(engine.destinationStep(red.tokens[0], 2), homeEntryStep);
    });

    test('a block immediately before home entry cannot be crossed', () {
      red.tokens[0].step = mainPathLength - 2;
      final lastRedPathCell =
          (startIndex[PlayerColor.red]! + mainPathLength - 1) %
              mainPathLength;
      placeOnGlobalCell(green.tokens[0], lastRedPathCell);
      placeOnGlobalCell(green.tokens[1], lastRedPathCell);

      expect(engine.crossesOpponentBlock(red.tokens[0], 2), isTrue);
    });

    test('wrapping around the shared path checks opponent blocks for every color', () {
      for (final color in PlayerColor.values) {
        final movingPlayer = engine.playerOf(color);
        final opponent = engine.players.firstWhere((p) => p.color != color);
        final movingToken = movingPlayer.tokens[0];
        final blockIndex = (startIndex[color]! + mainPathLength - 1) %
            mainPathLength;

        movingToken.step = mainPathLength - 2;
        placeOnGlobalCell(opponent.tokens[0], blockIndex);
        placeOnGlobalCell(opponent.tokens[1], blockIndex);

        expect(
          engine.canMoveToken(movingToken, 2),
          isFalse,
          reason: 'Expected $color to be blocked before path wrap/home entry',
        );

        movingToken.step = baseStep;
        opponent.tokens[0].step = baseStep;
        opponent.tokens[1].step = baseStep;
      }
    });

    test('a player wins only when all four tokens are finished', () {
      for (final token in red.tokens.take(3)) {
        token.step = finishedStep;
      }

      expect(red.hasWon, isFalse);

      red.tokens[3].step = finishedStep;
      expect(red.hasWon, isTrue);
    });

    test('AI prefers a legal capture over ordinary progress', () {
      red.tokens[0].step = 1;
      placeOnGlobalCell(green.tokens[0], 2);

      expect(engine.chooseAIMove(red, 1), same(red.tokens[0]));
    });

    test('AI prefers an exact winning move', () {
      red.tokens[0].step = finishedStep - 1;

      expect(engine.chooseAIMove(red, 1), same(red.tokens[0]));
    });

    test('AI can choose to release a token from base on six', () {
      expect(engine.chooseAIMove(red, 6), same(red.tokens[0]));
    });

    test('AI advances the most progressed movable token when no capture exists', () {
      red.tokens[0].step = 4;
      red.tokens[1].step = 12;

      expect(engine.chooseAIMove(red, 1), same(red.tokens[1]));
    });

    test('AI rejects selection when no legal move exists', () {
      expect(
        () => engine.chooseAIMove(red, 5),
        throwsStateError,
      );
    });
  });


  group('LudoEngine player-approved turn and safe-cell rules', () {
    late LudoPlayer red;
    late LudoPlayer green;
    late LudoPlayer yellow;
    late LudoEngine engine;

    setUp(() {
      red = LudoPlayer(color: PlayerColor.red, isAI: false);
      green = LudoPlayer(color: PlayerColor.green, isAI: false);
      yellow = LudoPlayer(color: PlayerColor.yellow, isAI: false);
      engine = LudoEngine([red, green, yellow]);
    });

    test('a player may pass through their own two-token block', () {
      placeOnGlobalCell(red.tokens[0], 0);
      placeOnGlobalCell(red.tokens[1], 1);
      placeOnGlobalCell(red.tokens[2], 1);

      expect(engine.isBlockAtGlobalCell(1), isTrue);
      expect(engine.crossesOpponentBlock(red.tokens[0], 2), isFalse);
      expect(engine.canMoveToken(red.tokens[0], 2), isTrue);
    });

    test('different-color tokens remain together on a safe cell', () {
      red.tokens[0].step = 7; // Destination is safe global cell 8.
      placeOnGlobalCell(green.tokens[0], 8);
      placeOnGlobalCell(yellow.tokens[0], 8);

      final result = engine.applyMove(red.tokens[0], 1);

      expect(result.captured, isEmpty);
      expect(red.tokens[0].globalPathIndex, 8);
      expect(green.tokens[0].globalPathIndex, 8);
      expect(yellow.tokens[0].globalPathIndex, 8);
    });
  });

  group('LudoTurnTracker', () {
    late LudoTurnTracker tracker;

    setUp(() {
      tracker = LudoTurnTracker();
    });

    test('the first and second consecutive sixes retain the turn', () {
      expect(tracker.registerRoll(6), isFalse);
      expect(tracker.consecutiveSixes, 1);
      expect(tracker.registerRoll(6), isFalse);
      expect(tracker.consecutiveSixes, 2);
    });

    test('the third consecutive six cancels the turn and resets the count', () {
      expect(tracker.registerRoll(6), isFalse);
      expect(tracker.registerRoll(6), isFalse);
      expect(tracker.registerRoll(6), isTrue);
      expect(tracker.consecutiveSixes, 0);
    });

    test('a non-six breaks the consecutive-six sequence', () {
      expect(tracker.registerRoll(6), isFalse);
      expect(tracker.registerRoll(6), isFalse);
      expect(tracker.registerRoll(4), isFalse);
      expect(tracker.consecutiveSixes, 0);
      expect(tracker.registerRoll(6), isFalse);
    });

    test('a capture grants an extra roll even when dice is not six', () {
      expect(
        tracker.grantsExtraRoll(dice: 3, captured: true),
        isTrue,
      );
    });

    test('a six grants an extra roll without a capture', () {
      expect(
        tracker.grantsExtraRoll(dice: 6, captured: false),
        isTrue,
      );
    });

    test('an ordinary move without a capture does not grant an extra roll', () {
      expect(
        tracker.grantsExtraRoll(dice: 4, captured: false),
        isFalse,
      );
    });
  });


  group('LudoEngine roster invariants', () {
    test('rejects fewer than two players', () {
      final red = LudoPlayer(color: PlayerColor.red, isAI: false);
      expect(() => LudoEngine([red]), throwsArgumentError);
    });

    test('rejects more than four players', () {
      final players = PlayerColor.values
          .map((color) => LudoPlayer(color: color, isAI: false))
          .toList()
        ..add(LudoPlayer(color: PlayerColor.red, isAI: true));
      expect(() => LudoEngine(players), throwsArgumentError);
    });

    test('rejects duplicate player colors', () {
      final redOne = LudoPlayer(color: PlayerColor.red, isAI: false);
      final redTwo = LudoPlayer(color: PlayerColor.red, isAI: true);
      expect(() => LudoEngine([redOne, redTwo]), throwsArgumentError);
    });

    test('rejects a token that does not belong to this match', () {
      final red = LudoPlayer(color: PlayerColor.red, isAI: false);
      final green = LudoPlayer(color: PlayerColor.green, isAI: false);
      final engine = LudoEngine([red, green]);
      final externalRedToken = LudoToken(color: PlayerColor.red, id: 0);

      expect(engine.canMoveToken(externalRedToken, 6), isFalse);
      expect(
        () => engine.applyMove(externalRedToken, 6),
        throwsStateError,
      );
    });
  });

  group('AI difficulty profiles', () {
    test('all four difficulty profiles return a legal move', () {
      final red = LudoPlayer(color: PlayerColor.red, isAI: true);
      final green = LudoPlayer(color: PlayerColor.green, isAI: false);
      final engine = LudoEngine([red, green]);

      for (final level in AIDifficulty.values) {
        final selected = engine.chooseAIMove(
          red,
          6,
          difficulty: level,
        );
        expect(red.tokens, contains(selected), reason: 'Invalid move at $level');
        expect(engine.canMoveToken(selected, 6), isTrue);
      }
    });

    test('four distinct difficulty levels are exposed', () {
      expect(AIDifficulty.values, hasLength(4));
      expect(AIDifficulty.values, containsAll([
        AIDifficulty.easy,
        AIDifficulty.medium,
        AIDifficulty.hard,
        AIDifficulty.expert,
      ]));
    });

    test('hard AI avoids an exposed advance that medium prefers', () {
      final red = LudoPlayer(color: PlayerColor.red, isAI: true);
      final green = LudoPlayer(color: PlayerColor.green, isAI: false);
      final engine = LudoEngine([red, green]);

      // Red token 0 is further advanced but would land on a cell
      // reachable by green next turn. Red token 1 lands on safe cell 8.
      red.tokens[0].step = 9;
      red.tokens[1].step = 7;
      green.tokens[0].step = 48; // Green global cell 9; one roll reaches 10.

      final medium = engine.chooseAIMove(
        red, 1, difficulty: AIDifficulty.medium,
      );
      final hard = engine.chooseAIMove(
        red, 1, difficulty: AIDifficulty.hard,
      );

      expect(medium, same(red.tokens[0]));
      expect(hard, same(red.tokens[1]));
    });
  });

}
