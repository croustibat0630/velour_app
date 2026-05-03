import 'dart:async';

import 'package:flutter/material.dart';

import '../providers/game_state_types.dart';

/// État du tutoriel « Trinité » (hors première partie narrative).
///
/// Le plateau et la persistance disque sont pilotés par [GameState] via callbacks.
class TrinityTutorialService extends ChangeNotifier {
  bool _complete = false;
  TrinityTutorialPhase _phase = TrinityTutorialPhase.none;
  TrinityBannerId _bannerId = TrinityBannerId.none;
  int _bannerTick = 0;

  bool get isComplete => _complete;

  TrinityTutorialPhase get phase => _phase;

  TrinityBannerId get bannerId => _bannerId;

  int get bannerTick => _bannerTick;

  bool get isChronoFrozen =>
      _phase == TrinityTutorialPhase.shape ||
      _phase == TrinityTutorialPhase.color ||
      _phase == TrinityTutorialPhase.perfect;

  void hydrateCompleteFromDisk(bool trinityTutorialComplete) {
    _complete = trinityTutorialComplete;
    notifyListeners();
  }

  /// Fin du tutoriel narratif : trinité considérée acquise (prefs alignées côté parent).
  void markCompleteFromNarrative() {
    _complete = true;
    _phase = TrinityTutorialPhase.none;
    _bannerId = TrinityBannerId.none;
    notifyListeners();
  }

  void hardReset() {
    _complete = false;
    _phase = TrinityTutorialPhase.none;
    _bannerId = TrinityBannerId.none;
    _bannerTick++;
    notifyListeners();
  }

  void clearForNarrativeFirstRun() {
    _phase = TrinityTutorialPhase.none;
    _bannerId = TrinityBannerId.none;
    notifyListeners();
  }

  void beginShapeIntro() {
    _phase = TrinityTutorialPhase.shape;
    _bannerId = TrinityBannerId.shapeIntro;
    _bannerTick++;
    notifyListeners();
  }

  void clearForInactiveBoardInit() {
    _phase = TrinityTutorialPhase.none;
    _bannerId = TrinityBannerId.none;
    notifyListeners();
  }

  bool shouldOfferAtInit({
    required bool isFirstTimeGame,
    required SessionStakeKind stake,
    required int gameLevel,
  }) =>
      !isFirstTimeGame &&
      stake == SessionStakeKind.casual &&
      !_complete &&
      gameLevel == 1;

  void advanceAfterMatch(
    RunBasis basis, {
    required Future<void> Function() persistTrinityTutorialComplete,
    required void Function() onClearSlotsAndBoard,
    required void Function() onReseedTrinityBoard,
    required void Function() onFillBoardToCap,
  }) {
    if (_complete) {
      _phase = TrinityTutorialPhase.none;
      return;
    }
    bool ok = false;
    switch (_phase) {
      case TrinityTutorialPhase.shape:
        ok = basis == RunBasis.shape;
        break;
      case TrinityTutorialPhase.color:
        ok = basis == RunBasis.color;
        break;
      case TrinityTutorialPhase.perfect:
        ok = basis == RunBasis.perfect;
        break;
      case TrinityTutorialPhase.none:
        return;
    }
    if (!ok) {
      return;
    }

    switch (_phase) {
      case TrinityTutorialPhase.shape:
        _phase = TrinityTutorialPhase.color;
        _bannerId = TrinityBannerId.colorIntro;
        break;
      case TrinityTutorialPhase.color:
        _phase = TrinityTutorialPhase.perfect;
        _bannerId = TrinityBannerId.perfectIntro;
        break;
      case TrinityTutorialPhase.perfect:
        _complete = true;
        _phase = TrinityTutorialPhase.none;
        _bannerId = TrinityBannerId.none;
        unawaited(persistTrinityTutorialComplete());
        onClearSlotsAndBoard();
        _bannerTick++;
        onFillBoardToCap();
        notifyListeners();
        return;
      case TrinityTutorialPhase.none:
        return;
    }
    onClearSlotsAndBoard();
    onReseedTrinityBoard();
    _bannerTick++;
    notifyListeners();
  }
}
