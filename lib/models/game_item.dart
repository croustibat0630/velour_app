import 'dart:ui' show Offset;

class GameItem {
  final String id;

  /// Shape id (1..N).
  final int typeId;

  /// Neon color id (1..M), independent from shape.
  final int colorId;
  final Offset position;
  final bool isSelected;

  /// Per-item float cycle duration (board only).
  final int floatPeriodMs;

  /// Random start offset in [0,1).
  final double floatPhase;

  const GameItem({
    required this.id,
    required this.typeId,
    required this.colorId,
    required this.position,
    this.isSelected = false,
    this.floatPeriodMs = 4000,
    this.floatPhase = 0.0,
  });
}
