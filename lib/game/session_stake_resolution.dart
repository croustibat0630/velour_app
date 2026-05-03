import 'session_stake_constants.dart';
import '../providers/game_state_types.dart';

/// Résultat de la résolution des mises premium en fin de run (logique pure, testable).
class SessionStakeResolution {
  const SessionStakeResolution({
    required this.footerLine,
    required this.rewardLuxCoins,
    required this.replaySuggestedStake,
  });

  final SessionStakeFooterLine footerLine;
  final int rewardLuxCoins;
  final SessionStakeKind replaySuggestedStake;
}

/// Applique les règles High Stakes / Royal à la fin d’une session (niveau atteint vs objectif).
///
/// Les défauts numériques viennent de [SessionStakeConstants] (source unique).
SessionStakeResolution resolveSessionStakeOnGameOver({
  required SessionStakeKind sessionStake,
  required int gameLevel,
  int highStakesTargetLevel = SessionStakeConstants.highStakesTargetLevel,
  int royalTargetLevel = SessionStakeConstants.royalTargetLevel,
  int highStakesWinLux = SessionStakeConstants.highStakesWinLux,
  int royalWinLux = SessionStakeConstants.royalWinLux,
}) {
  final SessionStakeKind ended = sessionStake;

  if (ended == SessionStakeKind.casual) {
    return const SessionStakeResolution(
      footerLine: SessionStakeFooterLine.none,
      rewardLuxCoins: 0,
      replaySuggestedStake: SessionStakeKind.casual,
    );
  }

  if (ended == SessionStakeKind.highStakes) {
    if (gameLevel < highStakesTargetLevel) {
      return SessionStakeResolution(
        footerLine: SessionStakeFooterLine.highStakesFail,
        rewardLuxCoins: 0,
        replaySuggestedStake: ended,
      );
    }
    return SessionStakeResolution(
      footerLine: SessionStakeFooterLine.highStakesWin150Lux,
      rewardLuxCoins: highStakesWinLux,
      replaySuggestedStake: ended,
    );
  }

  if (ended == SessionStakeKind.royal) {
    if (gameLevel < royalTargetLevel) {
      return SessionStakeResolution(
        footerLine: SessionStakeFooterLine.royalFail,
        rewardLuxCoins: 0,
        replaySuggestedStake: ended,
      );
    }
    return SessionStakeResolution(
      footerLine: SessionStakeFooterLine.royalWin1250Lux,
      rewardLuxCoins: royalWinLux,
      replaySuggestedStake: ended,
    );
  }

  return const SessionStakeResolution(
    footerLine: SessionStakeFooterLine.none,
    rewardLuxCoins: 0,
    replaySuggestedStake: SessionStakeKind.casual,
  );
}
