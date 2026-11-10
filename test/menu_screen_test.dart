import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_game/menu_screen.dart';
import 'package:ludo_game/game_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MenuScreen player configuration', () {
    testWidgets('requires at least two active seats and one human',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MenuScreen()));

      var start = find.widgetWithText(ElevatedButton, 'ابدأ اللعبة');
      expect(tester.widget<ElevatedButton>(start).onPressed, isNotNull);

      // Change green from AI to empty, leaving only one active human.
      await tester.tap(find.text('أخضر').first);
      await tester.pump();
      expect(tester.widget<ElevatedButton>(start).onPressed, isNull);

      // Add a second human in the green seat.
      await tester.tap(find.text('أخضر').first);
      await tester.pump();
      expect(tester.widget<ElevatedButton>(start).onPressed, isNotNull);
    });

    testWidgets('starts a match with configured human and AI seats',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MenuScreen()));

      await tester.tap(find.text('ابدأ اللعبة'));
      await tester.pumpAndSettle();

      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.text('لودو'), findsOneWidget);
      expect(find.text('أحمر'), findsOneWidget);
      expect(find.text('أخضر'), findsOneWidget);
      expect(find.text('لاعب'), findsOneWidget);
      expect(find.text('كمبيوتر'), findsOneWidget);
    });

    testWidgets('cycles a seat through human, AI, and empty states',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MenuScreen()));

      expect(find.text('لاعب (هذا الجهاز)'), findsOneWidget);
      expect(find.text('كمبيوتر'), findsOneWidget);
      expect(find.text('فارغ'), findsNWidgets(2));

      await tester.tap(find.text('أحمر').first);
      await tester.pump();
      expect(find.text('كمبيوتر'), findsNWidgets(2));

      await tester.tap(find.text('أحمر').first);
      await tester.pump();
      expect(find.text('فارغ'), findsNWidgets(3));
    });
  });
}
