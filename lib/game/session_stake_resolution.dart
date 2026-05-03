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
/// Les constantes numériques restent sur [GameState] côté UI ; ici on duplique les seuils
/// pour garder ce module autonome (aligné avec `GameState.highStakesTargetLevel`, etc.).
SessionStakeResolution resolveSessionStakeOnGameOver({
  required SessionStakeKind sessionStake,
  required int gameLevel,
  int highStakesTargetLevel = 3,
  int royalTargetLevel = 5,
  int highStakesWinLux = 150,
  int royalWinLux = 1250,
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
