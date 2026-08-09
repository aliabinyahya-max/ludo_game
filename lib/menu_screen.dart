import 'package:flutter/material.dart';
import 'ludo_data.dart';
import 'game_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  // true = seat active, value = isAI
  final Map<PlayerColor, bool?> seatState = {
    PlayerColor.red: false, // human
    PlayerColor.green: true, // AI
    PlayerColor.yellow: null, // empty
    PlayerColor.blue: null, // empty
  };

  void _cycle(PlayerColor c) {
    setState(() {
      final current = seatState[c];
      if (current == null) {
        seatState[c] = false; // -> human
      } else if (current == false) {
        seatState[c] = true; // -> AI
      } else {
        seatState[c] = null; // -> empty
      }
    });
  }

  String _label(bool? v) {
    if (v == null) return 'فارغ';
    return v ? 'كمبيوتر' : 'لاعب (هذا الجهاز)';
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = seatState.values.where((v) => v != null).length;
    final humanCount = seatState.values.where((v) => v == false).length;

    return Scaffold(
      appBar: AppBar(title: const Text('لودو - إعداد اللعبة')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'اختر لكل لون: لاعب (تمرير الجوال بين الأصدقاء) أو كمبيوتر أو فارغ.\nاضغط على المربع لتغيير حالته.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            ...PlayerColor.values.map((c) {
              final v = seatState[c];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  onTap: () => _cycle(c),
                  leading: CircleAvatar(backgroundColor: c.color),
                  title: Text(c.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Chip(label: Text(_label(v))),
                ),
              );
            }),
            const SizedBox(height: 24),
            Text(
              humanCount >= 1
                  ? '$activeCount لاعبين نشطين — $humanCount منهم بشرًا (تمرير نفس الجوال بينكم)'
                  : 'اختر لاعبًا بشريًا واحدًا على الأقل',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: (activeCount >= 2 && humanCount >= 1)
                  ? () {
                      final seats = <PlayerColor, bool>{};
                      seatState.forEach((k, v) {
                        if (v != null) seats[k] = v;
                      });
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => GameScreen(seats: seats)),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('ابدأ اللعبة', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
