// Scaffold + Stack principal du jeu (corps de [_GameScreenState.build]).

part of 'game_screen.dart';

extension _GameScreenStateLayout on _GameScreenState {
  Widget buildScreenFrame(
    BuildContext context,

    ThemeEngine themeEngine,

    GameState gameState,
  ) {
    Color neonColor(int colorId) => themeEngine.colorForId(colorId);

    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        _shakeController,
        _flashController,
        _matchParticleController,
      ]),
      builder: (BuildContext context, Widget? _) {
        // iOS « Réduire les mouvements » → [MediaQueryData.disableAnimations] (voir
        // [velourReduceMotion] / [MediaQuery.disableAnimationsOf]).
        final bool reduceMotion = velourReduceMotion(context);
        final double shakeMul = reduceMotion ? 0.0 : 1.0;
        return Transform.translate(
          offset: _shakeOffset(shakeMul),
          child: Scaffold(
            backgroundColor: const Color(0xFF0A0A0F),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const double slotPaddingH = 12;

                  // Universal layout: scale sizes with screen width (mobile/tablet).
                  final double uiScale = (constraints.maxWidth / 420).clamp(
                    0.85,
                    1.25,
                  );
                  final double slotBarHeight = (100 * uiScale).clamp(
                    88.0,
                    130.0,
                  );
                  final double slotSize = (GameState.baseSlotSize * uiScale)
                      .clamp(38.0, 60.0);
                  final double itemSize = slotSize;
                  final double gridGap = (GameState.baseGridGap * uiScale)
                      .clamp(4.0, 10.0);

                  final double width = constraints.maxWidth;
                  final double height = constraints.maxHeight;
                  final double playZoneHeight = (height - slotBarHeight).clamp(
                    0,
                    height,
                  );

                  final Rect playZoneRect = Rect.fromLTWH(
                    0,
                    0,
                    width,
                    playZoneHeight,
                  );

                  // HUD (full width, 2 colonnes) + zone sûre + spawn floor.
                  // High stakes: bandeau objectif au-dessus du score.
                  final double luxBoardTop = gameState.hasPremiumStakeSession
                      ? 40
                      : 10;
                  const double luxSafePadding = 16;
                  const double hudHeight = 110;
                  final double narrativeOracleW = math.min(width * 0.92, 440);
                  final Rect luxBoardRect = Rect.fromLTWH(
                    0,
                    luxBoardTop,
                    width,
                    hudHeight,
                  );
                  final Rect luxSafeRect = luxBoardRect.inflate(luxSafePadding);
                  final double boardSpawnMinY = luxBoardRect.bottom + 50;

                  final double available = (width - (slotPaddingH * 2)).clamp(
                    0,
                    width,
                  );
                  final double gap =
                      (available - (slotSize * GameState.slotCount)) /
                      (GameState.slotCount - 1);
                  final double slotTop =
                      playZoneHeight + (slotBarHeight - slotSize) / 2;

                  final List<Offset> slotTopLefts = List<Offset>.generate(
                    GameState.slotCount,
                    (i) {
                      final double left = slotPaddingH + i * (slotSize + gap);
                      return Offset(left, slotTop);
                    },
                  );

                  final nextLayout = (
                    playZoneRect: playZoneRect,
                    luxSafeRect: luxSafeRect,
                    boardSpawnMinY: boardSpawnMinY,
                    itemSize: itemSize,
                    slotSize: slotSize,
                    gridGap: gridGap,
                    slotTopLefts: slotTopLefts,
                  );
                  if (_lastLayout == null || _lastLayout != nextLayout) {
                    _lastLayout = nextLayout;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      context.read<GameState>().setLayout(
                        playZoneRect: playZoneRect,
                        slotTopLefts: slotTopLefts,
                        luxSafeRect: luxSafeRect,
                        boardSpawnMinY: boardSpawnMinY,
                        itemSize: itemSize,
                        slotSize: slotSize,
                        gridGap: gridGap,
                      );
                    });
                  }

                  // Perf: avoid sorting each rebuild (keep stable ordering, render selected last).
                  final List<GameItem> items = <GameItem>[
                    ...gameState.boardItems.where((e) => !e.isSelected),
                    ...gameState.slotItems.where((e) => !e.isSelected),
                    ...gameState.boardItems.where((e) => e.isSelected),
                    ...gameState.slotItems.where((e) => e.isSelected),
                  ];

                  final bool narrativeStep3Dim =
                      gameState.narrativePhase ==
                      NarrativeTutorialPhase.step3Perfect;
                  final Set<String> narrativeTrio = gameState.narrativeTrioIds;
                  final Set<String> boardIds = gameState.boardItems
                      .map((e) => e.id)
                      .toSet();

                  return Stack(
                    children: [
                      // Fond : léger drift du centre (premium, sans distraire du jeu).
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedBuilder(
                            animation: _bgDrift,
                            builder: (BuildContext context, Widget? _) {
                              final double t = _bgDrift.value * math.pi * 2;
                              final Alignment center = Alignment(
                                0.038 * math.sin(t),
                                0.10 + 0.028 * math.cos(t * 0.73),
                              );
                              return DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    center: center,
                                    radius: 1.2,
                                    colors: const <Color>[
                                      Color(0xFF0B1020),
                                      Color(0xFF000000),
                                    ],
                                    stops: const <double>[0.0, 1.0],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(
                              begin: _pulseUp ? 0.2 : 0.4,
                              end: _pulseUp ? 0.4 : 0.2,
                            ),
                            duration: reduceMotion
                                ? Duration.zero
                                : const Duration(seconds: 4),
                            onEnd: () {
                              if (!gameState.criticalFailure) {
                                _toggleBackgroundPulseForAmbient();
                              }
                            },
                            builder: (context, pulseT, _) {
                              if (!gameState.hasPremiumStakeSession) {
                                return DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      center: const Alignment(0, 0.10),
                                      radius: 1.2,
                                      colors: [
                                        NeonColors.cyan.withValues(
                                          alpha: pulseT,
                                        ),
                                        const Color(0x00000000),
                                      ],
                                      stops: const [0.0, 1.0],
                                    ),
                                  ),
                                );
                              }
                              final double u = ((pulseT - 0.2) / 0.2).clamp(
                                0.0,
                                1.0,
                              );
                              if (gameState.isRoyalSession) {
                                // Vignette violet néon (bords), plus marquée que l’or.
                                final double edgeA = 0.14 + 0.12 * u;
                                return DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      center: Alignment.center,
                                      radius: 1.42,
                                      colors: [
                                        const Color(0x00000000),
                                        const Color(
                                          0xFF9D50BB,
                                        ).withValues(alpha: edgeA),
                                        const Color(
                                          0xFF6E48AA,
                                        ).withValues(alpha: edgeA * 0.82),
                                      ],
                                      stops: const [0.62, 0.88, 1.0],
                                    ),
                                  ),
                                );
                              }
                              // Vignette dorée sur les bords (centre transparent → or léger).
                              final double edgeA = 0.10 + 0.08 * u;
                              return DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    center: Alignment.center,
                                    radius: 1.38,
                                    colors: [
                                      const Color(0x00000000),
                                      const Color(
                                        0xFFFFD700,
                                      ).withValues(alpha: edgeA),
                                    ],
                                    stops: const [0.70, 1.0],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      // Space dust (very subtle)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: LayoutBuilder(
                            builder: (context, c) {
                              return Stack(
                                children: [
                                  for (final p in _dust)
                                    Positioned(
                                      left: p.dx * c.maxWidth,
                                      top: p.dy * c.maxHeight,
                                      child: Container(
                                        width: 1,
                                        height: 1,
                                        color: Colors.white.withValues(
                                          alpha: 0.06,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      if (gameState.isNarrativeTutorialActive)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: const NarrativeTutorialAmbientLayer(),
                          ),
                        ),
                      AbsorbPointer(
                        absorbing:
                            gameState.criticalFailure ||
                            gameState.isProcessingMatch,
                        child: Column(
                          children: [
                            const Expanded(
                              child: IgnorePointer(child: _PlayZone()),
                            ),
                            _SlotBar(
                              imminentSlotIdxs: gameState.imminentSlotIdxs,
                              slotItems: gameState.slotItems,
                              accent: gameState.isRoyalSession
                                  ? const Color(0xFF9D50BB)
                                  : gameState.isHighStakesSession
                                  ? const Color(0xFFFFD700)
                                  : NeonColors.cyan,
                              premium: gameState.hasPremiumStakeSession,
                            ),
                          ],
                        ),
                      ),
                      AbsorbPointer(
                        absorbing:
                            gameState.criticalFailure ||
                            gameState.isProcessingMatch,
                        child: RepaintBoundary(
                          child: TweenAnimationBuilder<double>(
                            key: ValueKey<int>(
                              gameState.postNarrativeSpawnFadeTick,
                            ),
                            tween: Tween<double>(
                              begin: gameState.postNarrativeSpawnFadeTick == 0
                                  ? 1.0
                                  : 0.0,
                              end: 1.0,
                            ),
                            duration:
                                gameState.postNarrativeSpawnFadeTick == 0 ||
                                    reduceMotion
                                ? Duration.zero
                                : const Duration(milliseconds: 780),
                            curve: Curves.easeOutCubic,
                            builder: (context, double fade, Widget? child) {
                              return Opacity(opacity: fade, child: child);
                            },
                            child: Stack(
                              children: [
                                for (final item in items)
                                  AnimatedPositioned(
                                    key: ValueKey(item.id),
                                    duration: reduceMotion
                                        ? Duration.zero
                                        : Duration(
                                            milliseconds:
                                                gameState.narrativeGemFlightMs,
                                          ),
                                    curve: Curves.easeInOutCubic,
                                    left: item.position.dx,
                                    top: item.position.dy,
                                    width: itemSize,
                                    height: itemSize,
                                    child: Opacity(
                                      opacity:
                                          narrativeStep3Dim &&
                                              !narrativeTrio.contains(item.id)
                                          ? 0.34
                                          : 1.0,
                                      child: _NarrativeTargetGemPulse(
                                        active: gameState
                                            .narrativeGuideGemShouldPulse(
                                              item.id,
                                            ),
                                        child: FloatingGem(
                                          enabled: boardIds.contains(item.id),
                                          floatPeriodMs: item.floatPeriodMs,
                                          floatPhase: item.floatPhase,
                                          size: itemSize,
                                          child: _GemTapJuice(
                                            semanticsLabel:
                                                gemAccessibilityLabel(
                                                  AppLocalizations.of(context)!,
                                                  item.typeId,
                                                  item.colorId,
                                                ),
                                            isOnBoard: boardIds.contains(
                                              item.id,
                                            ),
                                            typeId: item.typeId,
                                            neon: neonColor(item.colorId),
                                            stakeTapTraceColor:
                                                gameState.isHighStakesSession
                                                ? const Color(0xFFFFD700)
                                                : gameState.isRoyalSession
                                                ? const Color(0xFFE49BFF)
                                                : null,
                                            stakeTapParticleBoost:
                                                gameState.isRoyalSession
                                                ? 1.22
                                                : 1.0,
                                            onSelect: () =>
                                                gameState.selectItem(item.id),
                                            child: _ItemFx(
                                              id: item.id,
                                              isRemoving: gameState.removingIds
                                                  .contains(item.id),
                                              kind: gameState.removalKindFor(
                                                item.id,
                                              ),
                                              typeId: item.typeId,
                                              neon: neonColor(item.colorId),
                                              child: _NeonHalo(
                                                color: neonColor(item.colorId),
                                                alert: gameState.alertIds
                                                    .contains(item.id),
                                                lowGlow:
                                                    gameState
                                                        .isTrinityTutorialActive ||
                                                    gameState
                                                        .isNarrativeTutorialActive,
                                                child: _itemWidget(
                                                  item,
                                                  itemSize,
                                                  neonColor(item.colorId),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (gameState.isNarrativeTutorialActive &&
                          !(gameState.narrativePhase ==
                                  NarrativeTutorialPhase.celebration &&
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
                            tutorialStepIndex:
                                gameState.narrativeTutorialStepDotIndex,
                          ),
                        ),
                      if (gameState.narrativeRippleCenter != null &&
                          gameState.narrativeRippleTick > 0)
                        NarrativeTapShockwave(
                          key: ValueKey<int>(gameState.narrativeRippleTick),
                          center: gameState.narrativeRippleCenter!,
                        ),
                      if (gameState.narrativePhase ==
                              NarrativeTutorialPhase.celebration &&
                          gameState.narrativePerfectBannerTick > 0)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: _NarrativePerfectCelebrationBanner(
                              key: ValueKey<int>(
                                gameState.narrativePerfectBannerTick,
                              ),
                            ),
                          ),
                        ),
                      if (gameState.trinityBannerId != TrinityBannerId.none &&
                          !gameState.isNarrativeTutorialActive)
                        Positioned(
                          left: width * 0.10,
                          width: width * 0.80,
                          // Ancrée au-dessus du rack (évite de recouvrir les gemmes).
                          bottom: (slotBarHeight + (16 * uiScale)).clamp(
                            96.0,
                            height * 0.40,
                          ),
                          child: IgnorePointer(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 420),
                              switchInCurve: Curves.easeOutCubic,
                              child: Material(
                                key: ValueKey<int>(
                                  gameState.tutorialBannerTick,
                                ),
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: Colors.white.withValues(
                                            alpha: 0.92,
                                          ),
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
                          !(gameState.narrativePhase ==
                                  NarrativeTutorialPhase.celebration &&
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
                              spectacularBurst:
                                  _floating!.isNarrativePerfectBurst,
                              textColorOverride: _floating!.textColorOverride,
                              appendPerfectHeatNear:
                                  _floating!.appendPerfectHeatNear,
                            ),
                          ),
                        ),
                      if (gameState.narrativeGemGainFx != null)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: _NarrativeGemGainFloater(
                              key: ValueKey<String>(
                                gameState.narrativeGemGainFx!.id,
                              ),
                              from: gameState.narrativeGemGainFx!.from,
                              color: neonColor(
                                gameState.narrativeGemGainFx!.colorId,
                              ),
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
                                  secondary:
                                      gameState.currentSkin.secondaryColor,
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
                              tooltip: AppLocalizations.of(
                                context,
                              )!.gameHudMenuTooltip,
                              onPressed: () async {
                                if (!context.mounted) return;
                                AudioHandler.instance.playMenuClick();
                                context.read<GameState>().setPaused(true);
                                await showDialog<void>(
                                  context: context,
                                  barrierDismissible: true,
                                  builder: (context) {
                                    return PauseOverlay(
                                      onContinue: () =>
                                          Navigator.of(context).pop(),
                                      onBackToMenu: () {
                                        Navigator.of(context).pop();
                                        context
                                            .read<GameState>()
                                            .clearSessionStakeForMenu();
                                        context.read<GameState>().resetGame();
                                        Navigator.of(
                                          context,
                                        ).pushReplacementNamed('/main');
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
                            final ({
                              double level,
                              double lux,
                              double score,
                              double time,
                            })
                            op = gameState.narrativeHudOpacities;
                            return AnimatedOpacity(
                              duration: Duration(
                                milliseconds: velourReduceMotion(context)
                                    ? 0
                                    : 900,
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
                                  levelUpFlashTick:
                                      gameState.isLevelTransitionInProgress
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
                      if (!reduceMotion &&
                          gameState.perfectHeatSurgeTierDisplay > 0)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: _PerfectHeatSurgeFlash(
                              tick: gameState.perfectHeatSurgeFlashTick,
                              tier: gameState.perfectHeatSurgeTierDisplay,
                            ),
                          ),
                        ),
                      if (!reduceMotion &&
                          gameState.isLevelTransitionInProgress)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: _LevelUpFlash(
                              tick: gameState.levelUpFlashTick,
                              level: gameState.gameLevel,
                            ),
                          ),
                        ),
                      if (!reduceMotion &&
                          gameState.isLevelTransitionInProgress)
                        const Positioned.fill(
                          child: IgnorePointer(child: _LevelUpLuxBurst()),
                        ),
                      if (gameState.criticalFailure)
                        Positioned.fill(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (!reduceMotion)
                                _GameOverRedFlash(
                                  tick: gameState.gameOverFlashTick,
                                ),
                              Builder(
                                builder: (context) {
                                  final GameState gs = gameState;
                                  final ThemeEngine te = context
                                      .watch<ThemeEngine>();
                                  final SessionStakeKind ended =
                                      gs.lastEndedRunStakeKind;
                                  final double? prestigeMult =
                                      ended == SessionStakeKind.highStakes &&
                                          gs.gameLevel >=
                                              GameState.highStakesTargetLevel
                                      ? 1.5
                                      : ended == SessionStakeKind.royal &&
                                            gs.gameLevel >=
                                                GameState.royalTargetLevel
                                      ? 3.0
                                      : null;
                                  final bool isPremiumWin =
                                      gs.lastStakeRewardLuxCoins > 0;
                                  final Color recordAccent =
                                      ended == SessionStakeKind.royal
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
                                    stakeRewardLuxCoins:
                                        gs.lastStakeRewardLuxCoins,
                                    isPremiumWin: isPremiumWin,
                                    isPersonalBest: gs.lastGameWasPersonalBest,
                                    recordAccentColor: recordAccent,
                                    sessionStakeFooter:
                                        gs.sessionStakeFooterLine,
                                    oracleInsuranceRefundLux:
                                        gs.lastOracleInsuranceRefundLux,
                                    onReplay: () async {
                                      final SessionStakeKind stake =
                                          gs.replaySuggestedStake ??
                                          SessionStakeKind.casual;
                                      context.read<GameState>().resetGame();
                                      _shakeController.stop();
                                      _flashController.reset();
                                      if (!context.mounted) return;
                                      Navigator.of(context).pushReplacement(
                                        fadeRoute(
                                          PreparationView(initialStake: stake),
                                        ),
                                      );
                                    },
                                    onMenu: () {
                                      context
                                          .read<GameState>()
                                          .clearSessionStakeForMenu();
                                      context.read<GameState>().resetGame();
                                      Navigator.of(
                                        context,
                                      ).pushReplacementNamed('/main');
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
                            child: _SequenceCompletedFlash(
                              tick: gameState.sequenceTick,
                            ),
                          ),
                        ),
                      if (!reduceMotion)
                        Positioned.fill(
                          child: IgnorePointer(
                            ignoring: _flashController.value == 0,
                            child: AnimatedBuilder(
                              animation: _flashController,
                              builder: (context, _) {
                                final double v = Curves.easeInOutCubic
                                    .transform(_flashController.value);
                                return ColoredBox(
                                  color: Colors.white.withValues(
                                    alpha: 0.40 * v,
                                  ),
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
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
