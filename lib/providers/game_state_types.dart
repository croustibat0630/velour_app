import 'package:flutter/material.dart';

/// Résolution d’un groupe de gemmes identiques (forme / couleur / perfect).
enum MatchKind { normal, boosted, overcharge, perfect }

/// Base de run pour tutoriels et libellés (interne au moteur de match).
enum RunBasis { shape, color, perfect }

/// Tutoriel « La Trinité » (partie casual niveau 1 tant que non complété en prefs).
enum TrinityTutorialPhase { none, shape, color, perfect }

/// Tutoriel narratif « première partie » (remplace l’overlay + trinité si actif).
enum NarrativeTutorialPhase {
  none,
  step1Shape,
  step2Color,
  step3Perfect,
  celebration,
}

/// Mise choisie avant une partie (écran préparation).
enum SessionStakeKind { casual, highStakes, royal }

/// Ligne de pied de page sur l’overlay fin de partie (mises premium).
enum SessionStakeFooterLine {
  none,
  highStakesFail,
  highStakesWin150Lux,
  royalFail,
  royalWin1250Lux,
}

/// Résultat d’un tap sur une ligne skin en boutique.
enum SkinPurchaseOutcome {
  insufficientLux,
  purchasedAndEquipped,
  equippedFromOwned,
  alreadyEquipped,
}

class FlightFx {
  FlightFx({
    required this.id,
    required this.from,
    required this.to,
    required this.typeId,
    required this.colorId,
  });

  final String id;
  final Offset from;
  final Offset to;
  final int typeId;
  final int colorId;
}

class FloatingTextFx {
  FloatingTextFx({
    required this.id,
    required this.text,
    required this.position,
    required this.typeId,
    required this.colorId,
    this.isNarrativePerfectBurst = false,
  });

  final String id;
  final String text;
  final Offset position;
  final int typeId;
  final int colorId;

  /// Style « burst » sur le floater ; le parfait narratif n’affiche plus le floater.
  final bool isNarrativePerfectBurst;
}

/// Petit « +1 » tutoriel narratif : part de la gemme vers le haut / la zone score.
class NarrativeGemGainFx {
  NarrativeGemGainFx({
    required this.id,
    required this.from,
    required this.colorId,
  });

  final String id;
  final Offset from;
  final int colorId;
}

class MatchParticleFx {
  MatchParticleFx({
    required this.id,
    required this.center,
    required this.typeId,
    required this.colorId,
    required this.particleCount,
    required this.perfectLuxBurst,
  });

  final String id;
  final Offset center;
  final int typeId;
  final int colorId;

  /// LUX Dust : 15–20 base ; ×3 si [perfectLuxBurst].
  final int particleCount;
  final bool perfectLuxBurst;
}

/// Texte combo cascade (scale + slide côté UI).
class ComboFloaterFx {
  ComboFloaterFx({
    required this.id,
    required this.text,
    required this.position,
  });

  final String id;
  final String text;
  final Offset position;
}
