import 'dart:async';

import 'package:flutter/material.dart';

import '../providers/game_state_types.dart';
import '../utils/velour_audit_log.dart';

/// État du tutoriel « Trinité » (bannières shape / couleur / perfect).
///
/// Ne s’arme plus au démarrage d’une partie standard : l’apprentissage passe par le
/// menu Tutoriel (narratif). [GameState] peut encore appeler [beginShapeIntro] en
/// interne (tests / futur) ; le plateau initial ne l’utilise plus.
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
    VelourAuditLog.event(
      'tutorial.trinity.begin',
      data: <String, Object?>{'phase': _phase.toString()},
    );
    notifyListeners();
  }

  void clearForInactiveBoardInit() {
    _phase = TrinityTutorialPhase.none;
    _bannerId = TrinityBannerId.none;
    notifyListeners();
  }

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
        VelourAuditLog.event(
          'tutorial.trinity.phase',
          data: <String, Object?>{'phase': _phase.toString()},
        );
        break;
      case TrinityTutorialPhase.color:
        _phase = TrinityTutorialPhase.perfect;
        _bannerId = TrinityBannerId.perfectIntro;
        VelourAuditLog.event(
          'tutorial.trinity.phase',
          data: <String, Object?>{'phase': _phase.toString()},
        );
        break;
      case TrinityTutorialPhase.perfect:
        _complete = true;
        _phase = TrinityTutorialPhase.none;
        _bannerId = TrinityBannerId.none;
        VelourAuditLog.event('tutorial.trinity.complete');
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
