import 'package:flutter/widgets.dart';

/// « Réduire les mouvements » (iOS) / équivalent : [MediaQueryData.disableAnimations].
bool velourReduceMotion(BuildContext context) {
  return MediaQuery.maybeOf(context)?.disableAnimations ?? false;
}
