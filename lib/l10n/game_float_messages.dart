import 'package:velour_app/l10n/app_localizations.dart';

import '../providers/game_state_types.dart';

String resolveRuntimeLuxFloat(
  AppLocalizations l10n,
  RuntimeLuxFloatKind kind,
  int gain,
  String? chainMult,
) {
  final String m = chainMult ?? '';
  return switch (kind) {
    RuntimeLuxFloatKind.luxGain => l10n.gameFloatLuxGain(gain),
    RuntimeLuxFloatKind.luxGainMult => l10n.gameFloatLuxGainMult(gain, m),
    RuntimeLuxFloatKind.perfectGain => l10n.gameFloatPerfectGain(gain),
    RuntimeLuxFloatKind.perfectGainMult => l10n.gameFloatPerfectGainMult(
      gain,
      m,
    ),
  };
}
