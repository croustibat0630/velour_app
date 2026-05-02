import 'dart:math' as math;

import 'package:flutter/material.dart';

class NeonTimerBar extends StatefulWidget {
  const NeonTimerBar({
    super.key,
    required this.value,
    required this.skinPrimary,
    this.height = 6,
  });

  /// 0..1 time remaining.
  final double value;
  final double height;
  final Color skinPrimary;

  @override
  State<NeonTimerBar> createState() => _NeonTimerBarState();
}

class _NeonTimerBarState extends State<NeonTimerBar>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _blink;
  double _lastValue = 1.0;

  @override
  void initState() {
    super.initState();
    _lastValue = widget.value;
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void didUpdateWidget(covariant NeonTimerBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final double v = widget.value;
    final double prev = _lastValue;
    _lastValue = v;

    // Pulse when time goes UP (match refund).
    if (v > prev + 0.0001) {
      _pulse.forward(from: 0);
    }

    // Blink sous 25 % (urgence critique).
    if (v < 0.25) {
      if (!_blink.isAnimating) {
        _blink.repeat(reverse: true);
      }
    } else {
      if (_blink.isAnimating) {
        _blink.stop();
        _blink.value = 1.0;
      } else if (_blink.value == 0.0) {
        _blink.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _blink.dispose();
    super.dispose();
  }

  Color _tensionColor(double v) {
    if (v > 0.50) return widget.skinPrimary;
    if (v >= 0.25) return const Color(0xFFFF8A34);
    return const Color(0xFFFF2A2A);
  }

  @override
  Widget build(BuildContext context) {
    final double v = widget.value.clamp(0.0, 1.0);
    final Color c = _tensionColor(v);

    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[_pulse, _blink]),
      builder: (context, _) {
        final double pulseT = Curves.easeOutCubic.transform(_pulse.value);
        // Keep a subtle pulse by modulating fill opacity only (flat bars: no glow).
        final double pulse = math.sin(pulseT * math.pi); // 0..1..0
        final double fillA = (0.85 + 0.15 * pulse).clamp(0.0, 1.0);
        final double blinkA = (_blink.isAnimating)
            ? (0.45 + 0.55 * _blink.value)
            : 1.0;

        return Opacity(
          opacity: blinkA,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double maxW = constraints.maxWidth;
              final double width = math.max(1.0, maxW * v);
              Color fillColor = c.withValues(alpha: fillA);
              if (pulseT > 0.004) {
                const Color mint = Color(0xFFB8F5D0);
                const Color flash = Color(0xFFF5FFFA);
                final double k =
                    (0.42 + 0.48 * pulse) * pulseT.clamp(0.0, 1.0);
                fillColor = Color.lerp(
                  fillColor,
                  Color.lerp(mint, flash, pulse * 0.55)!,
                  k.clamp(0.0, 1.0),
                )!;
              }
              return ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: widget.height,
                  width: maxW,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color: Colors.grey.withValues(alpha: 0.10),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          width: width,
                          height: widget.height,
                          child: ColoredBox(
                            color: fillColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

