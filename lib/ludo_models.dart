import 'ludo_data.dart';

/// Current location/state of a token.
enum LudoTokenState {
  base,
  path,
  homeColumn,
  finished,
}

/// A single Ludo token.
class LudoToken {
  final PlayerColor color;
  final int id; // 0..3, matches baseSlots index

  /// Logical progress:
  /// -1   = base
  /// 0-51 = shared outer path
  /// 52-56 = home column
  /// 57   = finished
  int step;

  LudoToken({
    required this.color,
    required this.id,
    this.step = baseStep,
  });

  LudoTokenState get state {
    if (step == baseStep) return LudoTokenState.base;
    if (step >= 0 && step < homeEntryStep) {
      return LudoTokenState.path;
    }
    if (step >= homeEntryStep && step < finishedStep) {
      return LudoTokenState.homeColumn;
    }
    if (step == finishedStep) return LudoTokenState.finished;

    throw StateError('Invalid token step: $step');
  }

  bool get inBase => state == LudoTokenState.base;

  bool get onPath => state == LudoTokenState.path;

  bool get inHomeColumn => state == LudoTokenState.homeColumn;

  bool get finished => state == LudoTokenState.finished;

  bool get onBoard => onPath || inHomeColumn;

  /// Global shared-path index, or null when not on the shared path.
  int? get globalPathIndex {
    if (!onPath) return null;
    return (startIndex[color]! + step) % mainPathLength;
  }

  /// Global [row, column] board position.
  List<int>? get gridPosition {
    if (inBase || finished) return null;

    if (onPath) {
      return mainPath[globalPathIndex!];
    }

    final homeIndex = step - homeEntryStep;

    if (homeIndex < 0 || homeIndex >= homeColumnLength) {
      throw StateError('Invalid home-column step: $step');
    }

    return homeColumns[color]![homeIndex];
  }

  /// Creates a copy with the same identity and an optional new step.
  LudoToken copyWith({int? step}) {
    return LudoToken(
      color: color,
      id: id,
      step: step ?? this.step,
    );
  }
}

/// A player participating in the current game.
class LudoPlayer {
  final PlayerColor color;
  final bool isAI;
  final List<LudoToken> tokens;

  LudoPlayer({
    required this.color,
    required this.isAI,
  }) : tokens = List.generate(
          4,
          (i) => LudoToken(
            color: color,
            id: i,
          ),
        );

  bool get hasWon => tokens.every((token) => token.finished);

  int get baseTokenCount => tokens.where((token) => token.inBase).length;

  int get pathTokenCount => tokens.where((token) => token.onPath).length;

  int get homeColumnTokenCount =>
      tokens.where((token) => token.inHomeColumn).length;

  int get finishedTokenCount => tokens.where((token) => token.finished).length;
}
