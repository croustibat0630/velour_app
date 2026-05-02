import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/responsive.dart';

class LuxScoreDisplayer extends StatelessWidget {
  const LuxScoreDisplayer({
    super.key,
    required this.lux,
    this.initialValue,
    this.color = const Color(0xFF00E5FF),
    this.prefix = 'LUX COINS',
  });

  final int lux;
  final int? initialValue;
  final Color color;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    final double sH = Responsive.heightScale(context);
    final double sT = Responsive.textScale(context);
    final double labelSize = (12 * sT).clamp(11.0, 14.0);
    final double valueSize = (12 * sT).clamp(11.0, 15.0);

    final int beginInt = initialValue ?? lux;
    final double begin = beginInt.toDouble();
    final double end = lux.toDouble();

    return TweenAnimationBuilder<double>(
      key: ValueKey('lux_$beginInt->$lux'),
      tween: Tween<double>(begin: begin, end: end),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutExpo,
      builder: (context, v, _) {
        final int shown = v.round();
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: RichText(
            textAlign: TextAlign.right,
            text: TextSpan(
              style: GoogleFonts.montserrat(
                fontSize: labelSize,
                fontWeight: FontWeight.w500,
                letterSpacing: 2.4,
                height: 1.0,
                color: Colors.white.withValues(alpha: 0.44),
              ),
              children: [
                TextSpan(text: '$prefix  '),
                TextSpan(
                  text: '$shown',
                  style: GoogleFonts.montserrat(
                    fontSize: valueSize,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.4,
                    height: 1.0,
                    color: color.withValues(alpha: 0.95),
                    shadows: [
                      Shadow(
                        color: color.withValues(alpha: 0.40),
                        blurRadius: (5 * sH).clamp(4.0, 6.0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
