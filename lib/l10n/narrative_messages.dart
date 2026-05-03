import 'package:velour_app/l10n/app_localizations.dart';

import '../providers/game_state_types.dart';

String resolveOracleDockMessage(AppLocalizations l10n, OracleDockMessageId id) {
  return switch (id) {
    OracleDockMessageId.none => '',
    OracleDockMessageId.step1Shape => l10n.oracleDockStep1Shape,
    OracleDockMessageId.step2Color => l10n.oracleDockStep2Color,
    OracleDockMessageId.step3Perfect => l10n.oracleDockStep3Perfect,
    OracleDockMessageId.celebration => l10n.oracleDockCelebration,
  };
}

String resolveTrinityBanner(AppLocalizations l10n, TrinityBannerId id) {
  return switch (id) {
    TrinityBannerId.none => '',
    TrinityBannerId.shapeIntro => l10n.tutorialTrinityShapeIntro,
    TrinityBannerId.colorIntro => l10n.tutorialTrinityColorIntro,
    TrinityBannerId.perfectIntro => l10n.tutorialTrinityPerfectIntro,
  };
}

String resolveNarrativeFloating(
  AppLocalizations l10n,
  NarrativeFloatingKey key,
) {
  return switch (key) {
    NarrativeFloatingKey.shapeBonus => l10n.narrativeFloatShapeBonus,
    NarrativeFloatingKey.colorBonus => l10n.narrativeFloatColorBonus,
    NarrativeFloatingKey.perfectBonus => l10n.narrativeFloatPerfectBonus,
  };
}
