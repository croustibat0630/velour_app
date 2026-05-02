import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/game_state.dart';
import '../../theme/theme_engine.dart';
import '../../utils/responsive.dart';
import 'dark_matte_overlay.dart';
import 'menu_text_button.dart';

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({
    super.key,
    required this.onContinue,
    required this.onBackToMenu,
  });

  final VoidCallback onContinue;
  final VoidCallback onBackToMenu;

  @override
  Widget build(BuildContext context) {
    final te = context.watch<ThemeEngine>();
    final double s = Responsive.compactHeightScale(context);
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          const Positioned.fill(child: DarkMatteOverlay()),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF000000).withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'PAUSE',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              letterSpacing: 6,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: (Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.fontSize ??
                                      16) *
                                  s,
                            ),
                      ),
                      SizedBox(height: 18 * s),
                      MenuTextButton(
                        label: 'CONTINUER',
                        neon: te.colorForId(1),
                        onPressed: onContinue,
                      ),
                      SizedBox(height: 12 * s),
                      MenuTextButton(
                        label: 'RETOUR AU MENU',
                        neon: te.colorForId(5),
                        fontSize: 16,
                        letterSpacing: 1.5,
                        onPressed: () async {
                          final GameState gs = context.read<GameState>();
                          if (gs.hasPremiumStakeSession) {
                            final bool confirm =
                                await gs.showPremiumForfeitAlert(
                              context,
                              gs.activeSessionAnteLux,
                            );
                            if (!confirm) return;
                          }
                          onBackToMenu();
                        },
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

