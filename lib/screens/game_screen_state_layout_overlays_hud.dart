// Menu pause, objectif de session premium, tableau de score.

part of 'game_screen.dart';

extension _GameScreenStateOverlayHud on _GameScreenState {
  List<Widget> buildHudOverlayLayers({
    required BuildContext context,
    required GameState gameState,
    required bool reduceMotion,
    required double width,
    required double height,
    required double slotBarHeight,
    required double uiScale,
    required double narrativeOracleW,
    required Color Function(int colorId) neonColor,
    required double luxBoardTop,
    required double boardSpawnMinY,
    required double itemSize,
  }) {
    return <Widget>[
      // Menu isolé (haut gauche), en dehors du HUD.
      Positioned(
        top: 8,
        left: 8,
        child: SafeArea(
          bottom: false,
          child: Material(
            type: MaterialType.transparency,
            child: IconButton(
              tooltip: AppLocalizations.of(context)!.gameHudMenuTooltip,
              onPressed: () async {
                if (!context.mounted) return;
                AudioHandler.instance.playMenuClick();
                context.read<GameState>().setPaused(true);
                await showDialog<void>(
                  context: context,
                  barrierDismissible: true,
                  builder: (context) {
                    return PauseOverlay(
                      onContinue: () => Navigator.of(context).pop(),
                      onBackToMenu: () {
                        Navigator.of(context).pop();
                        context.read<GameState>().clearSessionStakeForMenu();
                        context.read<GameState>().resetGame();
                        Navigator.of(context).pushReplacementNamed('/main');
                      },
                    );
                  },
                );
                if (!context.mounted) return;
                context.read<GameState>().setPaused(false);
              },
              icon: Icon(
                Icons.menu_rounded,
                size: 19,
                color: Colors.white.withValues(alpha: 0.60),
              ),
            ),
          ),
        ),
      ),
      if (gameState.hasPremiumStakeSession)
        Positioned(
          top: 8,
          left: 48,
          right: 12,
          child: IgnorePointer(
            child: Center(
              child: _StakeObjectiveStrip(
                stake: gameState.sessionStake,
                gameLevel: gameState.gameLevel,
              ),
            ),
          ),
        ),
      // HUD full-width : alignement verrouillé dans `NeonScoreBoard` (Row center).
      Positioned(
        left: 0,
        right: 0,
        top: luxBoardTop,
        child: Builder(
          builder: (context) {
            final ({double level, double lux, double score, double time}) op =
                gameState.narrativeHudOpacities;
            return AnimatedOpacity(
              duration: Duration(
                milliseconds: velourReduceMotion(context) ? 0 : 900,
              ),
              curve: Curves.easeOutCubic,
              opacity:
                  gameState.isNarrativeTutorialActive &&
                      gameState.narrativeUiReveal == 0
                  ? 0.0
                  : 1.0,
              child: RepaintBoundary(
                child: NeonScoreBoard(
                  gameLevel: gameState.gameLevel,
                  lux: gameState.lux,
                  comboFlashTick: gameState.luxComboFlashTick,
                  luxIntroTick: gameState.narrativeLuxIntroTick,
                  levelUpFlashTick: gameState.isLevelTransitionInProgress
                      ? 0
                      : gameState.levelUpFlashTick,
                  maxWidth: 500,
                  levelOpacity: op.level,
                  luxOpacity: op.lux,
                  scoreColumnOpacity: op.score,
                  timeColumnOpacity: op.time,
                ),
              ),
            );
          },
        ),
      ),
    ];
  }
}
