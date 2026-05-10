// Menu pause, objectif de session premium, tableau de score.

part of 'game_screen.dart';

extension _GameScreenStateOverlayHud on _GameScreenState {
  List<Widget> buildHudOverlayLayers(_GameOverlayLayoutBundle overlays) {
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
              tooltip: AppLocalizations.of(
                overlays.context,
              )!.gameHudMenuTooltip,
              onPressed: () async {
                if (!overlays.context.mounted) return;
                AudioHandler.instance.playMenuClick();
                overlays.context.read<GameState>().setPaused(true);
                await showDialog<void>(
                  context: overlays.context,
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
                if (!overlays.context.mounted) return;
                overlays.context.read<GameState>().setPaused(false);
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
      if (overlays.gameState.hasPremiumStakeSession)
        Positioned(
          top: 8,
          left: 48,
          right: 12,
          child: IgnorePointer(
            child: Center(
              child: _StakeObjectiveStrip(
                stake: overlays.gameState.sessionStake,
                gameLevel: overlays.gameState.gameLevel,
              ),
            ),
          ),
        ),
      // HUD full-width : alignement verrouillé dans `NeonScoreBoard` (Row center).
      Positioned(
        left: 0,
        right: 0,
        top: overlays.luxBoardTop,
        child: Builder(
          builder: (context) {
            final ({double level, double lux, double score, double time}) op =
                overlays.gameState.narrativeHudOpacities;
            return AnimatedOpacity(
              duration: Duration(
                milliseconds: velourReduceMotion(context) ? 0 : 900,
              ),
              curve: Curves.easeOutCubic,
              opacity:
                  overlays.gameState.isNarrativeTutorialActive &&
                      overlays.gameState.narrativeUiReveal == 0
                  ? 0.0
                  : 1.0,
              child: RepaintBoundary(
                child: NeonScoreBoard(
                  gameLevel: overlays.gameState.gameLevel,
                  lux: overlays.gameState.lux,
                  comboFlashTick: overlays.gameState.luxComboFlashTick,
                  luxIntroTick: overlays.gameState.narrativeLuxIntroTick,
                  levelUpFlashTick:
                      overlays.gameState.isLevelTransitionInProgress
                      ? 0
                      : overlays.gameState.levelUpFlashTick,
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
