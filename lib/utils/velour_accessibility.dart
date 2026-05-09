import 'package:flutter/widgets.dart';

/// « Réduire les mouvements » (iOS) / équivalent : [MediaQueryData.disableAnimations].
///
/// Utilise [MediaQuery.disableAnimationsOf] pour rester aligné sur le signal OS
/// attendu par Apple (accessibilité / validation store).
bool velourReduceMotion(BuildContext context) {
  return MediaQuery.disableAnimationsOf(context);
}
