import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/responsive.dart';

/// Compact level readout for the in-game HUD (pairs with [NeonScoreBoard]).
class NeonLevelBadge extends StatefulWidget {
  const NeonLevelBadge({super.key, required this.level});

  final int level;

  /// Width reserved for layout / spawn safe-zone (gap to score is outside this).
  static const double layoutWidth = 58;

  @override
  State<NeonLevelBadge> createState() => _NeonLevelBadgeState();
}

class _NeonLevelBadgeState extends State<NeonLevelBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double sT = Responsive.textScale(context);
    // Keep badge readable on dense screens; avoid tiny readout.
    final double w = (NeonLevelBadge.layoutWidth * sT).clamp(54.0, 72.0);
    final double labelSize = (10 * sT).clamp(9.0, 12.0);
    final double levelSize = (28 * sT).clamp(20.0, 34.0);
    final double gap2 = (2 * Responsive.heightScale(context)).clamp(1.0, 3.0);
    return SizedBox(
      width: w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'LEVEL',
            style: GoogleFonts.montserrat(
              fontSize: labelSize,
              letterSpacing: 3,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.42),
            ),
          ),
          SizedBox(height: gap2),
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              final double w =
                  math.sin(_pulse.value * math.pi * 2) * 0.5 + 0.5;
              final double glowA = 0.42 + 0.18 * w;
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, anim) {
                  return FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.92, end: 1.0).animate(anim),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  '${widget.level}',
                  key: ValueKey<int>(widget.level),
                  style: GoogleFonts.montserrat(
                    fontSize: levelSize,
                    height: 0.95,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF00FFFF),
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: (5 * sT).clamp(4.0, 7.0),
                        offset: const Offset(0, 1),
                      ),
                      Shadow(
                        color: const Color(0xFF00FFFF).withValues(alpha: glowA),
                        blurRadius: (8 * sT).clamp(6.0, 12.0),
                      ),
                      Shadow(
                        color: const Color(0x6600FFFF)
                            .withValues(alpha: 0.55 * glowA),
                        blurRadius: (16 * sT).clamp(12.0, 24.0),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
