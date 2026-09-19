import 'package:flutter/material.dart';

/// The four player colors.
enum PlayerColor {
  red,
  green,
  yellow,
  blue,
}

/// Display and visual properties for each player color.
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

/// Board dimensions.
const int boardSize = 15;

/// Number of shared cells around the outer board.
const int mainPathLength = 52;

/// Number of cells in each player's home column.
const int homeColumnLength = 5;

/// Token step meanings:
/// -1   = token is in base
/// 0-51 = token is on the shared outer path
/// 52-56 = token is in its color home column
/// 57   = token has finished
const int baseStep = -1;
const int homeEntryStep = mainPathLength;
const int finishedStep = mainPathLength + homeColumnLength;
const int totalSteps = finishedStep;

/// Shared outer path as 15x15 [row, column] coordinates.
/// The path is clockwise and contains exactly 52 cells.
const List<List<int>> mainPath = [
  [6, 1],
  [6, 2],
  [6, 3],
  [6, 4],
  [6, 5],
  [5, 6],
  [4, 6],
  [3, 6],
  [2, 6],
  [1, 6],
  [0, 6],
  [0, 7],
  [0, 8],
  [1, 8],
  [2, 8],
  [3, 8],
  [4, 8],
  [5, 8],
  [6, 9],
  [6, 10],
  [6, 11],
  [6, 12],
  [6, 13],
  [6, 14],
  [7, 14],
  [8, 14],
  [8, 13],
  [8, 12],
  [8, 11],
  [8, 10],
  [8, 9],
  [9, 8],
  [10, 8],
  [11, 8],
  [12, 8],
  [13, 8],
  [14, 8],
  [14, 7],
  [14, 6],
  [13, 6],
  [12, 6],
  [11, 6],
  [10, 6],
  [9, 6],
  [8, 5],
  [8, 4],
  [8, 3],
  [8, 2],
  [8, 1],
  [8, 0],
  [7, 0],
  [6, 0],
];

/// Global path index where each color enters the shared path.
const Map<PlayerColor, int> startIndex = {
  PlayerColor.red: 0,
  PlayerColor.green: 13,
  PlayerColor.yellow: 26,
  PlayerColor.blue: 39,
};

/// Safe/star cells on the shared path.
///
/// Tokens standing on these cells cannot be captured.
/// The actual rule set can later override this list for different modes.
const List<int> safeIndices = [
  0,
  8,
  13,
  21,
  26,
  34,
  39,
  47,
];

/// Five home-column cells for each color.
/// These are entered after step 51 and lead toward the center.
const Map<PlayerColor, List<List<int>>> homeColumns = {
  PlayerColor.red: [
    [7, 1],
    [7, 2],
    [7, 3],
    [7, 4],
    [7, 5],
  ],
  PlayerColor.green: [
    [1, 7],
    [2, 7],
    [3, 7],
    [4, 7],
    [5, 7],
  ],
  PlayerColor.yellow: [
    [7, 13],
    [7, 12],
    [7, 11],
    [7, 10],
    [7, 9],
  ],
  PlayerColor.blue: [
    [13, 7],
    [12, 7],
    [11, 7],
    [10, 7],
    [9, 7],
  ],
};

/// Top-left [row, column] coordinate of each 6x6 player base.
const Map<PlayerColor, List<int>> baseOrigin = {
  PlayerColor.red: [0, 0],
  PlayerColor.green: [0, 9],
  PlayerColor.yellow: [9, 9],
  PlayerColor.blue: [9, 0],
};

/// Relative [row, column] positions of the four token slots inside a base.
const List<List<int>> baseSlots = [
  [1, 1],
  [1, 3],
  [3, 1],
  [3, 3],
];
