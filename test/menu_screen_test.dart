import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_game/app_theme.dart';
import 'package:ludo_game/game_screen.dart';
import 'package:ludo_game/main.dart' as app;
import 'package:ludo_game/menu_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Premium menu and player configuration', () {
    testWidgets('app shell enforces Arabic right-to-left direction', (tester) async {
      await tester.pumpWidget(const app.LudoApp());
      final menuContext = tester.element(find.byType(MenuScreen));
      expect(Directionality.of(menuContext), TextDirection.rtl);
    });

    testWidgets('uses the premium dark visual system', (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: LudoTheme.dark, home: const MenuScreen()),
      );
      expect(find.text('PREMIUM'), findsOneWidget);
      expect(find.text('مستعد للتحدي؟'), findsOneWidget);
      expect(find.text('تجهيز المباراة'), findsOneWidget);
      for (final color in ['red', 'green', 'yellow', 'blue']) {
        expect(find.byKey(ValueKey('seat-$color')), findsOneWidget);
      }
    });

    testWidgets('requires at least two active seats and one human', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MenuScreen()));
      final start = find.widgetWithText(ElevatedButton, 'ابدأ المباراة');
      expect(tester.widget<ElevatedButton>(start).onPressed, isNotNull);

      await tester.tap(find.byKey(const ValueKey('seat-green')));
      await tester.pump();
      expect(tester.widget<ElevatedButton>(start).onPressed, isNull);

      await tester.tap(find.byKey(const ValueKey('seat-green')));
      await tester.pump();
      expect(tester.widget<ElevatedButton>(start).onPressed, isNotNull);
    });

    testWidgets('starts a match with configured human and AI seats', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MenuScreen()));
      final start = find.text('ابدأ المباراة');
      await tester.ensureVisible(start);
      await tester.tap(start);
      await tester.pumpAndSettle();

      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.text('لودو'), findsOneWidget);
      expect(find.text('أحمر'), findsOneWidget);
      expect(find.text('أخضر'), findsOneWidget);
      expect(find.text('لاعب'), findsOneWidget);
      expect(find.text('كمبيوتر'), findsOneWidget);
    });

    testWidgets('cycles a seat through human, AI, and empty states', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MenuScreen()));
      expect(find.text('بشري'), findsOneWidget);
      expect(find.text('كمبيوتر'), findsOneWidget);
      expect(find.text('مقعد فارغ'), findsNWidgets(2));

      await tester.tap(find.byKey(const ValueKey('seat-red')));
      await tester.pump();
      expect(find.text('كمبيوتر'), findsNWidgets(2));

      await tester.tap(find.byKey(const ValueKey('seat-red')));
      await tester.pump();
      expect(find.text('مقعد فارغ'), findsNWidgets(3));
    });

    testWidgets('adapts to a narrow viewport without horizontal overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: MenuScreen()));
      expect(tester.takeException(), isNull);
      expect(find.text('ابدأ المباراة'), findsOneWidget);
    });
  });
}
