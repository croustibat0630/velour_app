import 'package:flutter/widgets.dart';

/// « Réduire les mouvements » (iOS) / équivalent : [MediaQueryData.disableAnimations].
///
/// Utilise [MediaQuery.disableAnimationsOf] pour rester aligné sur le signal OS
/// attendu par Apple (accessibilité / validation store).
bool velourReduceMotion(BuildContext context) {
  return MediaQuery.disableAnimationsOf(context);
}

/// Navigation **clavier / souris « classique »** (ex. macOS, certains claviers externes).
///
/// Quand [NavigationMode.traditional] est actif, les contrôles doivent exposer un état
/// de **focus** visible (Material [InkWell.focusColor], etc.). Voir
/// [MediaQuery.maybeNavigationModeOf].
///
/// [NavigationMode.directional] correspond surtout aux UIs type télécommande / D-pad.
bool velourTraditionalKeyboardNavigation(BuildContext context) {
  return MediaQuery.maybeNavigationModeOf(context) ==
      NavigationMode.traditional;
}
