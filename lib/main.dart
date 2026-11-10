import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'menu_screen.dart';

void main() {
  runApp(const LudoApp());
}

class LudoApp extends StatelessWidget {
  const LudoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'لودو',
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      theme: LudoTheme.dark,
      home: const MenuScreen(),
    );
  }
}
