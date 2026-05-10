// Assemble les calques overlay du jeu dans l'ordre du [Stack] racine.

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
      ...buildNarrativeTutorialOverlayLayers(
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
      ),
      ...buildFxOverlayLayersBetweenNarrativeAndHud(
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
      ),
      ...buildHudOverlayLayers(
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
      ),
      ...buildFxOverlayLayersAboveHud(
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
      ),
    ];
  }
}
