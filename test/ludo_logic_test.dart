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
}
