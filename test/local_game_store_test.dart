import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo_game/local_game_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalGameStore', () {
    late LocalGameStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      store = LocalGameStore();
    });

    test('saves and restores a resumable match snapshot', () async {
      final snapshot = <String, Object?>{
        'version': 1,
        'currentPlayerIndex': 1,
        'players': [
          {'color': 'red', 'isAI': false, 'steps': [-1, 0, 4, 57]},
        ],
      };
      await store.saveMatch(snapshot);
      expect(await store.loadMatch(), equals(snapshot));
    });

    test('clears malformed saved state safely', () async {
      SharedPreferences.setMockInitialValues({'ludo.saved_match.v1': '{bad'});
      expect(await store.loadMatch(), isNull);
      expect(
        (await SharedPreferences.getInstance()).containsKey('ludo.saved_match.v1'),
        isFalse,
      );
    });

    test('records completed matches and keeps newest history first', () async {
      await store.recordCompletedMatch({'winner': 'red', 'captures': 2});
      await store.recordCompletedMatch({'winner': 'green', 'captures': 1});
      final history = await store.loadHistory();
      expect(history, hasLength(2));
      expect(history.first['winner'], 'green');
      expect(history.first['completedAt'], isNotNull);
      expect(await store.loadMatch(), isNull);
    });

    test('persists sound, theme and language preferences', () async {
      await store.setSoundEnabled(false);
      await store.setThemeName('ocean');
      await store.setLanguageCode('en');
      expect(await store.soundEnabled(), isFalse);
      expect(await store.themeName(), 'ocean');
      expect(await store.languageCode(), 'en');
    });
  });
}
