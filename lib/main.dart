import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'local_game_store.dart';
import 'menu_screen.dart';

void main() {
  runApp(const LudoApp());
}

class LudoApp extends StatefulWidget {
  const LudoApp({super.key});

  @override
  State<LudoApp> createState() => _LudoAppState();
}

class _LudoAppState extends State<LudoApp> {
  final LocalGameStore _store = LocalGameStore();
  String _themeName = 'emerald';
  String _languageCode = 'ar';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final values = await Future.wait([
      _store.themeName(),
      _store.languageCode(),
    ]);
    if (!mounted) return;
    setState(() {
      _themeName = values[0] as String;
      _languageCode = values[1] as String;
    });
  }

  void _changeTheme(String value) {
    setState(() => _themeName = value);
    _store.setThemeName(value);
  }

  void _changeLanguage(String value) {
    setState(() => _languageCode = value);
    _store.setLanguageCode(value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: _languageCode == 'en' ? 'Ludo' : 'لودو',
      locale: Locale(_languageCode),
      supportedLocales: const [Locale('ar'), Locale('en')],
      theme: LudoTheme.forName(_themeName),
      builder: (context, child) => Directionality(
        textDirection:
            _languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        child: child ?? const SizedBox.shrink(),
      ),
      home: MenuScreen(
        themeName: _themeName,
        languageCode: _languageCode,
        onThemeChanged: _changeTheme,
        onLanguageChanged: _changeLanguage,
      ),
    );
  }
}
