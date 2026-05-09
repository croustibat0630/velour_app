import 'package:velour_app/l10n/app_localizations.dart';
import 'package:velour_app/models/game_item.dart';
import 'package:velour_app/providers/game_state.dart';

/// VoiceOver / TalkBack label for one rack column (index matches [GameState.slotItems] order).
///
/// Occupied slots use a short label so shape/color is not duplicated with the gem’s own
/// [Semantics] on the floating piece.
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
  String base = l10n.a11yRackSlotOccupied(slot, max);
  if (imminentSlotIdxs.contains(indexZero)) {
    base = '$base ${l10n.a11yRackSlotImminentHint}';
  }
  return base;
}
