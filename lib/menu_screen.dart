import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'game_screen.dart';
import 'ludo_data.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  // null = empty seat, false = human, true = computer.
  final Map<PlayerColor, bool?> seatState = {
    PlayerColor.red: false,
    PlayerColor.green: true,
    PlayerColor.yellow: null,
    PlayerColor.blue: null,
  };

  void _cycle(PlayerColor color) {
    setState(() {
      final current = seatState[color];
      if (current == null) {
        seatState[color] = false;
      } else if (current == false) {
        seatState[color] = true;
      } else {
        seatState[color] = null;
      }
    });
  }

  String _seatLabel(bool? value) {
    if (value == null) return 'مقعد فارغ';
    return value ? 'الكمبيوتر' : 'لاعب بشري';
  }

  IconData _seatIcon(bool? value) {
    if (value == null) return Icons.person_add_alt_1_rounded;
    return value ? Icons.smart_toy_rounded : Icons.person_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = seatState.values.where((value) => value != null).length;
    final humanCount = seatState.values.where((value) => value == false).length;
    final canStart = activeCount >= 2 && humanCount >= 1;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth >= 600 ? 36.0 : 20.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 22, horizontalPadding, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildBrandHeader(),
                      const SizedBox(height: 28),
                      _buildHeroPanel(),
                      const SizedBox(height: 28),
                      _buildSectionHeader(
                        title: 'تجهيز المباراة',
                        subtitle: 'اختر من سيشارك في اللعب',
                      ),
                      const SizedBox(height: 14),
                      ...PlayerColor.values.map(_buildSeatCard),
                      const SizedBox(height: 18),
                      _buildPlayerSummary(
                        activeCount: activeCount,
                        humanCount: humanCount,
                        canStart: canStart,
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        onPressed: canStart ? _startGame : null,
                        icon: const Icon(Icons.play_arrow_rounded, size: 26),
                        label: const Text('ابدأ المباراة'),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'اللعب المحلي • من لاعبين إلى أربعة لاعبين',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [LudoTheme.emeraldLight, LudoTheme.emerald],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(17),
            boxShadow: [
              BoxShadow(
                color: LudoTheme.emerald.withValues(alpha: 0.28),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.casino_rounded, color: Colors.white, size: 29),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('LUDO', style: Theme.of(context).textTheme.titleLarge),
              Text('اللعب يجمعنا', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: LudoTheme.gold.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: LudoTheme.gold.withValues(alpha: 0.35)),
          ),
          child: const Text(
            'PREMIUM',
            style: TextStyle(
              color: LudoTheme.gold,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroPanel() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF194431), Color(0xFF10251D), Color(0xFF0C1D16)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: LudoTheme.emerald.withValues(alpha: 0.38)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.emoji_events_rounded, color: LudoTheme.gold, size: 25),
          ),
          const SizedBox(height: 17),
          Text('مستعد للتحدي؟', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 7),
          Text(
            'جهّز مقاعد اللاعبين وابدأ جولة لودو مع الأصدقاء أو الكمبيوتر.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FeaturePill(icon: Icons.groups_rounded, label: '2–4 لاعبين'),
              _FeaturePill(icon: Icons.wifi_off_rounded, label: 'بدون إنترنت'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 3),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildSeatCard(PlayerColor color) {
    final value = seatState[color];
    final seatColor = color.color;
    final isEmpty = value == null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        key: ValueKey('seat-' + color.name),
        borderRadius: BorderRadius.circular(22),
        onTap: () => _cycle(color),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: seatColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: seatColor.withValues(alpha: 0.55)),
                ),
                child: Icon(Icons.circle, color: seatColor, size: 19),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(color.label, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(_seatLabel(value), style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                decoration: BoxDecoration(
                  color: isEmpty ? LudoTheme.surfaceElevated : LudoTheme.emerald.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: isEmpty ? LudoTheme.outline : LudoTheme.emerald),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _seatIcon(value),
                      size: 16,
                      color: isEmpty ? LudoTheme.textSecondary : LudoTheme.emeraldLight,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isEmpty ? 'إضافة' : (value ? 'كمبيوتر' : 'بشري'),
                      style: TextStyle(
                        color: isEmpty ? LudoTheme.textSecondary : LudoTheme.emeraldLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.touch_app_rounded, size: 17, color: LudoTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerSummary({
    required int activeCount,
    required int humanCount,
    required bool canStart,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LudoTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LudoTheme.outline),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: LudoTheme.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              canStart
                  ? '$activeCount مقاعد مشاركة • $humanCount لاعب بشري'
                  : humanCount == 0
                      ? 'أضف لاعباً بشرياً واحداً على الأقل'
                      : 'أضف مقعداً ثانياً لبدء المباراة',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: canStart ? LudoTheme.emeraldLight : LudoTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Text(
            '$activeCount/4',
            style: const TextStyle(color: LudoTheme.gold, fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  void _startGame() {
    final seats = <PlayerColor, bool>{};
    seatState.forEach((color, isAI) {
      if (isAI != null) seats[color] = isAI;
    });
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GameScreen(seats: seats)),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: LudoTheme.gold),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: LudoTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
