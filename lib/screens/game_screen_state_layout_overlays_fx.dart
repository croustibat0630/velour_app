// Effets entre narratif et HUD (combo, poussière LUX, flash ghost Perfect Heat),
// puis au-dessus du HUD (surge, level-up, game over, flash blanc, lueur haut).

part of 'game_screen.dart';

extension _GameScreenStateOverlayFx on _GameScreenState {
  List<Widget> buildFxOverlayLayersBetweenNarrativeAndHud(
    _GameOverlayLayoutBundle overlays,
  ) {
    return <Widget>[
      if (_comboFloater != null)
        Positioned.fill(
          child: IgnorePointer(
            child: _ComboFloater(
              key: ValueKey(_comboFloater!.id),
              chainMult: _comboFloater!.chainMult,
              position: _comboFloater!.position,
              accent: overlays.neonColor(2),
            ),
          ),
        ),
      if (!overlays.reduceMotion && _matchParticle != null)
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: LuxDustPainter(
                  center: _matchParticle!.center,
                  primary: overlays.gameState.currentSkin.primaryColor,
                  secondary: overlays.gameState.currentSkin.secondaryColor,
                  t: _matchParticleController.value,
                  seeds: _luxDustSeeds,
                  perfectBurst: _matchParticle!.perfectLuxBurst,
                  flashRadius: overlays.itemSize * 0.95,
                ),
              ),
            ),
          ),
        ),
      // Flash palier 5 : uniquement au-dessus de la zone de spawn des gemmes
      // (évite de voiler le plateau sous stress).
      if (!overlays.reduceMotion &&
          overlays.gameState.perfectHeatMechanicsActive)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: overlays.boardSpawnMinY,
          child: IgnorePointer(
            child: ClipRect(
              child: _PerfectHeatGhostFlash(
                tick: overlays.gameState.perfectHeatGhostFlashTick,
              ),
            ),
          ),
        ),
    ];
  }

  List<Widget> buildFxOverlayLayersAboveHud(_GameOverlayLayoutBundle overlays) {
    return <Widget>[
      if (!overlays.reduceMotion &&
          overlays.gameState.perfectHeatSurgeTierDisplay > 0)
        Positioned.fill(
          child: IgnorePointer(
            child: _PerfectHeatSurgeFlash(
              tick: overlays.gameState.perfectHeatSurgeFlashTick,
              tier: overlays.gameState.perfectHeatSurgeTierDisplay,
            ),
          ),
        ),
      if (!overlays.reduceMotion &&
          overlays.gameState.isLevelTransitionInProgress)
        Positioned.fill(
          child: IgnorePointer(
            child: _LevelUpFlash(
              tick: overlays.gameState.levelUpFlashTick,
              level: overlays.gameState.gameLevel,
            ),
          ),
        ),
      if (!overlays.reduceMotion &&
          overlays.gameState.isLevelTransitionInProgress)
        const Positioned.fill(child: IgnorePointer(child: _LevelUpLuxBurst())),
      if (overlays.gameState.criticalFailure)
        Positioned.fill(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (!overlays.reduceMotion)
                _GameOverRedFlash(tick: overlays.gameState.gameOverFlashTick),
              Builder(
                builder: (context) {
                  final GameState gs = overlays.gameState;
                  final ThemeEngine te = context.watch<ThemeEngine>();
                  final SessionStakeKind ended = gs.lastEndedRunStakeKind;
                  final double? prestigeMult =
                      ended == SessionStakeKind.highStakes &&
                          gs.gameLevel >= GameState.highStakesTargetLevel
                      ? 1.5
                      : ended == SessionStakeKind.royal &&
                            gs.gameLevel >= GameState.royalTargetLevel
                      ? 3.0
                      : null;
                  final bool isPremiumWin = gs.lastStakeRewardLuxCoins > 0;
                  final Color recordAccent = ended == SessionStakeKind.royal
                      ? const Color(0xFFE49BFF)
                      : ended == SessionStakeKind.highStakes
                      ? const Color(0xFFFFD700)
                      : te.colorForId(1);
                  return GameOverOverlay(
                    rawMatchLuxTotal: gs.runMatchLuxRawTotal,
                    finalLux: gs.lux,
                    careerHighScore: gs.highScore,
                    finalLevel: gs.gameLevel,
                    endedStakeKind: ended,
                    prestigeMultiplier: prestigeMult,
                    stakeRewardLuxCoins: gs.lastStakeRewardLuxCoins,
                    isPremiumWin: isPremiumWin,
                    isPersonalBest: gs.lastGameWasPersonalBest,
                    recordAccentColor: recordAccent,
                    sessionStakeFooter: gs.sessionStakeFooterLine,
                    oracleInsuranceRefundLux: gs.lastOracleInsuranceRefundLux,
                    onReplay: () async {
                      final SessionStakeKind stake =
                          gs.replaySuggestedStake ?? SessionStakeKind.casual;
                      context.read<GameState>().resetGame();
                      _shakeController.stop();
                      _flashController.reset();
                      if (!context.mounted) return;
                      Navigator.of(context).pushReplacement(
                        fadeRoute(PreparationView(initialStake: stake)),
                      );
                    },
                    onMenu: () {
                      context.read<GameState>().clearSessionStakeForMenu();
                      context.read<GameState>().resetGame();
                      Navigator.of(context).pushReplacementNamed('/main');
                    },
                  );
                },
              ),
            ],
          ),
        ),
      if (!overlays.reduceMotion &&
          !overlays.gameState.isTrinityTutorialComplete &&
          overlays.gameState.sequenceTick > 0)
        Positioned.fill(
          child: IgnorePointer(
            child: _SequenceCompletedFlash(
              tick: overlays.gameState.sequenceTick,
            ),
          ),
        ),
      if (!overlays.reduceMotion)
        Positioned.fill(
          child: IgnorePointer(
            ignoring: _flashController.value == 0,
            child: AnimatedBuilder(
              animation: _flashController,
              builder: (context, _) {
                final double v = Curves.easeInOutCubic.transform(
                  _flashController.value,
                );
                return ColoredBox(
                  color: Colors.white.withValues(alpha: 0.40 * v),
                );
              },
            ),
          ),
        ),
      // Lueur "plafonnier" (haut de l'écran)
      Positioned(
        left: 0,
        top: 0,
        right: 0,
        height: 50,
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x0DFFFFFF), // white @ 0.05
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
    ];
  }
}
