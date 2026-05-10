// Colonne zone de jeu + rack, puis stack des gemmes (plateau + slots).

part of 'game_screen.dart';

extension _GameScreenStateLayoutPlayfield on _GameScreenState {
  List<Widget> buildScreenLayoutPlayfieldLayers({
    required BuildContext context,
    required GameState gameState,
    required bool reduceMotion,
    required List<GameItem> items,
    required double itemSize,
    required bool narrativeStep3Dim,
    required Set<String> narrativeTrio,
    required Set<String> boardIds,
    required Color Function(int colorId) neonColor,
  }) {
    return <Widget>[
      AbsorbPointer(
        absorbing: gameState.criticalFailure || gameState.isProcessingMatch,
        child: Column(
          children: [
            const Expanded(child: IgnorePointer(child: _PlayZone())),
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
        absorbing: gameState.criticalFailure || gameState.isProcessingMatch,
        child: RepaintBoundary(
          child: TweenAnimationBuilder<double>(
            key: ValueKey<int>(gameState.postNarrativeSpawnFadeTick),
            tween: Tween<double>(
              begin: gameState.postNarrativeSpawnFadeTick == 0 ? 1.0 : 0.0,
              end: 1.0,
            ),
            duration: gameState.postNarrativeSpawnFadeTick == 0 || reduceMotion
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
                            milliseconds: gameState.narrativeGemFlightMs,
                          ),
                    curve: Curves.easeInOutCubic,
                    left: item.position.dx,
                    top: item.position.dy,
                    width: itemSize,
                    height: itemSize,
                    child: Opacity(
                      opacity:
                          narrativeStep3Dim && !narrativeTrio.contains(item.id)
                          ? 0.34
                          : 1.0,
                      child: _NarrativeTargetGemPulse(
                        active: gameState.narrativeGuideGemShouldPulse(item.id),
                        child: FloatingGem(
                          enabled: boardIds.contains(item.id),
                          floatPeriodMs: item.floatPeriodMs,
                          floatPhase: item.floatPhase,
                          size: itemSize,
                          child: _GemTapJuice(
                            semanticsLabel: gemAccessibilityLabel(
                              AppLocalizations.of(context)!,
                              item.typeId,
                              item.colorId,
                            ),
                            isOnBoard: boardIds.contains(item.id),
                            typeId: item.typeId,
                            neon: neonColor(item.colorId),
                            stakeTapTraceColor: gameState.isHighStakesSession
                                ? const Color(0xFFFFD700)
                                : gameState.isRoyalSession
                                ? const Color(0xFFE49BFF)
                                : null,
                            stakeTapParticleBoost: gameState.isRoyalSession
                                ? 1.22
                                : 1.0,
                            onSelect: () => gameState.selectItem(item.id),
                            child: _ItemFx(
                              id: item.id,
                              isRemoving: gameState.removingIds.contains(
                                item.id,
                              ),
                              kind: gameState.removalKindFor(item.id),
                              typeId: item.typeId,
                              neon: neonColor(item.colorId),
                              child: _NeonHalo(
                                color: neonColor(item.colorId),
                                alert: gameState.alertIds.contains(item.id),
                                lowGlow:
                                    gameState.isTrinityTutorialActive ||
                                    gameState.isNarrativeTutorialActive,
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
    ];
  }
}
