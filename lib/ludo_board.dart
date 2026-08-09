import 'dart:math';
import 'package:flutter/material.dart';
import 'ludo_data.dart';
import 'ludo_models.dart';

class LudoBoard extends StatelessWidget {
  final List<LudoPlayer> players;
  final List<LudoToken> highlightedTokens;
  final void Function(LudoToken) onTokenTap;

  const LudoBoard({
    super.key,
    required this.players,
    required this.highlightedTokens,
    required this.onTokenTap,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cell = constraints.maxWidth / 15;
          final tokenWidgets = <Widget>[];

          for (final p in players) {
            for (final t in p.tokens) {
              List<int> rc;
              if (t.inBase) {
                final origin = baseOrigin[p.color]!;
                final slot = baseSlots[t.id];
                rc = [origin[0] + slot[0], origin[1] + slot[1]];
              } else if (t.finished) {
                continue;
              } else {
                rc = t.gridPosition!;
              }
              final isHighlighted = highlightedTokens.contains(t);
              tokenWidgets.add(Positioned(
                left: rc[1] * cell + cell * 0.10,
                top: rc[0] * cell + cell * 0.10,
                width: cell * 0.80,
                height: cell * 0.80,
                child: GestureDetector(
                  onTap: isHighlighted ? () => onTokenTap(t) : null,
                  child: _TokenDot(
                    color: p.color.color,
                    highlighted: isHighlighted,
                  ),
                ),
              ));
            }
          }

          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black87, width: 2.5),
              boxShadow: const [
                BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxWidth),
                  painter: _BoardPainter(),
                ),
                ...tokenWidgets,
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TokenDot extends StatelessWidget {
  final Color color;
  final bool highlighted;
  const _TokenDot({required this.color, required this.highlighted});

  @override
  Widget build(BuildContext context) {
    final darker = Color.lerp(color, Colors.black, 0.25)!;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [Color.lerp(color, Colors.white, 0.45)!, color, darker],
          stops: const [0.0, 0.55, 1.0],
        ),
        border: Border.all(
          color: highlighted ? Colors.white : Colors.black54,
          width: highlighted ? 3 : 1.5,
        ),
        boxShadow: highlighted
            ? [
                BoxShadow(color: color.withOpacity(0.95), blurRadius: 10, spreadRadius: 1.5),
                const BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
              ]
            : const [BoxShadow(color: Colors.black38, blurRadius: 3, offset: Offset(0, 1.5))],
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 15;
    final bg = Paint()..color = const Color(0xFFFAF7F0);
    canvas.drawRect(Offset.zero & size, bg);

    _drawBase(canvas, cell, baseOrigin[PlayerColor.red]!, PlayerColor.red.color);
    _drawBase(canvas, cell, baseOrigin[PlayerColor.green]!, PlayerColor.green.color);
    _drawBase(canvas, cell, baseOrigin[PlayerColor.yellow]!, PlayerColor.yellow.color);
    _drawBase(canvas, cell, baseOrigin[PlayerColor.blue]!, PlayerColor.blue.color);

    final gridPaint = Paint()
      ..color = Colors.black26
      ..strokeWidth = 1;

    final pathCells = <List<int>>[...mainPath];
    for (final entry in homeColumns.entries) {
      pathCells.addAll(entry.value);
    }
    for (final rc in pathCells) {
      final rect = Rect.fromLTWH(rc[1] * cell, rc[0] * cell, cell, cell);
      final pathIdx = mainPath.contains(rc) ? mainPath.indexOf(rc) : -1;
      final isSafe = pathIdx != -1 && safeIndices.contains(pathIdx);
      canvas.drawRect(rect, Paint()..color = isSafe ? const Color(0xFFEDE6D6) : Colors.white);
      canvas.drawRect(rect, gridPaint..style = PaintingStyle.stroke);
      if (isSafe) {
        _drawStar(canvas, rect.center, cell * 0.28, Colors.amber.shade700);
      }
    }

    for (final entry in homeColumns.entries) {
      final tint = entry.key.color.withOpacity(0.4);
      for (final rc in entry.value) {
        final rect = Rect.fromLTWH(rc[1] * cell, rc[0] * cell, cell, cell);
        canvas.drawRect(rect, Paint()..color = tint);
        canvas.drawRect(rect, gridPaint..style = PaintingStyle.stroke);
      }
    }

    for (final entry in startIndex.entries) {
      final rc = mainPath[entry.value];
      final rect = Rect.fromLTWH(rc[1] * cell, rc[0] * cell, cell, cell);
      canvas.drawRect(rect, Paint()..color = entry.key.color.withOpacity(0.6));
      canvas.drawRect(rect, gridPaint..style = PaintingStyle.stroke);
      _drawStar(canvas, rect.center, cell * 0.3, Colors.white);
    }

    final cx = 7.5 * cell;
    final cy = 7.5 * cell;
    final half = 1.5 * cell;
    final topLeft = Offset(cx - half, cy - half);
    final topRight = Offset(cx + half, cy - half);
    final bottomLeft = Offset(cx - half, cy + half);
    final bottomRight = Offset(cx + half, cy + half);
    final center = Offset(cx, cy);

    _fillTriangle(canvas, [topLeft, topRight, center], PlayerColor.green.color);
    _fillTriangle(canvas, [topRight, bottomRight, center], PlayerColor.yellow.color);
    _fillTriangle(canvas, [bottomRight, bottomLeft, center], PlayerColor.blue.color);
    _fillTriangle(canvas, [bottomLeft, topLeft, center], PlayerColor.red.color);

    final centerRect = Rect.fromLTWH(6 * cell, 6 * cell, 3 * cell, 3 * cell);
    canvas.drawRect(centerRect, Paint()..color = Colors.black87..style = PaintingStyle.stroke..strokeWidth = 2.5);
  }

  void _fillTriangle(Canvas canvas, List<Offset> points, Color color) {
    final path = Path()..addPolygon(points, true);
    canvas.drawPath(path, Paint()..color = color.withOpacity(0.85));
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    const points = 5;
    final innerRadius = radius * 0.45;
    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : innerRadius;
      final angle = (pi / points) * i - pi / 2;
      final offset = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
      if (i == 0) {
        path.moveTo(offset.dx, offset.dy);
      } else {
        path.lineTo(offset.dx, offset.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color.withOpacity(0.9));
  }

  void _drawBase(Canvas canvas, double cell, List<int> origin, Color color) {
    final outerRect = Rect.fromLTWH(origin[1] * cell, origin[0] * cell, cell * 6, cell * 6);
    final outerRRect = RRect.fromRectAndRadius(outerRect, Radius.circular(cell * 0.4));
    canvas.drawRRect(outerRRect, Paint()..color = color.withOpacity(0.28));
    canvas.drawRRect(outerRRect, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 3);

    final inner = Rect.fromLTWH(origin[1] * cell + cell * 0.85, origin[0] * cell + cell * 0.85,
        cell * 4.3, cell * 4.3);
    final innerRRect = RRect.fromRectAndRadius(inner, Radius.circular(cell * 0.3));
    canvas.drawRRect(innerRRect, Paint()..color = Colors.white);
    canvas.drawRRect(innerRRect, Paint()..color = color.withOpacity(0.6)..style = PaintingStyle.stroke..strokeWidth = 1.5);

    for (final slot in baseSlots) {
      final slotCenter = Offset(
        (origin[1] + slot[1] + 0.5) * cell,
        (origin[0] + slot[0] + 0.5) * cell,
      );
      canvas.drawCircle(slotCenter, cell * 0.32, Paint()..color = color.withOpacity(0.15));
      canvas.drawCircle(
        slotCenter,
        cell * 0.32,
        Paint()
          ..color = color.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
