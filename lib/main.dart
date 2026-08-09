import 'package:flutter/material.dart';
import 'menu_screen.dart';

void main() {
  runApp(const LudoApp());
}

class LudoApp extends StatelessWidget {
  const LudoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'لودو',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        fontFamily: 'Arial',
      ),
      locale: const Locale('ar'),
      home: const MenuScreen(),
    );
  }
}
