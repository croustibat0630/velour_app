import 'package:velour_app/l10n/app_localizations.dart';
import 'package:velour_app/models/game_item.dart';
import 'package:velour_app/providers/game_state.dart';
import 'package:velour_app/utils/gem_accessibility.dart';

/// VoiceOver / TalkBack label for one rack column (index matches [GameState.slotItems] order).
String rackSlotSemanticsLabel(
  AppLocalizations l10n,
  int indexZero,
  List<GameItem> slotItems,
  Set<int> imminentSlotIdxs,
) {
  final int slot = indexZero + 1;
  final int max = GameState.slotCount;
  if (indexZero >= slotItems.length) {
    return l10n.a11yRackSlotEmpty(slot, max);
  }
  final GameItem item = slotItems[indexZero];
  final String gem = gemAccessibilityLabel(l10n, item.typeId, item.colorId);
  String base = l10n.a11yRackSlotGem(slot, max, gem);
  if (imminentSlotIdxs.contains(indexZero)) {
    base = '$base ${l10n.a11yRackSlotImminentHint}';
  }
  return base;
}
