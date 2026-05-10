// Assemble les calques overlay du jeu dans l'ordre du [Stack] racine.

part of 'game_screen.dart';

extension _GameScreenStateLayoutOverlays on _GameScreenState {
  List<Widget> buildScreenLayoutOverlayLayers(
    _GameOverlayLayoutBundle overlays,
  ) {
    return <Widget>[
      ...buildNarrativeTutorialOverlayLayers(overlays),
      ...buildFxOverlayLayersBetweenNarrativeAndHud(overlays),
      ...buildHudOverlayLayers(overlays),
      ...buildFxOverlayLayersAboveHud(overlays),
    ];
  }
}
