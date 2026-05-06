import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

import '../../services/audio_handler.dart';

class MenuTextButton extends StatefulWidget {
  const MenuTextButton({
    super.key,
    required this.label,
    required this.neon,
    required this.onPressed,
    this.scale = 1.0,
    this.baseAlpha = 0.82,
    this.neonShadowBlur = 18,
    this.fontSize,
    this.letterSpacing,
    this.transformFilterQuality = FilterQuality.medium,
  });

  final String label;
  final Color neon;
  final VoidCallback onPressed;
  final double scale;

  /// Opacité de base du texte (hors survol) — utile pour mettre un CTA en avant.
  final double baseAlpha;

  /// Rayon du halo porté sur le texte (ombre néon). Valeurs basses = texte plus net.
  final double neonShadowBlur;

  /// Override typographie (utile pour le menu pause / variantes courtes).
  final double? fontSize;
  final double? letterSpacing;

  /// Qualité du scale au press — `none` / `low` = glyphes plus nets.
  final FilterQuality transformFilterQuality;

  @override
  State<MenuTextButton> createState() => _MenuTextButtonState();
}

class _MenuTextButtonState extends State<MenuTextButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _hover = false;
  bool _down = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _down = true);
          // Immediate feedback on press (not release).
          AudioHandler.instance.playMenuClick();
        },
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onPressed,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final double s = (sin01(_c.value));
            final double pulse = _hover ? (0.10 + 0.10 * s) : (0.05 + 0.05 * s);
            final double a = _hover ? 0.98 : widget.baseAlpha.clamp(0.0, 1.0);
            final double scale = (_down ? 1.05 : 1.0) * widget.scale;
            return ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 10 * widget.scale),
                  child: Transform.scale(
                    scale: scale,
                    filterQuality: widget.transformFilterQuality,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.visible,
                        style: GoogleFonts.montserrat(
                          fontSize: (widget.fontSize ?? 16) * widget.scale,
                          fontWeight: FontWeight.w600,
                          letterSpacing: widget.letterSpacing ?? 4.6,
                          color: widget.neon.withValues(alpha: a),
                          shadows: widget.neonShadowBlur <= 0.5
                              ? const <Shadow>[]
                              : <Shadow>[
                                  Shadow(
                                    color: widget.neon.withValues(alpha: pulse),
                                    blurRadius: widget.neonShadowBlur,
                                  ),
                                ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

double sin01(double t) {
  // 0..1 sinusoid for soft pulsation
  return (math.sin(t * math.pi * 2) * 0.5 + 0.5);
}
