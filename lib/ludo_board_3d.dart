import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

import 'ludo_data.dart';
import 'ludo_models.dart';

/// A real-time 3D Ludo board. The rules engine remains outside this widget;
/// this class only projects token state into the 3D scene and routes taps back
/// to the existing legal-move callback.
class LudoBoard3D extends StatefulWidget {
  final List<LudoPlayer> players;
  final List<LudoToken> highlightedTokens;
  final void Function(LudoToken) onTokenTap;
  final bool rolling;

  const LudoBoard3D({
    super.key,
    required this.players,
    required this.highlightedTokens,
    required this.onTokenTap,
    this.rolling = false,
  });

  @override
  State<LudoBoard3D> createState() => _LudoBoard3DState();
}

class _LudoBoard3DState extends State<LudoBoard3D> {
  late final three.ThreeJS threeJs;
  final Map<String, three.Group> _tokenMeshes = {};
  final Map<String, three.Mesh> _tokenRings = {};
  final Map<String, List<double>> _targets = {};
  double _elapsed = 0;
  bool _ready = false;

  static const Map<PlayerColor, int> _colors = {
    PlayerColor.red: 0xFFE53935,
    PlayerColor.green: 0xFF43A047,
    PlayerColor.yellow: 0xFFFDD835,
    PlayerColor.blue: 0xFF1E88E5,
  };

  @override
  void initState() {
    super.initState();
    threeJs = three.ThreeJS(
      onSetupComplete: () {
        if (mounted) setState(() => _ready = true);
      },
      setup: _setupScene,
    );
  }

  Future<void> _setupScene() async {
    final scene = three.Scene();
    threeJs.scene = scene;

    final camera = three.OrthographicCamera(-8.15, 8.15, 8.15, -8.15, 0.1, 80);
    camera.position.setValues(0, 26, 0.001);
    camera.up.setValues(0, 0, -1);
    camera.lookAt(three.Vector3(0, 0, 0));
    threeJs.camera = camera;

    scene.add(three.AmbientLight(0xffffff, 1.1));
    final keyLight = three.DirectionalLight(0xffffff, 1.0);
    keyLight.position.setValues(-7, 18, 9);
    scene.add(keyLight);

    _addBox(scene, 15.35, 0.42, 15.35, 0x071711, 0, -0.25, 0);

    // Four raised, inset home quadrants.
    _addBox(scene, 5.95, 0.18, 5.95, _colors[PlayerColor.red]!, -4.5, 0, -4.5);
    _addBox(scene, 5.95, 0.18, 5.95, _colors[PlayerColor.green]!, 4.5, 0, -4.5);
    _addBox(scene, 5.95, 0.18, 5.95, _colors[PlayerColor.yellow]!, 4.5, 0, 4.5);
    _addBox(scene, 5.95, 0.18, 5.95, _colors[PlayerColor.blue]!, -4.5, 0, 4.5);

    // Raised home pads and their four recessed token sockets.
    for (final entry in baseOrigin.entries) {
      final origin = entry.value;
      _addBox(
        scene, 4.45, 0.12, 4.45, 0xFFF8F3E8,
        origin[1] - 7 + 2.5, 0.12, origin[0] - 7 + 2.5,
      );
      for (final slot in baseSlots) {
        _addCylinder(
          scene, 0.39, 0.08, 0xFFD9D4C9,
          origin[1] - 7 + slot[1] + 0.5,
          0.22,
          origin[0] - 7 + slot[0] + 0.5,
        );
      }
    }

    // Shared route and the five colored home-lane cells per player.
    for (var i = 0; i < mainPath.length; i++) {
      final rc = mainPath[i];
      final safe = safeIndices.contains(i);
      _addTile(
        scene, rc[1] - 7, rc[0] - 7,
        safe ? 0xFFFFE8B2 : 0xFFF9F6EF,
        height: safe ? 0.25 : 0.16,
      );
      if (safe) {
        _addCylinder(scene, 0.19, 0.035, 0xFFE0AD45,
            rc[1] - 7, 0.22, rc[0] - 7);
      }
    }
    for (final entry in homeColumns.entries) {
      for (final rc in entry.value) {
        _addTile(scene, rc[1] - 7, rc[0] - 7, _colors[entry.key]!,
            height: 0.24);
      }
    }

    // Start cells are marked with a raised gold inset.
    for (final entry in startIndex.entries) {
      final rc = mainPath[entry.value];
      _addCylinder(scene, 0.27, 0.07, 0xFFFFD36A,
          rc[1] - 7, 0.27, rc[0] - 7);
    }

    // A four-part raised destination in the centre.
    _addBox(scene, 2.8, 0.22, 2.8, 0xFFE4BD70, 0, 0.08, 0);
    _addBox(scene, 1.25, 0.08, 1.25, 0xFF10251D, 0, 0.22, 0);

    _createTokenMeshes();
    _syncTokenTargets();

    threeJs.addAnimationEvent((dt) {
      _elapsed += dt;
      final blend = math.min(1.0, dt * 13.0).toDouble();
      for (final player in widget.players) {
        for (final token in player.tokens) {
          final key = _tokenKey(token);
          final mesh = _tokenMeshes[key];
          final target = _targets[key];
          if (mesh == null || target == null) continue;

          mesh.position.x += (target[0] - mesh.position.x) * blend;
          mesh.position.y += (target[1] - mesh.position.y) * blend;
          mesh.position.z += (target[2] - mesh.position.z) * blend;
          mesh.rotation.y += dt * 0.45;

          final highlighted = widget.highlightedTokens.contains(token);
          final ring = _tokenRings[key];
          if (ring != null) {
            final pulse = highlighted ? 1.0 + math.sin(_elapsed * 5.5) * 0.10 : 1.0;
            ring.scale.setValues(pulse, 1, pulse);
          }
        }
      }
    });
  }

  void _addBox(
    three.Scene scene,
    double width,
    double height,
    double depth,
    int color,
    double x,
    double y,
    double z,
  ) {
    final mesh = three.Mesh(
      three.BoxGeometry(width, height, depth),
      three.MeshBasicMaterial({three.MaterialProperty.color: color}),
    );
    mesh.position.setValues(x, y, z);
    scene.add(mesh);
  }

  void _addCylinder(
    three.Scene scene,
    double radius,
    double height,
    int color,
    double x,
    double y,
    double z,
  ) {
    final mesh = three.Mesh(
      three.CylinderGeometry(radius, radius, height, 24),
      three.MeshBasicMaterial({three.MaterialProperty.color: color}),
    );
    mesh.position.setValues(x, y, z);
    scene.add(mesh);
  }

  void _addTile(three.Scene scene, double x, double z, int color,
      {double height = 0.16}) {
    _addBox(scene, 0.91, height, 0.91, color, x, 0.12, z);
    final edge = three.Mesh(
      three.BoxGeometry(0.94, 0.035, 0.94),
      three.MeshBasicMaterial({three.MaterialProperty.color: 0xFFB8B2A8}),
    );
    edge.position.setValues(x, 0.055, z);
    scene.add(edge);
  }

  String _tokenKey(LudoToken token) => '${token.color.name}-${token.id}';

  void _createTokenMeshes() {
    for (final player in widget.players) {
      for (final token in player.tokens) {
        final key = _tokenKey(token);
        final group = three.Group();
        final color = _colors[token.color]!;

        final ring = three.Mesh(
          three.CylinderGeometry(0.39, 0.39, 0.055, 28),
          three.MeshBasicMaterial({three.MaterialProperty.color: 0xFFFFD36A}),
        );
        ring.position.y = 0.23;
        group.add(ring);
        _tokenRings[key] = ring;

        final body = three.Mesh(
          three.CylinderGeometry(0.27, 0.31, 0.28, 24),
          three.MeshBasicMaterial({three.MaterialProperty.color: color}),
        );
        body.position.y = 0.39;
        group.add(body);

        final crown = three.Mesh(
          three.SphereGeometry(0.235, 20, 14),
          three.MeshBasicMaterial({three.MaterialProperty.color: color}),
        );
        crown.position.y = 0.59;
        group.add(crown);

        threeJs.scene.add(group);
        _tokenMeshes[key] = group;
      }
    }
  }

  List<int>? _cellFor(LudoToken token) {
    if (token.finished) return null;
    if (token.inBase) {
      final origin = baseOrigin[token.color]!;
      final slot = baseSlots[token.id];
      return [origin[0] + slot[0], origin[1] + slot[1]];
    }
    return token.gridPosition;
  }

  List<double> _positionFor(LudoToken token) {
    if (token.finished) {
      final offset = (token.id - 1.5) * 0.31;
      return [offset, 0.30, offset];
    }
    final cell = _cellFor(token)!;
    return [cell[1] - 7.0, 0.30, cell[0] - 7.0];
  }

  void _syncTokenTargets() {
    for (final player in widget.players) {
      for (final token in player.tokens) {
        final key = _tokenKey(token);
        final target = _positionFor(token);
        _targets[key] = target;
        final mesh = _tokenMeshes[key];
        if (mesh != null && mesh.position.y == 0) {
          mesh.position.setValues(target[0], target[1], target[2]);
        }
      }
    }
  }

  @override
  void didUpdateWidget(covariant LudoBoard3D oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTokenTargets();
  }

  void _handleBoardTap(TapUpDetails details, Size size) {
    // The orthographic camera frames 16.3 world units while the board spans
    // 15 units. Convert the tap back into board-cell coordinates so the
    // transparent input layer aligns with the visible 3D tiles.
    final worldX = details.localPosition.dx / size.width * 16.3 - 8.15;
    final worldZ = details.localPosition.dy / size.height * 16.3 - 8.15;
    final column = (worldX + 7).round().clamp(0, boardSize - 1);
    final row = (worldZ + 7).round().clamp(0, boardSize - 1);

    for (final token in widget.highlightedTokens) {
      final cell = _cellFor(token);
      if (cell != null && cell[0] == row && cell[1] == column) {
        widget.onTokenTap(token);
        return;
      }
    }
  }

  @override
  void dispose() {
    threeJs.dispose();
    three.loading.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                IgnorePointer(child: threeJs.build()),
                if (!_ready)
                  const ColoredBox(
                    color: Color(0xFF10251D),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF35D394),
                      ),
                    ),
                  ),
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapUp: (details) => _handleBoardTap(details, size),
                ),
                if (widget.rolling)
                  const Positioned(
                    top: 12,
                    right: 12,
                    child: Icon(Icons.casino, color: Color(0xFFE4BD70), size: 28),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
