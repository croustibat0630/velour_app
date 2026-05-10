// Overlays au-dessus du plateau : narrative, HUD, flashes, game over, etc.

part of 'game_screen.dart';

extension _GameScreenStateLayoutOverlays on _GameScreenState {
  List<Widget> buildScreenLayoutOverlayLayers({
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
      if (gameState.isNarrativeTutorialActive &&
          !(gameState.narrativePhase == NarrativeTutorialPhase.celebration &&
              gameState.narrativePerfectBannerTick > 0))
        Positioned(
          left: (width - narrativeOracleW) * 0.5,
          width: narrativeOracleW,
          bottom:
              slotBarHeight +
              (22 * uiScale) +
              6 +
              MediaQuery.paddingOf(context).bottom,
          child: NarrativeOracleMessageBar(
            messageId: gameState.narrativeOracleDockMessageId,
            accent: gameState.currentSkin.primaryColor,
            secondary: gameState.currentSkin.secondaryColor,
            tutorialStepIndex: gameState.narrativeTutorialStepDotIndex,
          ),
        ),
      if (gameState.narrativeRippleCenter != null &&
          gameState.narrativeRippleTick > 0)
        NarrativeTapShockwave(
          key: ValueKey<int>(gameState.narrativeRippleTick),
          center: gameState.narrativeRippleCenter!,
        ),
      if (gameState.narrativePhase == NarrativeTutorialPhase.celebration &&
          gameState.narrativePerfectBannerTick > 0)
        Positioned.fill(
          child: IgnorePointer(
            child: _NarrativePerfectCelebrationBanner(
              key: ValueKey<int>(gameState.narrativePerfectBannerTick),
            ),
          ),
        ),
      if (gameState.trinityBannerId != TrinityBannerId.none &&
          !gameState.isNarrativeTutorialActive)
        Positioned(
          left: width * 0.10,
          width: width * 0.80,
          // Ancrée au-dessus du rack (évite de recouvrir les gemmes).
          bottom: (slotBarHeight + (16 * uiScale)).clamp(96.0, height * 0.40),
          child: IgnorePointer(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              switchInCurve: Curves.easeOutCubic,
              child: Material(
                key: ValueKey<int>(gameState.tutorialBannerTick),
                color: Colors.black.withValues(alpha: 0.60),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    resolveTrinityBanner(
                      AppLocalizations.of(context)!,
                      gameState.trinityBannerId,
                    ),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      if (_floating != null &&
          !(gameState.narrativePhase == NarrativeTutorialPhase.celebration &&
              gameState.narrativePerfectBannerTick > 0))
        Positioned.fill(
          child: IgnorePointer(
            child: _FloatingText(
              key: ValueKey(_floating!.id),
              text: _floating!.text,
              narrativeFloatKey: _floating!.narrativeFloatKey,
              runtimeLuxKind: _floating!.runtimeLuxKind,
              runtimeGain: _floating!.runtimeGain,
              runtimeChainMult: _floating!.runtimeChainMult,
              position: _floating!.position,
              color: neonColor(_floating!.colorId),
              spectacularBurst: _floating!.isNarrativePerfectBurst,
              textColorOverride: _floating!.textColorOverride,
              appendPerfectHeatNear: _floating!.appendPerfectHeatNear,
            ),
          ),
        ),
      if (gameState.narrativeGemGainFx != null)
        Positioned.fill(
          child: IgnorePointer(
            child: _NarrativeGemGainFloater(
              key: ValueKey<String>(gameState.narrativeGemGainFx!.id),
              from: gameState.narrativeGemGainFx!.from,
              color: neonColor(gameState.narrativeGemGainFx!.colorId),
            ),
          ),
        ),
      if (_comboFloater != null)
        Positioned.fill(
          child: IgnorePointer(
            child: _ComboFloater(
              key: ValueKey(_comboFloater!.id),
              chainMult: _comboFloater!.chainMult,
              position: _comboFloater!.position,
              accent: neonColor(2),
            ),
          ),
        ),
      if (!reduceMotion && _matchParticle != null)
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: LuxDustPainter(
                  center: _matchParticle!.center,
                  primary: gameState.currentSkin.primaryColor,
                  secondary: gameState.currentSkin.secondaryColor,
                  t: _matchParticleController.value,
                  seeds: _luxDustSeeds,
                  perfectBurst: _matchParticle!.perfectLuxBurst,
                  flashRadius: itemSize * 0.95,
                ),
              ),
            ),
          ),
        ),
      // Flash palier 5 : uniquement au-dessus de la zone de spawn des gemmes
      // (évite de voiler le plateau sous stress).
      if (!reduceMotion && gameState.perfectHeatMechanicsActive)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: boardSpawnMinY,
          child: IgnorePointer(
            child: ClipRect(
              child: _PerfectHeatGhostFlash(
                tick: gameState.perfectHeatGhostFlashTick,
              ),
            ),
          ),
        ),
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
      if (!reduceMotion && gameState.perfectHeatSurgeTierDisplay > 0)
        Positioned.fill(
          child: IgnorePointer(
            child: _PerfectHeatSurgeFlash(
              tick: gameState.perfectHeatSurgeFlashTick,
              tier: gameState.perfectHeatSurgeTierDisplay,
            ),
          ),
        ),
      if (!reduceMotion && gameState.isLevelTransitionInProgress)
        Positioned.fill(
          child: IgnorePointer(
            child: _LevelUpFlash(
              tick: gameState.levelUpFlashTick,
              level: gameState.gameLevel,
            ),
          ),
        ),
      if (!reduceMotion && gameState.isLevelTransitionInProgress)
        const Positioned.fill(child: IgnorePointer(child: _LevelUpLuxBurst())),
      if (gameState.criticalFailure)
        Positioned.fill(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (!reduceMotion)
                _GameOverRedFlash(tick: gameState.gameOverFlashTick),
              Builder(
                builder: (context) {
                  final GameState gs = gameState;
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
      if (!reduceMotion &&
          !gameState.isTrinityTutorialComplete &&
          gameState.sequenceTick > 0)
        Positioned.fill(
          child: IgnorePointer(
            child: _SequenceCompletedFlash(tick: gameState.sequenceTick),
          ),
        ),
      if (!reduceMotion)
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
