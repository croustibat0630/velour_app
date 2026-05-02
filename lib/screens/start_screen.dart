import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/game_state.dart';
import '../utils/responsive.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();

    // Fire-and-forget: load persisted high score for the footer.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameState>().loadHighScore();
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double scaleH = Responsive.compactHeightScale(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, 0.10),
                    radius: 1.2,
                    colors: [Color(0xFF0B1020), Color(0xFF000000)],
                  ),
                ),
              ),
            ),
            Center(
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) {
                  final double pulseS =
                      (math.sin(_pulse.value * math.pi * 2) * 0.5 + 0.5);
                  final double glow = 0.55 + 0.25 * pulseS;
                  final double scale = 1.0 + 0.03 * pulseS;
                  return Transform.scale(
                    scale: scale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'VELOUR',
                          style: GoogleFonts.orbitron(
                            fontSize: 56 * scaleH,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 6,
                            color: const Color(0xFF00FFFF),
                            shadows: [
                              Shadow(
                                color: const Color(0xFF00FFFF)
                                    .withValues(alpha: glow),
                                blurRadius: 26,
                              ),
                              Shadow(
                                color: const Color(0x6600FFFF)
                                    .withValues(alpha: glow),
                                blurRadius: 52,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 22 * scaleH),
                        OutlinedButton(
                          onPressed: widget.onStart,
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
                            'INITIALIZE SYSTEM',
                            style: GoogleFonts.exo2(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Consumer<GameState>(
                builder: (context, gs, _) {
                  return Text(
                    'HIGH SCORE  ${gs.highScore}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.exo2(
                      fontSize: 12,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

