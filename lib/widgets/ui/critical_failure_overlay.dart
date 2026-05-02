import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../utils/responsive.dart';

class CriticalFailureOverlay extends StatefulWidget {
  const CriticalFailureOverlay({
    super.key,
    required this.onReset,
  });

  final VoidCallback onReset;

  @override
  State<CriticalFailureOverlay> createState() => _CriticalFailureOverlayState();
}

class _CriticalFailureOverlayState extends State<CriticalFailureOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flash;

  @override
  void initState() {
    super.initState();
    _flash = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    )..repeat();
  }

  @override
  void dispose() {
    _flash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double s = Responsive.compactHeightScale(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(
          color: Color(0x66FF0000),
        ),
        // Shift below top HUD (LUX + safe zone) so titles never collide with the score.
        Align(
          alignment: const Alignment(0, 0.22),
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, 96 * s, 18, 0),
            child: AnimatedBuilder(
              animation: _flash,
              builder: (context, _) {
                final double flash =
                    (math.sin(_flash.value * math.pi * 2) * 0.5 + 0.5);
                final double a = 0.55 + 0.35 * flash;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LayoutBuilder(
                      builder: (context, c) {
                        final double w = c.maxWidth;
                        final double size =
                            ((w * 0.095).clamp(16, 44)) * s;
                        return FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Opacity(
                            opacity: a,
                            child: Text(
                              'SYSTEM OVERCHARGE',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: size,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3.5,
                                height: 0.95,
                                color: const Color(0xFFFF2A2A),
                                shadows: const [
                                  Shadow(
                                    color: Color(0xFFFF2A2A),
                                    blurRadius: 18,
                                  ),
                                  Shadow(
                                    color: Color(0x66FF0000),
                                    blurRadius: 40,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 10 * s),
                    Opacity(
                      opacity: a,
                      child: Text(
                        'CONNECTION LOST',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13 * s,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4,
                          color: Color(0xFFFF2A2A),
                          shadows: [
                            Shadow(color: Color(0x66FF0000), blurRadius: 24),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 22 * s),
                    OutlinedButton(
                      onPressed: widget.onReset,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF00FFFF),
                        side: const BorderSide(
                          color: Color(0xFF00FFFF),
                          width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        'REINITIALISER LE SYSTEME',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                          fontSize: 14 * s,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
