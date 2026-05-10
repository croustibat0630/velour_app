// Oracle narrative, ripple, célébration Trinity, textes flottants, gem narrative.

part of 'game_screen.dart';

extension _GameScreenStateOverlayNarrative on _GameScreenState {
  List<Widget> buildNarrativeTutorialOverlayLayers({
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
    ];
  }
}
