import 'package:flutter/material.dart';

/// The 4 colors used in the game, in fixed turn order.
enum PlayerColor { red, green, yellow, blue }

extension PlayerColorX on PlayerColor {
  Color get color {
    switch (this) {
      case PlayerColor.red:
        return const Color(0xFFE53935);
      case PlayerColor.green:
        return const Color(0xFF43A047);
      case PlayerColor.yellow:
        return const Color(0xFFFDD835);
      case PlayerColor.blue:
        return const Color(0xFF1E88E5);
    }
  }

  String get label {
    switch (this) {
      case PlayerColor.red:
        return 'أحمر';
      case PlayerColor.green:
        return 'أخضر';
      case PlayerColor.yellow:
        return 'أصفر';
      case PlayerColor.blue:
        return 'أزرق';
    }
  }
}

/// Board is modeled as a 15x15 grid (row, col), 0-indexed.
/// The 52-cell outer path, shared by all players, going clockwise.
const List<List<int>> mainPath = [
  [6, 1], [6, 2], [6, 3], [6, 4], [6, 5],
  [5, 6], [4, 6], [3, 6], [2, 6], [1, 6], [0, 6],
  [0, 7],
  [0, 8], [1, 8], [2, 8], [3, 8], [4, 8], [5, 8],
  [6, 9], [6, 10], [6, 11], [6, 12], [6, 13], [6, 14],
  [7, 14],
  [8, 14], [8, 13], [8, 12], [8, 11], [8, 10], [8, 9],
  [9, 8], [10, 8], [11, 8], [12, 8], [13, 8], [14, 8],
  [14, 7],
  [14, 6], [13, 6], [12, 6], [11, 6], [10, 6], [9, 6],
  [8, 5], [8, 4], [8, 3], [8, 2], [8, 1], [8, 0],
  [7, 0],
  [6, 0],
];

/// Index on [mainPath] where each color leaves its base.
const Map<PlayerColor, int> startIndex = {
  PlayerColor.red: 0,
  PlayerColor.green: 13,
  PlayerColor.yellow: 26,
  PlayerColor.blue: 39,
};

/// Star / safe cells: no token can be captured while sitting here.
const List<int> safeIndices = [0, 8, 13, 21, 26, 34, 39, 47];

/// Home column (6 cells) for each color, leading into the center.
const Map<PlayerColor, List<List<int>>> homeColumns = {
  PlayerColor.red: [
    [7, 1], [7, 2], [7, 3], [7, 4], [7, 5], [7, 6],
  ],
  PlayerColor.green: [
    [1, 7], [2, 7], [3, 7], [4, 7], [5, 7], [6, 7],
  ],
  PlayerColor.yellow: [
    [7, 13], [7, 12], [7, 11], [7, 10], [7, 9], [7, 8],
  ],
  PlayerColor.blue: [
    [13, 7], [12, 7], [11, 7], [10, 7], [9, 7], [8, 7],
  ],
};

/// Base (home yard) area top-left corner, per color, for drawing the
/// 4 waiting tokens before they enter the board. Each base is a 6x6 area.
const Map<PlayerColor, List<int>> baseOrigin = {
  PlayerColor.red: [0, 0],
  PlayerColor.green: [0, 9],
  PlayerColor.yellow: [9, 9],
  PlayerColor.blue: [9, 0],
};

/// Relative slot offsets (within the 6x6 base) for the 4 tokens.
const List<List<int>> baseSlots = [
  [1, 1], [1, 3], [3, 1], [3, 3],
];

/// Total steps a token must travel: 51 main-path steps (0..50) plus
/// 6 home column cells (51..56); 57 means "finished / home".
const int totalSteps = 57;
const int homeEntryStep = 51;
const int finishedStep = 57;
