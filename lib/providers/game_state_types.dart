import 'package:flutter/material.dart';

export '../game/match_types.dart';

/// Tutoriel « La Trinité » (partie casual niveau 1 tant que non complété en prefs).
enum TrinityTutorialPhase { none, shape, color, perfect }

/// Tutoriel narratif (menu Tutoriel, casual ; remplace la trinité le temps de la séquence).
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

/// Résultat d’un achat de consommable LUX (Forge).
enum ForgePurchaseOutcome {
  insufficientLux,
  purchasedInsurance,
  purchasedRoyalBounty,
  insuranceStackFull,
  royalBountyAlreadyActive,
  purchasedChronoPulse,
  chronoPulseStackFull,
  purchasedMercySalvage,
  mercySalvageStackFull,
}

/// Réclamation du bonus LUX quotidien (menu principal).
enum DailyLuxClaimOutcome {
  successServerApplied,
  successQueuedOffline,
  alreadySyncedServerSide,
  alreadyClaimedToday,
  networkUnavailable,
  callableFailed,
}

/// Message dock Oracle (tutoriel narratif) — texte résolu via [AppLocalizations].
enum OracleDockMessageId {
  none,
  step1Shape,
  step2Color,
  step3Perfect,
  celebration,
}

/// Bannière tutoriel « Trinité » (hors run narrative).
enum TrinityBannerId { none, shapeIntro, colorIntro, perfectIntro }

/// Floater LUX fixe pendant le tutoriel narratif (sinon libellé runtime).
enum NarrativeFloatingKey { shapeBonus, colorBonus, perfectBonus }

/// Floater LUX hors tutoriel narratif — résolu en UI via [AppLocalizations].
enum RuntimeLuxFloatKind { luxGain, luxGainMult, perfectGain, perfectGainMult }

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
    this.narrativeFloatKey,
    this.runtimeLuxKind,
    this.runtimeGain,
    this.runtimeChainMult,
  });

  final String id;
  final String text;
  final Offset position;
  final int typeId;
  final int colorId;

  /// Style « burst » sur le floater ; le parfait narratif n’affiche plus le floater.
  final bool isNarrativePerfectBurst;

  /// Si non null, l’UI affiche la chaîne ARB correspondante au lieu de [text].
  final NarrativeFloatingKey? narrativeFloatKey;

  /// Gain LUX runtime (hors [narrativeFloatKey]) — résolu en UI.
  final RuntimeLuxFloatKind? runtimeLuxKind;
  final int? runtimeGain;
  final String? runtimeChainMult;
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
    required this.position,
    required this.chainMult,
  });

  final String id;
  final Offset position;
  final double chainMult;
}
