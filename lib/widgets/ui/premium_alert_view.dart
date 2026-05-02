import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../utils/responsive.dart';

/// Fenêtre de confirmation d’abandon (« forfait ») pour session premium.
class PremiumAlertView extends StatelessWidget {
  const PremiumAlertView({
    super.key,
    required this.sessionName,
    required this.stakeAmountLux,
    required this.accentBorderColor,
    required this.stakeHighlightColor,
  });

  final String sessionName;
  final int stakeAmountLux;
  final Color accentBorderColor;
  final Color stakeHighlightColor;

  /// `true` si le joueur confirme le forfait, `false` sinon.
  static Future<bool> show(
    BuildContext context, {
    required String sessionName,
    required int stakeAmountLux,
    required Color accentBorderColor,
    required Color stakeHighlightColor,
  }) async {
    final bool? r = await showDialog<bool>(
      context: context,
      barrierColor: Colors.transparent,
      useRootNavigator: true,
      builder: (ctx) => PremiumAlertView(
        sessionName: sessionName,
        stakeAmountLux: stakeAmountLux,
        accentBorderColor: accentBorderColor,
        stakeHighlightColor: stakeHighlightColor,
      ),
    );
    return r ?? false;
  }

  static const Color _matteTop = Color(0xFF0E1014);
  static const Color _matteBottom = Color(0xFF1A1D26);
  static const Color _silver = Color(0xFFB8C0CE);
  static const Color _cyanActive = Color(0xFF00E0ED);
  static const Color _dangerRed = Color(0xFFFF5A5F);
  static const Color _matteDanger = Color(0xFF111218);

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.sizeOf(context);
    final double scaleH = Responsive.compactHeightScale(context);
    final double maxW = (screen.width * 0.78).clamp(280.0, 560.0);
    final double padH = (22 * scaleH).clamp(18.0, 24.0);
    final double padTop = (26 * scaleH).clamp(20.0, 28.0);
    final double padBottom = (20 * scaleH).clamp(16.0, 22.0);
    final double glyphSize = (52 * scaleH).clamp(44.0, 56.0);
    final double titleSize = (19 * scaleH).clamp(16.0, 20.0);
    final double bodySize = (15 * scaleH).clamp(13.5, 16.0);
    final double gap18 = (18 * scaleH).clamp(12.0, 18.0);
    final double gap16 = (16 * scaleH).clamp(10.0, 16.0);
    final double gap26 = (26 * scaleH).clamp(16.0, 26.0);

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(false),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
          Center(
            child: GestureDetector(
              onTap: () {},
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW, minWidth: 280),
                child: Container(
                  padding:
                      EdgeInsets.fromLTRB(padH, padTop, padH, padBottom),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_matteTop, _matteBottom],
                    ),
                    border: Border.all(
                      color: accentBorderColor.withValues(alpha: 0.55),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentBorderColor.withValues(alpha: 0.14),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ForfeitGlyph(
                        accent: accentBorderColor,
                        size: glyphSize,
                      ),
                      SizedBox(height: gap18),
                      Text(
                        'FORFAIT ?',
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  letterSpacing: 7,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.94),
                                  fontSize: titleSize,
                                ),
                      ),
                      SizedBox(height: gap16),
                      Text.rich(
                        TextSpan(
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontSize: bodySize,
                                    height: 1.48,
                                    color: _silver.withValues(alpha: 0.92),
                                  ),
                          children: [
                            TextSpan(
                              text:
                                  'En quittant cette session $sessionName, vous allez perdre définitivement votre mise de ',
                            ),
                            TextSpan(
                              text: '$stakeAmountLux LUX',
                              style: TextStyle(
                                color: stakeHighlightColor,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: gap26),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(false),
                              style: FilledButton.styleFrom(
                                elevation: 0,
                                backgroundColor:
                                    _cyanActive.withValues(alpha: 0.18),
                                foregroundColor:
                                    Colors.white.withValues(alpha: 0.96),
                                side: BorderSide(
                                  color: _cyanActive.withValues(alpha: 0.72),
                                  width: 1.2,
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: (14 * scaleH).clamp(12.0, 14.0),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'RESTER',
                                style: TextStyle(
                                  letterSpacing: 2.6,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(true),
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    _silver.withValues(alpha: 0.92),
                                backgroundColor:
                                    _matteDanger.withValues(alpha: 0.65),
                                side: BorderSide(
                                  color: _dangerRed.withValues(alpha: 0.55),
                                  width: 1.05,
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: (14 * scaleH).clamp(12.0, 14.0),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'FORFAIT',
                                style: TextStyle(
                                  letterSpacing: 2.4,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cercle fin + croix (mise en garde stylisée).
class _ForfeitGlyph extends StatelessWidget {
  const _ForfeitGlyph({required this.accent, required this.size});

  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: accent.withValues(alpha: 0.72),
          width: 1.65,
        ),
        color: Colors.black.withValues(alpha: 0.4),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.close_rounded,
        size: (size * 0.54).clamp(22.0, 30.0),
        color: accent.withValues(alpha: 0.92),
      ),
    );
  }
}
