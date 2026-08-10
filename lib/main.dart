import 'package:flutter/material.dart';

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
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C5CE7),
          brightness: Brightness.light,
        ),
      ),
      home: const GameSetupScreen(),
    );
  }
}

class GameSetupScreen extends StatefulWidget {
  const GameSetupScreen({super.key});

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  final List<Map<String, dynamic>> _players = [
    {'color': const Color(0xFFFF4757), 'name': 'أحمر', 'type': 'لاعب (هذا الجهاز)'},
    {'color': const Color(0xFF2ED573), 'name': 'أخضر', 'type': 'كمبيوتر'},
    {'color': const Color(0xFFFFA502), 'name': 'أصفر', 'type': 'فارغ'},
    {'color': const Color(0xFF1E90FF), 'name': 'أزرق', 'type': 'فارغ'},
  ];

  final List<String> _typeOptions = ['لاعب (هذا الجهاز)', 'كمبيوتر', 'فارغ'];

  void _togglePlayerType(int index) {
    setState(() {
      int currentIndex = _typeOptions.indexOf(_players[index]['type']);
      int nextIndex = (currentIndex + 1) % _typeOptions.length;
      _players[index]['type'] = _typeOptions[nextIndex];
    });
  }

  int get _activeCount => _players.where((p) => p['type'] != 'فارغ').length;
  int get _humanCount => _players.where((p) => p['type'] == 'لاعب (هذا الجهاز)').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('لودو - إعداد اللعبة', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            children: [
              const Text(
                'اختر لكل لون: لاعب (تمرير الجوال) أو كمبيوتر أو فارغ.
اضغط على المربع لتغيير حالته.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: _players.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final player = _players[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: player['color'],
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (player['color'] as Color).withOpacity(0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            player['name'],
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: () => _togglePlayerType(index),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F2F6),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.black12),
                              ),
                              child: Text(
                                player['type'],
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black80),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Text(
                'لاعبين نشطين —  منهم بشراً (تمرير نفس الجوال بينكم) ',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black60),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _activeCount >= 2 ? () {} : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  child: const Text('ابدأ اللعبة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
