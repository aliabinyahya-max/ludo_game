import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_game/game_screen.dart';
import 'package:ludo_game/ludo_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameScreen turn flow', () {
    testWidgets('locks dice input until the third-six turn transition completes',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var rollCount = 0;
      int deterministicSix() {
        rollCount++;
        return 6;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            seats: const {
              PlayerColor.red: false,
              PlayerColor.green: false,
            },
            diceRoller: deterministicSix,
          ),
        ),
      );

      Future<void> rollAndMove(String tokenKey) async {
        final diceButton = find.byType(ElevatedButton).first;
        expect(tester.widget<ElevatedButton>(diceButton).onPressed, isNotNull);
        await tester.tap(diceButton);
        await tester.pump(const Duration(milliseconds: 351));
        await tester.pump();
        final token = find.byKey(ValueKey(tokenKey));
        expect(token, findsOneWidget);
        await tester.tap(token);
        final movementSteps = tokenKey.endsWith('red-0') ? 0 : 6;
        if (movementSteps == 0) {
          await tester.pump(const Duration(milliseconds: 141));
        } else {
          for (var step = 0; step < movementSteps; step++) {
            await tester.pump(const Duration(milliseconds: 121));
          }
        }
        await tester.pump(const Duration(milliseconds: 501));
        await tester.pump();
      }

      await rollAndMove('token-red-0');
      await rollAndMove('token-red-1');

      final diceButton = find.byType(ElevatedButton).first;
      await tester.tap(diceButton);
      await tester.pump(const Duration(milliseconds: 351));

      expect(rollCount, 3);
      expect(find.textContaining('للمرة الثالثة'), findsOneWidget);
      expect(tester.widget<ElevatedButton>(diceButton).onPressed, isNull);

      await tester.pump(const Duration(milliseconds: 699));
      expect(tester.widget<ElevatedButton>(diceButton).onPressed, isNull);

      await tester.pump(const Duration(milliseconds: 1));
      expect(tester.widget<ElevatedButton>(diceButton).onPressed, isNotNull);
    });

    testWidgets('renders supported 2-4 player human and AI combinations',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (var count = 2; count <= 4; count++) {
        final seats = <PlayerColor, bool>{
          for (var i = 0; i < count; i++)
            PlayerColor.values[i]: i != 0,
        };

        await tester.pumpWidget(
          MaterialApp(home: GameScreen(seats: seats)),
        );
        await tester.pump();

        expect(find.text('لودو'), findsOneWidget);
        expect(find.text('لاعب'), findsOneWidget);
        expect(find.text('كمبيوتر'), findsNWidgets(count - 1));

        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  });
}
