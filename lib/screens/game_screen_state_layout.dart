// Scaffold + Stack : orchestre [buildScreenLayoutAmbientLayers],
// [buildScreenLayoutPlayfieldLayers], overlays (parts dédiés).

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
                      ...buildScreenLayoutAmbientLayers(
                        context: context,
                        gameState: gameState,
                        reduceMotion: reduceMotion,
                      ),
                      ...buildScreenLayoutPlayfieldLayers(
                        context: context,
                        gameState: gameState,
                        reduceMotion: reduceMotion,
                        items: items,
                        itemSize: itemSize,
                        narrativeStep3Dim: narrativeStep3Dim,
                        narrativeTrio: narrativeTrio,
                        boardIds: boardIds,
                        neonColor: neonColor,
                      ),
                      ...buildScreenLayoutOverlayLayers((
                        context: context,
                        gameState: gameState,
                        reduceMotion: reduceMotion,
                        width: width,
                        height: height,
                        slotBarHeight: slotBarHeight,
                        uiScale: uiScale,
                        narrativeOracleW: narrativeOracleW,
                        neonColor: neonColor,
                        luxBoardTop: luxBoardTop,
                        boardSpawnMinY: boardSpawnMinY,
                        itemSize: itemSize,
                      )),
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
