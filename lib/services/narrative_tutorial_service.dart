import 'dart:async';

import 'package:flutter/material.dart';

import '../providers/game_state_types.dart';

/// État et effets UI du tutoriel narratif « première partie ».
///
/// Le plateau, le chrono [ValueNotifier] et la persistance restent sur
/// [GameState] ; ce service reçoit des callbacks pour les mutations moteur.
class NarrativeTutorialService extends ChangeNotifier {
  NarrativeTutorialService({
    required Future<void> Function() onPersistTutorialComplete,
    required void Function() onExplosionShake,
    required void Function(double portion) refundTimeBarPortion,
    required void Function() setTimeBarFull,
    required void Function() onReseedBoardAfterShapeTutorialMatch,
    required void Function() onReseedBoardAfterColorTutorialMatch,
    required void Function() onCelebrationStarted,
  }) : _onPersistTutorialComplete = onPersistTutorialComplete,
       _onExplosionShake = onExplosionShake,
       _refundTimeBarPortion = refundTimeBarPortion,
       _setTimeBarFull = setTimeBarFull,
       _onReseedAfterShape = onReseedBoardAfterShapeTutorialMatch,
       _onReseedAfterColor = onReseedBoardAfterColorTutorialMatch,
       _onCelebrationStarted = onCelebrationStarted;

  final Future<void> Function() _onPersistTutorialComplete;
  final void Function() _onExplosionShake;
  final void Function(double portion) _refundTimeBarPortion;
  final void Function() _setTimeBarFull;
  final void Function() _onReseedAfterShape;
  final void Function() _onReseedAfterColor;
  final void Function() _onCelebrationStarted;

  NarrativeTutorialPhase _phase = NarrativeTutorialPhase.none;
  NarrativeTutorialPhase get phase => _phase;

  int _uiReveal = 0;
  int get uiReveal => _uiReveal;

  int _luxIntroTick = 0;
  int get luxIntroTick => _luxIntroTick;

  final List<String> _tapOrder = <String>[];
  List<String> get tapOrder => List<String>.unmodifiable(_tapOrder);

  int _tapProgress = 0;
  int get tapProgress => _tapProgress;

  int _perfectBannerTick = 0;
  int get perfectBannerTick => _perfectBannerTick;

  int _postSpawnFadeTick = 0;
  int get postSpawnFadeTick => _postSpawnFadeTick;

  Timer? _finalizeTimer;
  Timer? _gemGainClearTimer;

  int _rippleTick = 0;
  int get rippleTick => _rippleTick;
  Offset? _rippleCenter;
  Offset? get rippleCenter => _rippleCenter;

  NarrativeGemGainFx? _gemGainFx;
  NarrativeGemGainFx? get gemGainFx => _gemGainFx;
  int _gemGainTick = 0;
  int get gemGainTick => _gemGainTick;

  bool get isCoreSteps =>
      _phase == NarrativeTutorialPhase.step1Shape ||
      _phase == NarrativeTutorialPhase.step2Color ||
      _phase == NarrativeTutorialPhase.step3Perfect;

  bool get isStep3Perfect => _phase == NarrativeTutorialPhase.step3Perfect;

  Set<String> get trioIds {
    if (!isCoreSteps) return const <String>{};
    return Set<String>.from(_tapOrder);
  }

  bool guideGemShouldPulse(String id) {
    if (!isCoreSteps) return false;
    if (_tapProgress >= _tapOrder.length) return false;
    return _tapOrder.contains(id);
  }

  /// Filtre les taps plateau hors des 3 gemmes du palier tant qu’il reste des slots à remplir.
  bool shouldAcceptBoardSelect(String id) {
    if (!isCoreSteps) return true;
    if (_tapProgress >= _tapOrder.length) return true;
    return _tapOrder.contains(id);
  }

  int get gemFlightMs =>
      _phase == NarrativeTutorialPhase.step3Perfect ? 1400 : 400;

  int? get tutorialStepDotIndex {
    switch (_phase) {
      case NarrativeTutorialPhase.step1Shape:
        return 0;
      case NarrativeTutorialPhase.step2Color:
        return 1;
      case NarrativeTutorialPhase.step3Perfect:
        return 2;
      case NarrativeTutorialPhase.celebration:
      case NarrativeTutorialPhase.none:
        return null;
    }
  }

  OracleDockMessageId get oracleDockMessageId {
    switch (_phase) {
      case NarrativeTutorialPhase.step1Shape:
        return OracleDockMessageId.step1Shape;
      case NarrativeTutorialPhase.step2Color:
        return OracleDockMessageId.step2Color;
      case NarrativeTutorialPhase.step3Perfect:
        return OracleDockMessageId.step3Perfect;
      case NarrativeTutorialPhase.celebration:
        return OracleDockMessageId.celebration;
      case NarrativeTutorialPhase.none:
        return OracleDockMessageId.none;
    }
  }

  ({double level, double lux, double score, double time}) hudOpacities(
    bool isFirstTimeGame,
  ) {
    if (!isFirstTimeGame || _phase == NarrativeTutorialPhase.none) {
      return (level: 1.0, lux: 1.0, score: 1.0, time: 1.0);
    }
    if (_uiReveal <= 0) {
      return (level: 0.0, lux: 0.0, score: 0.0, time: 0.0);
    }
    if (_uiReveal == 1) {
      return (level: 0.0, lux: 1.0, score: 1.0, time: 0.0);
    }
    if (_uiReveal == 2) {
      return (level: 0.0, lux: 1.0, score: 1.0, time: 1.0);
    }
    return (level: 1.0, lux: 1.0, score: 1.0, time: 1.0);
  }

  bool isChronoFrozen(bool isFirstTimeGame) =>
      isFirstTimeGame &&
      (_phase == NarrativeTutorialPhase.step1Shape ||
          _phase == NarrativeTutorialPhase.step2Color ||
          _phase == NarrativeTutorialPhase.step3Perfect ||
          _phase == NarrativeTutorialPhase.celebration);

  NarrativeFloatingKey? floatingKeyForMatch(RunBasis basis) {
    if (!isCoreSteps) {
      return null;
    }
    switch (_phase) {
      case NarrativeTutorialPhase.step1Shape:
        if (basis == RunBasis.shape) {
          return NarrativeFloatingKey.shapeBonus;
        }
        return null;
      case NarrativeTutorialPhase.step2Color:
        if (basis == RunBasis.color) {
          return NarrativeFloatingKey.colorBonus;
        }
        return null;
      case NarrativeTutorialPhase.step3Perfect:
        if (basis == RunBasis.perfect) {
          return NarrativeFloatingKey.perfectBonus;
        }
        return null;
      case NarrativeTutorialPhase.celebration:
      case NarrativeTutorialPhase.none:
        return null;
    }
  }

  /// Annule le timer de fin de tutoriel (ex. hard reset / réinit plateau).
  void cancelFinalizeTimer() {
    _finalizeTimer?.cancel();
    _finalizeTimer = null;
  }

  /// Première partie casual : entre en étape 1 avant [_seedNarrativeStep1Board].
  void beginCasualFirstRunBoardInit() {
    cancelFinalizeTimer();
    _phase = NarrativeTutorialPhase.step1Shape;
    _uiReveal = 0;
    _luxIntroTick = 0;
    _tapProgress = 0;
    _tapOrder.clear();
  }

  void beginNarrativeStepSeeding() {
    _tapOrder.clear();
    _tapProgress = 0;
  }

  void addTapId(String id) => _tapOrder.add(id);

  void applyAfterMatch(
    bool isFirstTimeGame,
    RunBasis basis,
    double timeRefundPortion,
  ) {
    if (!isFirstTimeGame || !isCoreSteps) {
      return;
    }
    switch (_phase) {
      case NarrativeTutorialPhase.step1Shape:
        if (basis != RunBasis.shape) {
          return;
        }
        _uiReveal = 1;
        _luxIntroTick++;
        _phase = NarrativeTutorialPhase.step2Color;
        _onReseedAfterShape();
        notifyListeners();
        break;
      case NarrativeTutorialPhase.step2Color:
        if (basis != RunBasis.color) {
          return;
        }
        _uiReveal = 2;
        _refundTimeBarPortion(timeRefundPortion);
        _phase = NarrativeTutorialPhase.step3Perfect;
        _onReseedAfterColor();
        notifyListeners();
        break;
      case NarrativeTutorialPhase.step3Perfect:
        if (basis != RunBasis.perfect) {
          return;
        }
        _uiReveal = 3;
        _setTimeBarFull();
        _onExplosionShake();
        _phase = NarrativeTutorialPhase.celebration;
        _perfectBannerTick++;
        _onCelebrationStarted();
        cancelFinalizeTimer();
        _finalizeTimer = Timer(const Duration(milliseconds: 2100), () {
          unawaited(completeTutorialFromTimer());
        });
        notifyListeners();
        break;
      default:
        break;
    }
  }

  Future<void> completeTutorialFromTimer() async {
    cancelFinalizeTimer();
    _phase = NarrativeTutorialPhase.none;
    notifyListeners();
    await _onPersistTutorialComplete();
  }

  void bumpPostSpawnFade() {
    _postSpawnFadeTick++;
    notifyListeners();
  }

  void onBoardGemSelectedDuringTutorial({
    required Offset itemTopLeft,
    required int colorId,
    required double itemSize,
    required String Function() nextId,
  }) {
    _rippleCenter = itemTopLeft + Offset(itemSize * 0.5, itemSize * 0.5);
    _rippleTick++;
    _gemGainFx = NarrativeGemGainFx(
      id: nextId(),
      from: itemTopLeft + Offset(itemSize * 0.38, itemSize * 0.32),
      colorId: colorId,
    );
    _gemGainTick++;
    _gemGainClearTimer?.cancel();
    _gemGainClearTimer = Timer(const Duration(milliseconds: 900), () {
      _gemGainFx = null;
      _gemGainTick++;
      notifyListeners();
    });
  }

  void incrementTapProgress() {
    _tapProgress++;
  }

  /// Fragment de [GameState.resetGame] (ripple / gem / LUX intro tick).
  void onParentResetGame() {
    _postSpawnFadeTick = 0;
    _rippleTick = 0;
    _rippleCenter = null;
    _gemGainClearTimer?.cancel();
    _gemGainClearTimer = null;
    if (_gemGainFx != null) {
      _gemGainFx = null;
      _gemGainTick++;
    }
    _luxIntroTick = 0;
  }

  void hardReset() {
    cancelFinalizeTimer();
    _gemGainClearTimer?.cancel();
    _gemGainClearTimer = null;
    _phase = NarrativeTutorialPhase.none;
    _uiReveal = 0;
    _luxIntroTick = 0;
    _tapOrder.clear();
    _tapProgress = 0;
    _rippleTick = 0;
    _rippleCenter = null;
    _gemGainFx = null;
    _gemGainTick++;
    _postSpawnFadeTick = 0;
    _perfectBannerTick = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    cancelFinalizeTimer();
    _gemGainClearTimer?.cancel();
    _gemGainClearTimer = null;
    super.dispose();
  }
}
