import 'ludo_data.dart';

class LudoToken {
  final PlayerColor color;
  final int id; // 0..3, matches baseSlots index
  int step; // -1 = in base, 0..50 = main path, 51..56 = home column, 57 = finished

  LudoToken({required this.color, required this.id, this.step = -1});

  bool get inBase => step == -1;
  bool get finished => step == finishedStep;
  bool get onBoard => step >= 0 && step < finishedStep;

  /// Global (row, col) position of this token, or null if in base/finished.
  List<int>? get gridPosition {
    if (step < 0 || step >= finishedStep) return null;
    if (step < homeEntryStep) {
      final globalIndex = (startIndex[color]! + step) % mainPath.length;
      return mainPath[globalIndex];
    } else {
      final homeIdx = step - homeEntryStep;
      return homeColumns[color]![homeIdx];
    }
  }
}

class LudoPlayer {
  final PlayerColor color;
  final bool isAI;
  final List<LudoToken> tokens;

  LudoPlayer({required this.color, required this.isAI})
      : tokens = List.generate(4, (i) => LudoToken(color: color, id: i));

  bool get hasWon => tokens.every((t) => t.finished);
}
