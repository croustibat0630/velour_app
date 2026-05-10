// Oracle narrative, ripple, célébration Trinity, textes flottants, gem narrative.

part of 'game_screen.dart';

extension _GameScreenStateOverlayNarrative on _GameScreenState {
  List<Widget> buildNarrativeTutorialOverlayLayers(
    _GameOverlayLayoutBundle overlays,
  ) {
    return <Widget>[
      if (overlays.gameState.isNarrativeTutorialActive &&
          !(overlays.gameState.narrativePhase ==
                  NarrativeTutorialPhase.celebration &&
              overlays.gameState.narrativePerfectBannerTick > 0))
        Positioned(
          left: (overlays.width - overlays.narrativeOracleW) * 0.5,
          width: overlays.narrativeOracleW,
          bottom:
              overlays.slotBarHeight +
              (22 * overlays.uiScale) +
              6 +
              MediaQuery.paddingOf(overlays.context).bottom,
          child: NarrativeOracleMessageBar(
            messageId: overlays.gameState.narrativeOracleDockMessageId,
            accent: overlays.gameState.currentSkin.primaryColor,
            secondary: overlays.gameState.currentSkin.secondaryColor,
            tutorialStepIndex: overlays.gameState.narrativeTutorialStepDotIndex,
          ),
        ),
      if (overlays.gameState.narrativeRippleCenter != null &&
          overlays.gameState.narrativeRippleTick > 0)
        NarrativeTapShockwave(
          key: ValueKey<int>(overlays.gameState.narrativeRippleTick),
          center: overlays.gameState.narrativeRippleCenter!,
        ),
      if (overlays.gameState.narrativePhase ==
              NarrativeTutorialPhase.celebration &&
          overlays.gameState.narrativePerfectBannerTick > 0)
        Positioned.fill(
          child: IgnorePointer(
            child: _NarrativePerfectCelebrationBanner(
              key: ValueKey<int>(overlays.gameState.narrativePerfectBannerTick),
            ),
          ),
        ),
      if (overlays.gameState.trinityBannerId != TrinityBannerId.none &&
          !overlays.gameState.isNarrativeTutorialActive)
        Positioned(
          left: overlays.width * 0.10,
          width: overlays.width * 0.80,
          // Ancrée au-dessus du rack (évite de recouvrir les gemmes).
          bottom: (overlays.slotBarHeight + (16 * overlays.uiScale)).clamp(
            96.0,
            overlays.height * 0.40,
          ),
          child: IgnorePointer(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              switchInCurve: Curves.easeOutCubic,
              child: Material(
                key: ValueKey<int>(overlays.gameState.tutorialBannerTick),
                color: Colors.black.withValues(alpha: 0.60),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    resolveTrinityBanner(
                      AppLocalizations.of(overlays.context)!,
                      overlays.gameState.trinityBannerId,
                    ),
                    textAlign: TextAlign.center,
                    style: Theme.of(overlays.context).textTheme.titleSmall
                        ?.copyWith(
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
          !(overlays.gameState.narrativePhase ==
                  NarrativeTutorialPhase.celebration &&
              overlays.gameState.narrativePerfectBannerTick > 0))
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
              color: overlays.neonColor(_floating!.colorId),
              spectacularBurst: _floating!.isNarrativePerfectBurst,
              textColorOverride: _floating!.textColorOverride,
              appendPerfectHeatNear: _floating!.appendPerfectHeatNear,
            ),
          ),
        ),
      if (overlays.gameState.narrativeGemGainFx != null)
        Positioned.fill(
          child: IgnorePointer(
            child: _NarrativeGemGainFloater(
              key: ValueKey<String>(overlays.gameState.narrativeGemGainFx!.id),
              from: overlays.gameState.narrativeGemGainFx!.from,
              color: overlays.neonColor(
                overlays.gameState.narrativeGemGainFx!.colorId,
              ),
            ),
          ),
        ),
    ];
  }
}
