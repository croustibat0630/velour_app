import '../providers/game_state_types.dart';

/// Remboursement LUX quand l’assurance Oracle s’applique après échec d’une mise premium.
int oracleInsuranceRefundLux({
  required SessionStakeKind endedStake,
  required int highStakesAnteLux,
  required int royalAnteLux,
  int refundPercentOfAnte = 60,
}) {
  final int ante = switch (endedStake) {
    SessionStakeKind.highStakes => highStakesAnteLux,
    SessionStakeKind.royal => royalAnteLux,
    SessionStakeKind.casual => 0,
  };
  if (ante <= 0) return 0;
  return (ante * refundPercentOfAnte ~/ 100).clamp(0, ante);
}

bool isPremiumStakeFailure(SessionStakeFooterLine line) {
  return line == SessionStakeFooterLine.highStakesFail ||
      line == SessionStakeFooterLine.royalFail;
}
