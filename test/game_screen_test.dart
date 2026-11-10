import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo_game/game_screen.dart';
import 'package:ludo_game/ludo_data.dart';
import 'package:ludo_game/ludo_board.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameScreen turn flow', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });
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
            use3DBoard: false,
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

      await tester.tap(diceButton);
      expect(rollCount, 3);

      await tester.pump(const Duration(milliseconds: 701));
      expect(tester.widget<ElevatedButton>(diceButton).onPressed, isNotNull);
    });

    testWidgets('passes to the next human when no legal move exists',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            seats: const {
              PlayerColor.red: false,
              PlayerColor.green: false,
            },
            diceRoller: () => 5,
            use3DBoard: false,
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pump(const Duration(milliseconds: 351));
      expect(find.textContaining('لا توجد نقلة ممكنة'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 701));

      expect(find.textContaining('دور أخضر'), findsOneWidget);
      expect(tester.widget<ElevatedButton>(
        find.byType(ElevatedButton).first,
      ).onPressed, isNotNull);
    });

    testWidgets('cycles human and AI turns for 2-4 player configurations',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (var count = 2; count <= 4; count++) {
        var rollCount = 0;
        int deterministicOne() {
          rollCount++;
          return 1;
        }

        final seats = <PlayerColor, bool>{
          for (var i = 0; i < count; i++)
            PlayerColor.values[i]: i != 0,
        };

        await tester.pumpWidget(
          MaterialApp(
            home: GameScreen(seats: seats, diceRoller: deterministicOne, use3DBoard: false),
          ),
        );

        expect(find.text('لودو'), findsOneWidget);
        expect(find.text('لاعب'), findsOneWidget);
        expect(find.text('كمبيوتر'), findsNWidgets(count - 1));

        await tester.tap(find.byType(ElevatedButton).first);
        await tester.pump(const Duration(milliseconds: 351));
        await tester.pump(const Duration(milliseconds: 701));

        for (var aiTurn = 1; aiTurn < count; aiTurn++) {
          await tester.pump(const Duration(milliseconds: 601));
          await tester.pump(const Duration(milliseconds: 351));
          await tester.pump(const Duration(milliseconds: 701));
        }

        expect(rollCount, count);
        expect(find.textContaining('دور أحمر'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('falls back to the 2D board when 3D initialization times out',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            seats: const {
              PlayerColor.red: false,
              PlayerColor.green: false,
            },
            use3DBoard: true,
            boardInitializationTimeout: const Duration(milliseconds: 100),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 101));
      await tester.pump();

      expect(find.textContaining('تم التبديل إلى اللوحة البديلة'), findsOneWidget);
      expect(find.byType(LudoBoard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
