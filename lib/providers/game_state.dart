import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart' show QuerySnapshot;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game_state_local_store.dart';
import 'game_state_types.dart';
export 'game_state_types.dart';

import '../game/board_config.dart';
import '../game/board_flow_policy.dart';
import '../game/board_layout_logic.dart';
import '../game/board_spawn_logic.dart';
import '../game/meta_progression_policy.dart';
import '../game/forge_shop_logic.dart';
import '../game/match_scoring.dart';
import '../game/match_feedback.dart';
import '../game/perfect_heat_logic.dart';
import '../game/rack_logic.dart';
import '../game/run_timer_logic.dart';
import '../game/timer_tension_logic.dart';
import '../game/session_stake_constants.dart';
import '../game/session_stake_resolution.dart';
import '../game/tutorial_board_placer.dart';
import '../models/game_item.dart';
import '../models/skin_config.dart';
import '../services/audio_handler.dart';
import '../services/economy_service.dart';
import '../services/firestore_service.dart';
import '../services/lux_apply_motifs.dart';
import '../services/haptics_handler.dart';
import '../services/narrative_tutorial_service.dart';
import '../services/oracle_naming_service.dart';
import '../services/trinity_tutorial_service.dart';
import '../services/stats_service.dart';
import '../services/velour_observability.dart';
import '../utils/velour_audit_log.dart';
import '../utils/velour_debug_log.dart';
import '../widgets/ui/premium_alert_view.dart';

class GameState extends ChangeNotifier with WidgetsBindingObserver {
  static const int slotCount = 7;
  static const GameStateLocalStore _localDisk = GameStateLocalStore();
  static const Duration _baseMatchDelay = Duration(milliseconds: 350);

  final EconomyService _economy = EconomyService();

  /// Aligné sur [EconomyService.welcomeLuxGrant] (API stable pour l’UI).
  static int get welcomeLuxGrant => EconomyService.welcomeLuxGrant;

  /// Aligné sur [EconomyService.dailyLuxBonusAmount].
  static int get dailyLuxBonusAmount => EconomyService.dailyLuxBonusAmount;

  /// Marge LUX au-delà du snapshot cloud + tampons positifs lors du reconcile bootstrap
  /// (filets légers IAP / horloges désynchronisées).
  static const int bootstrapReconcileLuxTrustMargin = 500;

  late final NarrativeTutorialService _narrativeTutorial;
  final TrinityTutorialService _trinityTutorial = TrinityTutorialService();
  final OracleNamingService _oracleNaming = OracleNamingService();

  GameState() {
    _economy.addListener(notifyListeners);
    _economy.onPersonalBestCommitted = _oracleNaming.maybeOfferForNewHighScore;
    WidgetsBinding.instance.addObserver(this);
    _narrativeTutorial = NarrativeTutorialService(
      onPersistTutorialComplete: _persistNarrativeTutorialComplete,
      onExplosionShake: _narrativeExplosionShake,
      refundTimeBarPortion: (double portion) {
        timeBar.value = (timeBar.value + portion).clamp(0.0, 1.0);
      },
      setTimeBarFull: () {
        timeBar.value = 1.0;
      },
      onReseedBoardAfterShapeTutorialMatch: _seedNarrativeStep2Board,
      onReseedBoardAfterColorTutorialMatch: _seedNarrativeStep3Board,
      onCelebrationStarted: () => HapticsHandler.instance.mediumImpact(),
    );
    _narrativeTutorial.addListener(notifyListeners);
    _trinityTutorial.addListener(notifyListeners);
    _oracleNaming.addListener(notifyListeners);
  }

  bool _cloudLifecycleFlushBusy = false;

  /// Annule le debounce LUX, persiste le disque puis pousse LUX / record / skins
  /// vers Firestore (best-effort). Appelé sur [AppLifecycleState.paused] / [hidden].
  Future<void> flushCloudSyncOnAppHidden() async {
    if (_cloudLifecycleFlushBusy) return;
    _cloudLifecycleFlushBusy = true;
    try {
      await _economy.flushCloudSyncOnLifecycleHide();
      if (FirestoreService.instance.isCloudReady) {
        await FirestoreService.instance.pushMergedPlayerProgress(
          highScore: _economy.highScore,
          inventory: List<String>.from(_unlockedSkins),
          activeSkinId: _activeSkinId,
        );
      }
    } catch (e, st) {
      VelourObservability.logFirestoreFailure(
        'flushCloudSyncOnAppHidden',
        error: e,
        stackTrace: st,
      );
    } finally {
      _cloudLifecycleFlushBusy = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        unawaited(flushCloudSyncOnAppHidden());
        break;
      default:
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // Cloud — délégué à [FirestoreService] (auth + Firestore best-effort).
  // ---------------------------------------------------------------------------

  /// À appeler **après** chargement disque (ex. splash) : auth anonyme, merge
  /// local ∪ cloud (max LUX / max high score / union skins), persistance puis push.
  Future<void> bootstrapCloudAfterLocalLoad() async {
    await loadEconomyWelcome();
    await loadHighScore();

    final PlayerCloudPull? pulled = await FirestoreService.instance
        .initializeAuthAndPullSkins();
    if (pulled == null && !FirestoreService.instance.isCloudReady) {
      return;
    }
    if (pulled == null) {
      // Auth may be ready even if the pull failed; still try to offer Oracle naming
      // in case a personal best happened before cloud was initialized.
      unawaited(_oracleNaming.maybeOfferForNewHighScore(_economy.highScore));
      return;
    }

    try {
      final int pendingPositiveBudget = _economy
          .sumPendingPositiveLuxForCloud();
      final ({int? luxCoins, int? highScore}) pending = FirestoreService
          .instance
          .consumePendingCloudSyncHints();
      final int cloudLuxSnapshot = math.max(
        pulled.cloudLuxCoins,
        pending.luxCoins ?? 0,
      );
      await _economy.mergeBootstrapFromCloud(
        pulled: pulled,
        pendingLux: pending.luxCoins,
        pendingHigh: pending.highScore,
      );
      final int mergedLuxAfterBootstrap = _economy.luxCoins;
      final int reconcileCeiling =
          cloudLuxSnapshot +
          pendingPositiveBudget +
          bootstrapReconcileLuxTrustMargin;
      final int reconcileTarget = math.min(
        mergedLuxAfterBootstrap,
        reconcileCeiling,
      );
      if (_runStartedAt == null) {
        _runHighScoreBaseline = _economy.highScore;
      }

      final Set<String> union = <String>{..._unlockedSkins};
      if (pulled.inventory != null) {
        union.addAll(pulled.inventory!);
      }
      if (!union.contains(SkinCatalog.standard.id)) {
        union.add(SkinCatalog.standard.id);
      }
      _unlockedSkins = List<String>.from(union);

      final String? cActive = pulled.activeSkinId;
      if (!_unlockedSkins.contains(_activeSkinId)) {
        if (cActive != null &&
            cActive.isNotEmpty &&
            _unlockedSkins.contains(cActive)) {
          _activeSkinId = cActive;
        } else {
          _activeSkinId = SkinCatalog.standard.id;
        }
      }

      await _economy.persistLuxAndHighScoreLocalAfterBootstrap();
      await _persistSkinsLocal();
      notifyListeners();

      await FirestoreService.instance.reconcileBootstrapLuxAgainstSnapshot(
        targetMergedLux: reconcileTarget,
        cloudLuxSnapshot: cloudLuxSnapshot,
      );
      if (_economy.luxCoins > reconcileTarget) {
        await _economy.clampLuxCoinsToCeiling(reconcileTarget);
      }

      await FirestoreService.instance.pushMergedPlayerProgress(
        highScore: _economy.highScore,
        inventory: List<String>.from(_unlockedSkins),
        activeSkinId: _activeSkinId,
      );

      // If a personal best occurred before cloud init (or when offline), we may have
      // missed the initial offer. Re-check now that auth/doc exist.
      unawaited(_oracleNaming.maybeOfferForNewHighScore(_economy.highScore));
    } catch (e, st) {
      VelourObservability.logFirestoreFailure(
        'bootstrapCloudAfterLocalLoad',
        error: e,
        stackTrace: st,
      );
    }
  }

  bool get shouldShowNamingDialog => _oracleNaming.shouldShowDialog;

  void dismissNamingDialog() => _oracleNaming.dismiss();

  /// Enregistre le pseudo Oracle sur Firestore. Ne propage **jamais** d’exception
  /// (évite un dialogue bloqué avec bouton « busy » infini).
  /// `true` si la cérémonie peut se fermer (succès cloud ou fermeture locale hors-ligne).
  Future<bool> updateOracleName(String newName) =>
      _oracleNaming.submitName(newName);

  /// Stream classement mondial (Top 10) — best-effort. En cas d'erreur cloud,
  /// le StreamBuilder côté UI affichera un état vide.
  Stream<QuerySnapshot<Map<String, dynamic>>> getLeaderboardStream() {
    return FirestoreService.instance.leaderboardTopTenStream;
  }

  // Base visual constants (UI passes scaled values through setLayout).
  static const double baseItemSize = 45;
  static const double baseSlotSize = 45;
  static const double baseGridGap = 5;

  double _itemSize = baseItemSize;
  double _slotSize = baseSlotSize;
  double _gridGap = baseGridGap;

  double get itemSize => _itemSize;
  double get slotSize => _slotSize;
  final math.Random _rng = math.Random();

  /// Dernière action joueur (tap plateau) — tension chrono « idle hurry ».
  DateTime? _lastPlayerActionAt;

  /// Dernier échantillon de perf pour DDA (LUX/min entre matchs).
  DateTime? _lastMatchPerfSampleAt;
  double _perfEmaLuxPerMinute = MetaProgressionPolicy.neutralLuxPerMinute;

  final List<GameItem> _boardItems = <GameItem>[];
  final List<GameItem> _slotItems = <GameItem>[];
  int _slotInsertSeq = 0;
  final Map<String, int> _slotSeqById = <String, int>{};
  int _idSeq = 0;
  bool _initialized = false;

  Rect? _playZoneRect;
  List<Offset> _slotTopLefts = const <Offset>[];
  Rect _luxSafeRect = Rect.zero;
  double _boardSpawnMinY = 0;

  Timer? _matchTimer;
  Timer? _timeTimer;
  DateTime? _lastTimeTickAt;
  Timer? _matchParticleClearTimer;
  Timer? _comboFloaterClearTimer;

  /// True tant qu’un check match est armé (délai avant résolution).
  bool _awaitingScheduledMatch = false;

  /// True pendant la résolution d’un match (anim + score + remboursement temps).
  bool _isProcessingMatch = false;

  /// Incrémenté à chaque nouvelle planification ou annulation : un [Timer] annulé
  /// ne retire pas un callback `async` déjà lancé — les callbacks « en retard »
  /// doivent sortir sans toucher au plateau (sinon verrous / états incohérents).
  int _matchPipelineGeneration = 0;

  /// Le chrono est tombé à zéro pendant [_awaitingScheduledMatch] / [_isProcessingMatch].
  bool _deferredTimerGameOver = false;

  /// Exposé pour l’empreinte UI du jeu : sans ça, [notifyListeners] peut être ignoré
  /// alors que le chrono est déjà à zéro (game over différé).
  bool get hasDeferredTimerGameOver => _deferredTimerGameOver;

  /// Dernier jour UTC où le joueur a réclamé le bonus LUX quotidien (`yyyy-MM-dd`).
  String? _lastDailyLuxClaimUtcDay;
  DateTime? _runStartedAt;
  int _shapesPlacedThisRun = 0;
  int _matchesResolvedThisRun = 0;

  /// `true` une fois le tutoriel trinité terminé (prefs).
  bool get isTrinityTutorialComplete => _trinityTutorial.isComplete;

  /// Prefs « première partie » : reste `true` tant que le tutoriel narratif
  /// n’a pas été terminé depuis le menu [requestGuidedTutorialReplay] (persisté).
  /// Ne déclenche plus automatiquement le narratif sur « Commencer ».
  /// Défaut `false` jusqu’à [loadEconomyWelcome] (évite les tests sans prefs).
  bool _isFirstTimeGame = false;
  bool get isFirstTimeGame => _isFirstTimeGame;

  /// Relance volontaire du tutoriel narratif (menu) — consommé au lancement d’une partie casual.
  bool _guidedTutorialReplayPending = false;

  /// `true` le temps d’une run casual lancée depuis le menu « Tutoriel ».
  bool _narrativeReplayThisRun = false;

  /// Incrémenté à la fin du tutoriel narratif : [GameScreen] renvoie au menu principal.
  int _narrativeTutorialReturnToMainMenuTick = 0;

  int get narrativeTutorialReturnToMainMenuTick =>
      _narrativeTutorialReturnToMainMenuTick;

  /// Narrative active : uniquement une run casual lancée depuis le menu Tutoriel.
  bool get _narrativeRunEngaged =>
      _narrativeReplayThisRun && _sessionStake == SessionStakeKind.casual;

  NarrativeTutorialPhase get narrativePhase => _narrativeTutorial.phase;

  int get narrativeUiReveal => _narrativeTutorial.uiReveal;

  int get narrativeLuxIntroTick => _narrativeTutorial.luxIntroTick;

  int get narrativePerfectBannerTick => _narrativeTutorial.perfectBannerTick;

  int get postNarrativeSpawnFadeTick => _narrativeTutorial.postSpawnFadeTick;

  bool get isNarrativeTutorialActive =>
      _narrativeRunEngaged &&
      _narrativeTutorial.phase != NarrativeTutorialPhase.none;

  bool get _isNarrativeTutorialCoreSteps => _narrativeTutorial.isCoreSteps;

  Set<String> get narrativeTrioIds => _narrativeTutorial.trioIds;

  bool narrativeGuideGemShouldPulse(String id) =>
      _narrativeTutorial.guideGemShouldPulse(id);

  int get narrativeGemFlightMs => _narrativeTutorial.gemFlightMs;

  int get narrativeRippleTick => _narrativeTutorial.rippleTick;

  Offset? get narrativeRippleCenter => _narrativeTutorial.rippleCenter;

  NarrativeGemGainFx? get narrativeGemGainFx => _narrativeTutorial.gemGainFx;

  int get narrativeGemGainTick => _narrativeTutorial.gemGainTick;

  int? get narrativeTutorialStepDotIndex =>
      _narrativeTutorial.tutorialStepDotIndex;

  OracleDockMessageId get narrativeOracleDockMessageId =>
      _narrativeTutorial.oracleDockMessageId;

  ({double level, double lux, double score, double time})
  get narrativeHudOpacities =>
      _narrativeTutorial.hudOpacities(_narrativeRunEngaged);

  ComboFloaterFx? _comboFloater;
  int _comboFloaterTick = 0;

  /// Bloque plateau + chrono + spawn aléatoire pendant les phases trinité.
  bool get isTrinityTutorialChronoFrozen => _trinityTutorial.isChronoFrozen;

  bool get isTrinityTutorialActive => isTrinityTutorialChronoFrozen;

  /// Chrono figé pendant la séquence narrative (lancement depuis le menu Tutoriel).
  bool get isNarrativeTutorialChronoFrozen =>
      _narrativeTutorial.isChronoFrozen(_narrativeRunEngaged);

  /// Consommables Forge « en run » : désactivés pendant tutoriels scriptés.
  bool get _canUseForgeRunConsumables =>
      !isNarrativeTutorialActive && !isTrinityTutorialChronoFrozen;

  TrinityTutorialPhase get trinityTutorialPhase => _trinityTutorial.phase;

  TrinityBannerId get trinityBannerId => _trinityTutorial.bannerId;

  int get tutorialBannerTick => _trinityTutorial.bannerTick;

  ComboFloaterFx? get comboFloater => _comboFloater;

  int get comboFloaterTick => _comboFloaterTick;

  /// Verrou pipeline match + particules / cascades (pas d’interaction joueur).
  bool get isProcessingMatch => _isProcessingMatch;

  /// Délai avant résolution ou résolution en cours — utile HUD (feedback chrono bas).
  bool get isMatchResolutionActive =>
      _awaitingScheduledMatch || _isProcessingMatch;

  /// Base drain at level 1 (~33s to empty at 1.0 bar).
  static const double _baseTimeDrainPerSecond = 0.030;

  /// Difficulty / speed multiplier based on stake mode + level.
  ///
  /// - Casual (0 LUX): base 1.0
  /// - High Stakes (50 LUX): base 1.2
  /// - Royal (250 LUX): base 1.4 + 20% faster target appearance
  /// - Each level-up: speed × 1.15 (cumulative)
  double get _difficultySpeedMultiplier =>
      RunTimerLogic.difficultySpeedMultiplier(
        stake: _sessionStake,
        gameLevel: _gameLevel,
      );

  double get _timeDrainPerSecond => RunTimerLogic.timeDrainPerSecond(
    baseTimeDrainPerSecond: _baseTimeDrainPerSecond,
    stake: _sessionStake,
    gameLevel: _gameLevel,
  );

  Duration get _effectiveMatchDelay => RunTimerLogic.effectiveMatchDelay(
    baseMatchDelay: _baseMatchDelay,
    difficultySpeedMultiplier: _difficultySpeedMultiplier,
    isRoyalSession: isRoyalSession,
  );

  /// Time bar refill per match at level 1; shrinks ~5% per level.
  static const double _baseMatchTimeRefund = 0.20;
  double get _matchTimeRefund => RunTimerLogic.matchTimeRefund(
    baseMatchTimeRefund: _baseMatchTimeRefund,
    gameLevel: _gameLevel,
  );

  final ValueNotifier<double> timeBar = ValueNotifier<double>(1.0);
  double get timerValue => timeBar.value;

  /// Difficulty tier (1…). Advances when LUX earned this tier reaches
  /// `round(currentLevel * 1500 * 1.2)` (exponential-ish pressure).
  int _gameLevel = 1;
  int _luxAtLevelStart = 0;

  int get gameLevel => _gameLevel;

  /// Gem palette size (colors 1..N). Shapes use the same cap for parity.
  /// Levels 1–3: 4 | 4–6: 5 | 7–9: 6 | 10+: 7 (new shape/color)
  int get numberOfGemTypes {
    if (_gameLevel <= 3) return 4;
    if (_gameLevel <= 6) return 5;
    if (_gameLevel <= 9) return 6;
    return 7;
  }

  int _luxRequiredForNextLevel() =>
      MetaProgressionPolicy.luxRequiredForNextLevel(
        gameLevel: _gameLevel,
        perfEmaLuxPerMinute: _perfEmaLuxPerMinute,
      );

  int _levelUpFlashTick = 0;
  int get levelUpFlashTick => _levelUpFlashTick;

  bool _isLevelTransitionInProgress = false;
  bool get isLevelTransitionInProgress => _isLevelTransitionInProgress;
  int? _pendingLevelUpNeedLux;
  Timer? _levelTransitionTimer;

  int? _lastLuxBarLogLux;

  void _maybeAdvanceLevel() {
    if (_isLevelTransitionInProgress) return;
    final int need = _luxRequiredForNextLevel();
    final int into = _lux - _luxAtLevelStart;
    if (into >= need) {
      _isLevelTransitionInProgress = true;
      _pendingLevelUpNeedLux = need;
      _levelUpFlashTick++;
      HapticsHandler.instance.heavyImpact();
      // Sécurité : auto-commit même si l'UI ne rappelle pas (web/back).
      _levelTransitionTimer?.cancel();
      _levelTransitionTimer = Timer(
        const Duration(milliseconds: 1500),
        commitLevelTransitionIfAny,
      );
      notifyListeners();
    }
  }

  /// Interrompt l’animation / timer « level up » (chrono mort, deadlock, reset).
  void _resetLevelTransitionState() {
    _levelTransitionTimer?.cancel();
    _levelTransitionTimer = null;
    _isLevelTransitionInProgress = false;
    _pendingLevelUpNeedLux = null;
  }

  /// À appeler quand l'animation "Level Up" se termine (ou via timer de secours).
  void commitLevelTransitionIfAny() {
    if (!_isLevelTransitionInProgress) return;
    final int? need = _pendingLevelUpNeedLux;
    if (need == null) {
      _isLevelTransitionInProgress = false;
      notifyListeners();
      return;
    }
    _pendingLevelUpNeedLux = null;
    _luxAtLevelStart += need;
    _gameLevel++;
    _isLevelTransitionInProgress = false;
    // Si le score dépasse encore le palier suivant (gros combo), on ne retrigger
    // pas instantanément : un prochain gain relancera _maybeAdvanceLevel.
    notifyListeners();
  }

  final Set<String> _removingIds = <String>{};
  final Map<String, MatchKind> _removalKindById = <String, MatchKind>{};
  final Map<String, int> _removalTypeIdById = <String, int>{};
  final Map<String, int> _removalColorIdById = <String, int>{};

  final Set<String> _alertIds = <String>{};
  Set<String> get alertIds => Set.unmodifiable(_alertIds);

  final Set<int> _imminentSlotIdxs = <int>{};
  Set<int> get imminentSlotIdxs => Set.unmodifiable(_imminentSlotIdxs);

  int _sequenceTick = 0;
  int get sequenceTick => _sequenceTick;
  // Legacy: "sequence completed" feedback désactivé hors tutoriel.

  bool _isGameOver = false;
  bool get isGameOver => _isGameOver;

  bool _criticalFailure = false;
  bool get criticalFailure => _criticalFailure;

  int _gameOverFlashTick = 0;
  int get gameOverFlashTick => _gameOverFlashTick;

  // --- Perfect Heat (série de Perfects, bonus temps / LUX) ---
  int _heatTier = 1;
  int _heatConsecutivePerfects = 0;
  bool _heatReboundAvailable = false;
  bool _heatReboundPendingFromTimerDeath = false;
  final Set<int> _heatRescueConsumedTiers = <int>{};
  DateTime? _heatFreezeEnd;
  int _heatFreezeTick = 0;
  int _heatGhostFlashTick = 0;
  int _perfectHeatUiTick = 0;

  /// Même périmètre que les consos Forge en run : pas pendant tutoriels scriptés.
  bool get perfectHeatMechanicsActive => _canUseForgeRunConsumables;

  /// 0 = série brisée (attente REBOUND), 1–5 = palier courant.
  int get perfectHeatTier => _heatTier;

  int get perfectHeatConsecutivePerfects => _heatConsecutivePerfects;

  bool get perfectHeatReboundAvailable => _heatReboundAvailable;

  int get perfectHeatFreezeTick => _heatFreezeTick;

  int get perfectHeatGhostFlashTick => _heatGhostFlashTick;

  int get perfectHeatUiTick => _perfectHeatUiTick;

  bool get perfectHeatFreezeActive =>
      _heatFreezeEnd != null && DateTime.now().isBefore(_heatFreezeEnd!);

  void _initPerfectHeatForFreshReset() {
    _heatTier = 1;
    _heatConsecutivePerfects = 0;
    _heatReboundAvailable = false;
    _heatReboundPendingFromTimerDeath = false;
    _heatRescueConsumedTiers.clear();
    _heatFreezeEnd = null;
    _perfectHeatUiTick++;
  }

  int _heatBonusTierForPerfect() {
    if (_heatReboundAvailable && _heatTier == 0) return 2;
    return _heatTier.clamp(1, 5);
  }

  void _applyHeatDecayNonPerfect(MatchKind kind, RunBasis basis, int runCount) {
    if (!perfectHeatMechanicsActive) return;
    if (_heatReboundAvailable && _heatTier == 0) {
      _heatReboundAvailable = false;
      _heatReboundPendingFromTimerDeath = false;
    }
    if (_heatTier <= 0) return;
    if (PerfectHeatLogic.isNearMiss(kind, basis, runCount)) {
      _heatTier = math.max(1, _heatTier - 1);
    } else if (PerfectHeatLogic.isBadMiss(kind, basis, runCount)) {
      _heatTier = math.max(1, _heatTier - 2);
    } else {
      return;
    }
    _heatConsecutivePerfects = 0;
    _perfectHeatUiTick++;
  }

  void _applyHeatPerfectTimeRefillAfterRefund(
    int bonusTier,
    double timeSnapshotBeforeMatchRefund,
  ) {
    if (!perfectHeatMechanicsActive) return;
    final double baseFrac = PerfectHeatLogic.timeRefillFractionOfRemaining(
      bonusTier,
    );
    if (baseFrac <= 0) return;
    bool rescue = false;
    if (bonusTier >= 3 &&
        bonusTier <= 5 &&
        timeSnapshotBeforeMatchRefund < 0.15 &&
        !_heatRescueConsumedTiers.contains(bonusTier)) {
      rescue = true;
      _heatRescueConsumedTiers.add(bonusTier);
    }
    final double v = timeBar.value;
    final double delta = PerfectHeatLogic.heatTimeRefillDelta(
      timeBarValueAfterBaseRefund: v,
      baseRefillFraction: baseFrac,
      rescueDouble: rescue,
      timeDrainPerSecond: _timeDrainPerSecond,
    );
    if (delta > 0) {
      timeBar.value = (v + delta).clamp(0.0, 1.0);
    }
  }

  void _scheduleHeatFreezeRefresh() {
    _heatFreezeEnd = DateTime.now().add(const Duration(milliseconds: 500));
    _heatFreezeTick++;
    notifyListeners();
  }

  void _applyHeatPerfectTimeEffects(
    int bonusTier,
    double timeSnapshotBeforeMatchRefund,
  ) {
    if (!perfectHeatMechanicsActive) return;
    if (bonusTier == 4) {
      _scheduleHeatFreezeRefresh();
      return;
    }
    _applyHeatPerfectTimeRefillAfterRefund(
      bonusTier,
      timeSnapshotBeforeMatchRefund,
    );
  }

  void _advanceHeatAfterPerfect() {
    if (!perfectHeatMechanicsActive) return;
    if (_heatReboundAvailable && _heatTier == 0) {
      _heatTier = 2;
      _heatReboundAvailable = false;
      _heatReboundPendingFromTimerDeath = false;
    } else if (_heatTier == 0) {
      _heatTier = 1;
    } else {
      final int next = _heatTier + 1;
      _heatTier = next.clamp(1, 5);
    }
    _heatConsecutivePerfects++;
    _perfectHeatUiTick++;
  }

  void _breakPerfectHeatDeadlockInternal() {
    if (!perfectHeatMechanicsActive) return;
    _heatTier = 0;
    _heatConsecutivePerfects = 0;
    _heatReboundAvailable = false;
    _heatReboundPendingFromTimerDeath = false;
    _heatRescueConsumedTiers.clear();
    _heatFreezeEnd = null;
    _perfectHeatUiTick++;
  }

  void _breakPerfectHeatTimerGameOverInternal() {
    if (!perfectHeatMechanicsActive) return;
    _heatReboundPendingFromTimerDeath = true;
    _heatTier = 0;
    _heatConsecutivePerfects = 0;
    _heatRescueConsumedTiers.clear();
    _heatFreezeEnd = null;
    _perfectHeatUiTick++;
  }

  bool _paused = false;
  bool get paused => _paused;

  void setPaused(bool v) {
    if (_paused == v) return;
    _paused = v;
    if (_paused) {
      // Avoid a big dt spike when resuming.
      _lastTimeTickAt = null;
    } else {
      _tryFlushDeferredTimerGameOver();
    }
    notifyListeners();
  }

  int _shakeTick = 0;
  int get shakeTick => _shakeTick;
  double _shakeStrength = 0;
  double get shakeStrength => _shakeStrength;

  int _lux = 0;
  int get lux => _lux;

  /// Somme des gains bruts (avant multiplicateur prestige) pour l'écran de fin.
  int _runMatchLuxRawTotal = 0;
  int get runMatchLuxRawTotal => _runMatchLuxRawTotal;

  bool _lastGameWasPersonalBest = false;
  bool get lastGameWasPersonalBest => _lastGameWasPersonalBest;

  /// Mise de la dernière partie terminée (pour rejouer / UI fin de partie).
  SessionStakeKind _lastEndedRunStakeKind = SessionStakeKind.casual;
  SessionStakeKind get lastEndedRunStakeKind => _lastEndedRunStakeKind;

  /// LUX meta crédités sur victoire premium (0 sinon).
  int _lastStakeRewardLuxCoins = 0;
  int get lastStakeRewardLuxCoins => _lastStakeRewardLuxCoins;

  /// Suggestion « rejouer » : consommée par `resetGame()`.
  SessionStakeKind? _replaySuggestedStake;
  SessionStakeKind? get replaySuggestedStake => _replaySuggestedStake;

  int get luxCoins => _economy.luxCoins;

  static String _todayUtcYmd() {
    final DateTime n = DateTime.now().toUtc();
    final String mm = n.month.toString().padLeft(2, '0');
    final String dd = n.day.toString().padLeft(2, '0');
    return '${n.year}-$mm-$dd';
  }

  bool get canClaimDailyLuxBonus =>
      _economy.economyLoadedFromDisk &&
      _lastDailyLuxClaimUtcDay != _todayUtcYmd();

  /// Réclame [EconomyService.dailyLuxBonusAmount] LUX une fois par jour UTC (serveur borne).
  Future<DailyLuxClaimOutcome> claimDailyLuxBonus() async {
    final String today = _todayUtcYmd();
    if (_lastDailyLuxClaimUtcDay == today) {
      return DailyLuxClaimOutcome.alreadyClaimedToday;
    }
    if (!FirestoreService.instance.isCloudReady) {
      _economy.addLuxCoins(
        EconomyService.dailyLuxBonusAmount,
        luxCloudMotif: LuxApplyMotifs.dailyBonus,
      );
      _lastDailyLuxClaimUtcDay = today;
      await _localDisk.persistLastDailyLuxClaimUtcDay(today);
      notifyListeners();
      return DailyLuxClaimOutcome.successQueuedOffline;
    }
    final LuxDeltaApplyResult? r = await FirestoreService.instance
        .tryApplyLuxDeltaViaCallable(
          EconomyService.dailyLuxBonusAmount,
          motif: LuxApplyMotifs.dailyBonus,
          idempotencyKey: 'daily_bonus|$today',
        );
    if (r == null) {
      return DailyLuxClaimOutcome.networkUnavailable;
    }
    if (!r.ok) {
      return DailyLuxClaimOutcome.callableFailed;
    }
    final int applied = r.appliedDelta ?? 0;
    _lastDailyLuxClaimUtcDay = today;
    await _localDisk.persistLastDailyLuxClaimUtcDay(today);
    if (r.newLux != null) {
      await _economy.applyLuxCoinsFloorFromServer(r.newLux!);
    }
    notifyListeners();
    if (applied <= 0) {
      return DailyLuxClaimOutcome.alreadySyncedServerSide;
    }
    return DailyLuxClaimOutcome.successServerApplied;
  }

  List<String> _unlockedSkins = <String>[SkinCatalog.standard.id];
  List<String> get unlockedSkins => List.unmodifiable(_unlockedSkins);

  String _activeSkinId = SkinCatalog.standard.id;
  String get activeSkinId => _activeSkinId;

  SkinConfig get currentSkin => SkinCatalog.byId(_activeSkinId);

  /// Crédit meta en attente : utilisé pour déclencher le "juice" (count-up + SFX)
  /// à l'arrivée sur l'écran suivant (ex: retour du Shop).
  int get pendingLuxAnimation => _economy.pendingLuxAnimation;

  SessionStakeKind _sessionStake = SessionStakeKind.casual;
  SessionStakeKind get sessionStake => _sessionStake;

  /// Consommables Forge (persistés).
  int _oracleInsuranceCharges = 0;
  bool _royalVictoryBountyPending = false;

  /// Évite une double résolution de mise (chrono vs impasse) sur la même fin de run.
  bool _sessionStakeResolveConsumed = false;

  int get oracleInsuranceCharges => _oracleInsuranceCharges;
  bool get royalVictoryBountyPending => _royalVictoryBountyPending;

  int _chronoPulseCharges = 0;
  int _mercySalvageCharges = 0;

  int get chronoPulseCharges => _chronoPulseCharges;
  int get mercySalvageCharges => _mercySalvageCharges;

  /// Tutoriels terminés : consommables chrono / clémence actifs en run.
  bool get canForgeRunConsumablesApply => _canUseForgeRunConsumables;

  /// Le rack contient au moins un triple jouable (forme ou couleur).
  bool get slotsHavePlayableTriple =>
      RackLogic.slotsHaveAnyTripleRun(_slotItems);

  /// Chrono bas et au moins une charge : pulse HUD avant sauvetage auto.
  bool get isForgeChronoSalvagePrewarn =>
      _canUseForgeRunConsumables &&
      _chronoPulseCharges > 0 &&
      timeBar.value > 0.0 &&
      timeBar.value <= 0.22;

  /// Rack presque ou plein sans triple jouable : pulse avant clémence auto.
  bool get isForgeMercySalvagePrewarn =>
      _canUseForgeRunConsumables &&
      _mercySalvageCharges > 0 &&
      _slotItems.length >= slotCount - 1 &&
      !RackLogic.slotsHaveAnyTripleRun(_slotItems);

  /// Dernier remboursement assurance sur l’overlay fin de partie (0 si aucun).
  int _lastOracleInsuranceRefundLux = 0;
  int get lastOracleInsuranceRefundLux => _lastOracleInsuranceRefundLux;

  SessionStakeFooterLine _sessionStakeFooterLine = SessionStakeFooterLine.none;
  SessionStakeFooterLine get sessionStakeFooterLine => _sessionStakeFooterLine;

  bool get sessionStakeFooterIsFailure =>
      _sessionStakeFooterLine == SessionStakeFooterLine.highStakesFail ||
      _sessionStakeFooterLine == SessionStakeFooterLine.royalFail;

  /// Partie en cours : mise HIGH STAKES (50 LUX) — utile au HUD / GameView.
  bool get isHighStakesSession => _sessionStake == SessionStakeKind.highStakes;

  /// Partie en cours : mise VELOUR ROYAL (250 LUX).
  bool get isRoyalSession => _sessionStake == SessionStakeKind.royal;

  /// Mise payante (HUD objectif + vignette + feedback tap).
  bool get hasPremiumStakeSession =>
      _sessionStake == SessionStakeKind.highStakes ||
      _sessionStake == SessionStakeKind.royal;

  /// Ante déjà débitée pour la session en cours (0 si casual).
  int get activeSessionAnteLux => switch (_sessionStake) {
    SessionStakeKind.casual => 0,
    SessionStakeKind.highStakes => highStakesAnteLux,
    SessionStakeKind.royal => royalAnteLux,
  };

  static const int highStakesAnteLux = 50;

  /// Boutique Forge — assurance Oracle (rembourse part de la mise si échec premium).
  static const int forgeOracleInsurancePriceLux = 200;
  static const int forgeOracleInsuranceMaxCharges = 3;
  static const int forgeOracleInsuranceRefundPercent = 60;

  /// Prime royale : bonus LUX sur la prochaine **victoire** Royal uniquement.
  static const int forgeRoyalBountyPriceLux = 350;
  static const int forgeRoyalBountyBonusLux = 200;
  static int get highStakesWinLux => SessionStakeConstants.highStakesWinLux;
  static int get highStakesTargetLevel =>
      SessionStakeConstants.highStakesTargetLevel;

  static int get royalAnteLux => SessionStakeConstants.royalAnteLux;
  static int get royalWinLux => SessionStakeConstants.royalWinLux;
  static int get royalTargetLevel => SessionStakeConstants.royalTargetLevel;

  /// Recharge chrono pleine une fois quand le temps atteint zéro (hors tutoriels).
  static const int forgeChronoPulsePriceLux = 175;
  static const int forgeChronoPulseMaxCharges = 2;

  /// Sauvetage impasse : rack plein sans triple — refait apparaître un triplet jouable.
  static const int forgeMercySalvagePriceLux = 220;
  static const int forgeMercySalvageMaxCharges = 2;

  /// Espacement entre cascades (lisibilité vs dynamisme).
  static final Duration cascadeStepDelay = Duration(
    milliseconds: int.fromEnvironment(
      'VELOUR_CASCADE_DELAY_MS',
      defaultValue: 200,
    ).clamp(120, 420),
  );

  void addLuxCoins(
    int delta, {
    required String luxCloudMotif,
    bool recordCloudPending = true,
  }) {
    _economy.addLuxCoins(
      delta,
      luxCloudMotif: luxCloudMotif,
      recordCloudPending: recordCloudPending,
    );
  }

  ({int amount, bool silent}) takePendingLuxJuice() {
    return _economy.takePendingLuxJuice();
  }

  ({int id, String code, String motif})? consumeLuxCloudUnrecoverableNotice() {
    return _economy.consumeLuxCloudUnrecoverableNotice();
  }

  /// True tant que le cadeau de bienvenue n’a pas été accordé (persisté).
  bool get hasPendingWelcomeGift => _economy.hasPendingWelcomeGift;

  bool _welcomeGiftGestureBusy = false;
  int _welcomeGiftVisualBurstId = 0;

  /// Incrémenté après chaque dotation jouée (couche globale UI).
  int get welcomeGiftVisualBurstId => _welcomeGiftVisualBurstId;

  /// Premier lancement : premier clic menu (n’importe quel bouton) — audio + persistance + signal UI.
  Future<void> fireWelcomeGiftFromFirstMenuGestureIfPending() async {
    if (!_economy.hasPendingWelcomeGift) return;
    if (_welcomeGiftGestureBusy) return;
    _welcomeGiftGestureBusy = true;
    try {
      await AudioHandler.instance.unlockAudio();
      if (!_economy.hasPendingWelcomeGift) return;
      AudioHandler.instance.playCredit();
      await _economy.grantWelcomeLuxIfPending();
      _welcomeGiftVisualBurstId++;
      notifyListeners();
    } finally {
      _welcomeGiftGestureBusy = false;
    }
  }

  Future<void> _persistSkinsLocal() async {
    await _localDisk.persistSkinsLocal(
      activeSkinId: _activeSkinId,
      unlockedSkins: _unlockedSkins,
    );
  }

  /// Force une écriture disque immédiate du solde LUX.
  Future<void> flushLuxCoinsPersistence() async {
    await _economy.flushLuxCoinsPersistenceOnly();
  }

  /// Charge l'économie (solde LUX) et détecte le premier lancement.
  /// Ne crédite PAS automatiquement : le menu déclenche le cadeau avec un timing élégant.
  ///
  /// Retourne `true` si un cadeau de bienvenue doit être joué.
  Future<bool> loadEconomyWelcome() async {
    if (_economy.economyLoadedFromDisk) return _economy.hasPendingWelcomeGift;
    try {
      final EconomyWelcomeLoad? disk = await _localDisk.loadEconomyWelcome();
      if (disk == null) return false;
      _economy.hydrateLuxAndWelcomeFromDisk(disk);
      _lastDailyLuxClaimUtcDay = disk.lastDailyLuxClaimUtcDay;
      final Map<String, List<int>> pending = await _localDisk
          .loadPendingLuxByMotifForCloud();
      _economy.hydratePendingLuxByMotifFromDisk(pending);
      _trinityTutorial.hydrateCompleteFromDisk(disk.trinityTutorialComplete);
      // Cohérence : la trinité marquée « faite » implique que la première partie narrative est passée.
      bool firstTime = disk.isFirstTimeGame;
      if (disk.trinityTutorialComplete) {
        firstTime = false;
      }
      _isFirstTimeGame = firstTime;
      _activeSkinId = disk.activeSkinIdRaw ?? SkinCatalog.standard.id;
      _unlockedSkins =
          disk.unlockedSkinsRaw ?? <String>[SkinCatalog.standard.id];
      if (!_unlockedSkins.contains(SkinCatalog.standard.id)) {
        _unlockedSkins = <String>[SkinCatalog.standard.id, ..._unlockedSkins];
      }
      if (!_unlockedSkins.contains(_activeSkinId)) {
        _activeSkinId = SkinCatalog.standard.id;
      }
      await _hydrateForgeShopFromDisk();
      notifyListeners();
      return _economy.hasPendingWelcomeGift;
    } catch (e, st) {
      VelourObservability.recordClientFailure(
        VelourObsCodes.economyLoadWelcomeDisk,
        e,
        st,
      );
      return false;
    }
  }

  Future<void> _hydrateForgeShopFromDisk() async {
    try {
      final ({
        int insuranceCharges,
        bool royalBounty,
        int chronoPulseCharges,
        int mercySalvageCharges,
      })
      r = await _localDisk.loadForgeShop();
      _oracleInsuranceCharges = r.insuranceCharges.clamp(
        0,
        forgeOracleInsuranceMaxCharges,
      );
      _royalVictoryBountyPending = r.royalBounty;
      _chronoPulseCharges = r.chronoPulseCharges.clamp(
        0,
        forgeChronoPulseMaxCharges,
      );
      _mercySalvageCharges = r.mercySalvageCharges.clamp(
        0,
        forgeMercySalvageMaxCharges,
      );
    } catch (e, st) {
      VelourObservability.recordClientFailure(
        VelourObsCodes.forgeShopHydrateDisk,
        e,
        st,
      );
    }
  }

  Future<void> _persistForgeShopPrefs() async {
    await _localDisk.persistForgeShop(
      insuranceCharges: _oracleInsuranceCharges.clamp(
        0,
        forgeOracleInsuranceMaxCharges,
      ),
      royalVictoryBountyPending: _royalVictoryBountyPending,
      chronoPulseCharges: _chronoPulseCharges.clamp(
        0,
        forgeChronoPulseMaxCharges,
      ),
      mercySalvageCharges: _mercySalvageCharges.clamp(
        0,
        forgeMercySalvageMaxCharges,
      ),
    );
  }

  /// Déclenche le cadeau de bienvenue (1 seule fois, persistant).
  Future<void> grantWelcomeLuxIfPending() async {
    await _economy.grantWelcomeLuxIfPending();
  }

  /// Debug : remet l’état « premier lancement » et le solde LUX à 0 (prefs).
  Future<void> debugResetFirstLaunchWelcome() async {
    await _economy.debugResetFirstLaunchWelcome();
    notifyListeners();
  }

  /// Debug : wipe complet (prefs + état mémoire) pour retester tutoriel / économie.
  Future<void> fullHardReset() async {
    await _localDisk.clearAll();

    _economy.resetForFullHardReset();
    _oracleNaming.reset();
    _lastDailyLuxClaimUtcDay = null;
    _unlockedSkins = <String>[SkinCatalog.standard.id];
    _activeSkinId = SkinCatalog.standard.id;
    _oracleInsuranceCharges = 0;
    _royalVictoryBountyPending = false;
    _chronoPulseCharges = 0;
    _mercySalvageCharges = 0;
    _sessionStakeResolveConsumed = false;
    _lastOracleInsuranceRefundLux = 0;

    _trinityTutorial.hardReset();
    _narrativeTutorial.hardReset();
    _isFirstTimeGame = true;
    _guidedTutorialReplayPending = false;
    _narrativeReplayThisRun = false;

    resetGame();
    notifyListeners();
  }

  Future<SkinPurchaseOutcome> purchaseAndEquipSkin(SkinConfig skin) async {
    final String id = skin.id;
    if (_unlockedSkins.contains(id)) {
      if (_activeSkinId == id) {
        return SkinPurchaseOutcome.alreadyEquipped;
      }
      _activeSkinId = id;
      notifyListeners();
      unawaited(_persistSkinsLocal());
      unawaited(FirestoreService.instance.mergeActiveSkinOnly(id));
      return SkinPurchaseOutcome.equippedFromOwned;
    }

    if (skin.price > 0 && _economy.luxCoins < skin.price) {
      return SkinPurchaseOutcome.insufficientLux;
    }
    if (skin.price > 0) {
      addLuxCoins(-skin.price, luxCloudMotif: LuxApplyMotifs.shopSkin);
    }
    _unlockedSkins = <String>[..._unlockedSkins, id];
    _activeSkinId = id;
    notifyListeners();
    unawaited(_persistSkinsLocal());

    unawaited(FirestoreService.instance.mergeSkinPurchaseAndEquip(id));
    return SkinPurchaseOutcome.purchasedAndEquipped;
  }

  Future<ForgePurchaseOutcome> purchaseForgeOracleInsurance() async {
    await loadEconomyWelcome();
    if (_oracleInsuranceCharges >= forgeOracleInsuranceMaxCharges) {
      return ForgePurchaseOutcome.insuranceStackFull;
    }
    if (_economy.luxCoins < forgeOracleInsurancePriceLux) {
      return ForgePurchaseOutcome.insufficientLux;
    }
    addLuxCoins(
      -forgeOracleInsurancePriceLux,
      luxCloudMotif: LuxApplyMotifs.shopForgeConsumable,
    );
    _oracleInsuranceCharges++;
    notifyListeners();
    unawaited(_persistForgeShopPrefs());
    unawaited(_economy.flushLuxCoinsPersistenceOnly());
    return ForgePurchaseOutcome.purchasedInsurance;
  }

  Future<ForgePurchaseOutcome> purchaseForgeRoyalVictoryBounty() async {
    await loadEconomyWelcome();
    if (_royalVictoryBountyPending) {
      return ForgePurchaseOutcome.royalBountyAlreadyActive;
    }
    if (_economy.luxCoins < forgeRoyalBountyPriceLux) {
      return ForgePurchaseOutcome.insufficientLux;
    }
    addLuxCoins(
      -forgeRoyalBountyPriceLux,
      luxCloudMotif: LuxApplyMotifs.shopForgeConsumable,
    );
    _royalVictoryBountyPending = true;
    notifyListeners();
    unawaited(_persistForgeShopPrefs());
    unawaited(_economy.flushLuxCoinsPersistenceOnly());
    return ForgePurchaseOutcome.purchasedRoyalBounty;
  }

  Future<ForgePurchaseOutcome> purchaseForgeChronoPulse() async {
    await loadEconomyWelcome();
    if (_chronoPulseCharges >= forgeChronoPulseMaxCharges) {
      return ForgePurchaseOutcome.chronoPulseStackFull;
    }
    if (_economy.luxCoins < forgeChronoPulsePriceLux) {
      return ForgePurchaseOutcome.insufficientLux;
    }
    addLuxCoins(
      -forgeChronoPulsePriceLux,
      luxCloudMotif: LuxApplyMotifs.shopForgeConsumable,
    );
    _chronoPulseCharges++;
    notifyListeners();
    unawaited(_persistForgeShopPrefs());
    unawaited(_economy.flushLuxCoinsPersistenceOnly());
    return ForgePurchaseOutcome.purchasedChronoPulse;
  }

  Future<ForgePurchaseOutcome> purchaseForgeMercySalvage() async {
    await loadEconomyWelcome();
    if (_mercySalvageCharges >= forgeMercySalvageMaxCharges) {
      return ForgePurchaseOutcome.mercySalvageStackFull;
    }
    if (_economy.luxCoins < forgeMercySalvagePriceLux) {
      return ForgePurchaseOutcome.insufficientLux;
    }
    addLuxCoins(
      -forgeMercySalvagePriceLux,
      luxCloudMotif: LuxApplyMotifs.shopForgeConsumable,
    );
    _mercySalvageCharges++;
    notifyListeners();
    unawaited(_persistForgeShopPrefs());
    unawaited(_economy.flushLuxCoinsPersistenceOnly());
    return ForgePurchaseOutcome.purchasedMercySalvage;
  }

  /// Choix de mise depuis l’écran préparation. Retourne `false` si solde insuffisant (High Stakes).
  bool beginSession(SessionStakeKind kind) {
    if (kind == SessionStakeKind.casual) {
      _sessionStake = SessionStakeKind.casual;
      notifyListeners();
      return true;
    }
    _guidedTutorialReplayPending = false;
    if (kind == SessionStakeKind.highStakes) {
      if (_economy.luxCoins < highStakesAnteLux) {
        VelourAuditLog.event(
          'ftue.premium_blocked_insufficient_lux',
          data: <String, Object?>{
            'stake': 'high_stakes',
            'need': highStakesAnteLux,
            'have': _economy.luxCoins,
          },
        );
        return false;
      }
      VelourAuditLog.event(
        'ftue.premium_stake_start',
        data: <String, Object?>{
          'stake': 'high_stakes',
          'ante': highStakesAnteLux,
          'luxBefore': _economy.luxCoins,
        },
      );
      addLuxCoins(-highStakesAnteLux, luxCloudMotif: LuxApplyMotifs.stakeAnte);
      _sessionStake = SessionStakeKind.highStakes;
      notifyListeners();
      return true;
    }
    if (kind == SessionStakeKind.royal) {
      if (_economy.luxCoins < royalAnteLux) {
        VelourAuditLog.event(
          'ftue.premium_blocked_insufficient_lux',
          data: <String, Object?>{
            'stake': 'royal',
            'need': royalAnteLux,
            'have': _economy.luxCoins,
          },
        );
        return false;
      }
      VelourAuditLog.event(
        'ftue.premium_stake_start',
        data: <String, Object?>{
          'stake': 'royal',
          'ante': royalAnteLux,
          'luxBefore': _economy.luxCoins,
        },
      );
      addLuxCoins(-royalAnteLux, luxCloudMotif: LuxApplyMotifs.stakeAnte);
      _sessionStake = SessionStakeKind.royal;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Prochaine partie **casual** : rejouer le tutoriel narratif (depuis le menu).
  void requestGuidedTutorialReplay() {
    _guidedTutorialReplayPending = true;
    notifyListeners();
  }

  /// Consomme la mise **dès la validation** pré-partie : débit LUX + écriture disque immédiate.
  /// Aucun remboursement à l’abandon menu ; les gains premium sont crédités uniquement par
  /// [_resolveSessionStakeOnGameOver] quand l’objectif de niveau est atteint.
  Future<bool> consumeStake(SessionStakeKind kind) async {
    if (!beginSession(kind)) return false;
    await _economy.flushLuxCoinsPersistenceOnly();
    return true;
  }

  /// Affiche la confirmation de forfait avant abandon menu (session premium).
  /// Retourne `true` si le joueur confirme ; `true` immédiatement s’il n’y a pas d’enjeu.
  Future<bool> showPremiumForfeitAlert(
    BuildContext context,
    int stakeAmount,
  ) async {
    if (!hasPremiumStakeSession) return true;
    final int amount = activeSessionAnteLux;
    if (amount <= 0) return true;
    if (stakeAmount != amount) {
      velourDebug(
        'showPremiumForfeitAlert: stakeAmount=$stakeAmount ignoré, état=$amount',
      );
    }
    final SessionStakeKind kind = _sessionStake;
    final Color accentBorder = kind == SessionStakeKind.royal
        ? const Color(0xFF9D50BB)
        : const Color(0xFFFFD700);
    final Color stakeHighlight = kind == SessionStakeKind.royal
        ? const Color(0xFFE49BFF)
        : const Color(0xFFFFD700);
    return PremiumAlertView.show(
      context,
      stakeKind: kind,
      stakeAmountLux: amount,
      accentBorderColor: accentBorder,
      stakeHighlightColor: stakeHighlight,
    );
  }

  void _resolveSessionStakeOnGameOver() {
    if (_sessionStakeResolveConsumed) {
      return;
    }
    _sessionStakeResolveConsumed = true;

    _lastEndedRunStakeKind = _sessionStake;
    _lastStakeRewardLuxCoins = 0;
    _lastOracleInsuranceRefundLux = 0;

    final SessionStakeResolution r = resolveSessionStakeOnGameOver(
      sessionStake: _sessionStake,
      gameLevel: _gameLevel,
      highStakesTargetLevel: highStakesTargetLevel,
      royalTargetLevel: royalTargetLevel,
      highStakesWinLux: highStakesWinLux,
      royalWinLux: royalWinLux,
    );

    _sessionStakeFooterLine = r.footerLine;
    if (r.rewardLuxCoins > 0) {
      int reward = r.rewardLuxCoins;
      if (_royalVictoryBountyPending &&
          _lastEndedRunStakeKind == SessionStakeKind.royal &&
          r.footerLine == SessionStakeFooterLine.royalWin1250Lux) {
        reward += forgeRoyalBountyBonusLux;
        _royalVictoryBountyPending = false;
        unawaited(_persistForgeShopPrefs());
      }
      VelourAuditLog.event(
        'ftue.premium_stake_reward',
        data: <String, Object?>{
          'stake': _lastEndedRunStakeKind.toString(),
          'reward': reward,
          'level': _gameLevel,
          'footer': r.footerLine.toString(),
        },
      );
      addLuxCoins(reward, luxCloudMotif: LuxApplyMotifs.stakeReward);
      _lastStakeRewardLuxCoins = reward;
    } else if (isPremiumStakeFailure(r.footerLine) &&
        _oracleInsuranceCharges > 0 &&
        (_lastEndedRunStakeKind == SessionStakeKind.highStakes ||
            _lastEndedRunStakeKind == SessionStakeKind.royal)) {
      final int refund = oracleInsuranceRefundLux(
        endedStake: _lastEndedRunStakeKind,
        highStakesAnteLux: highStakesAnteLux,
        royalAnteLux: royalAnteLux,
        refundPercentOfAnte: forgeOracleInsuranceRefundPercent,
      );
      if (refund > 0) {
        VelourAuditLog.event(
          'ftue.premium_oracle_insurance_refund',
          data: <String, Object?>{
            'stake': _lastEndedRunStakeKind.toString(),
            'refund': refund,
            'footer': r.footerLine.toString(),
          },
        );
        addLuxCoins(
          refund,
          luxCloudMotif: LuxApplyMotifs.oracleInsuranceRefund,
        );
        _oracleInsuranceCharges--;
        _lastOracleInsuranceRefundLux = refund;
        unawaited(_persistForgeShopPrefs());
      }
    } else if (isPremiumStakeFailure(r.footerLine)) {
      VelourAuditLog.event(
        'ftue.premium_stake_fail',
        data: <String, Object?>{
          'stake': _lastEndedRunStakeKind.toString(),
          'level': _gameLevel,
          'footer': r.footerLine.toString(),
        },
      );
    }
    _replaySuggestedStake = r.replaySuggestedStake;
    _sessionStake = SessionStakeKind.casual;
  }

  /// Retour menu / abandon : réinitialise l’état de session **sans rembourser** l’ante
  /// (mise déjà consommée à l’entrée en partie).
  void clearSessionStakeForMenu() {
    _sessionStake = SessionStakeKind.casual;
    _sessionStakeFooterLine = SessionStakeFooterLine.none;
    notifyListeners();
  }

  int get highScore => _economy.highScore;
  int _runHighScoreBaseline = 0;
  bool _recordVibrateFired = false;

  Future<void> loadHighScore() async {
    await _economy.loadHighScoreFromDisk();
    if (_runStartedAt == null) {
      _runHighScoreBaseline = _economy.highScore;
    }
  }

  Future<void> _persistHighScoreIfNeeded() async {
    await _economy.commitRunHighScoreIfBetter(_lux);
  }

  /// 0…1 — (LUX actuel − LUX au début du segment) / objectif LUX pour passer au palier suivant.
  double get luxToNextLevelProgress {
    final int need = _luxRequiredForNextLevel();
    final int earnedInSegment = _lux - _luxAtLevelStart;
    if (need <= 0) return 1.0;
    final int into = earnedInSegment.clamp(0, need);
    final double progress = (into / need).clamp(0.0, 1.0);
    if (_lastLuxBarLogLux != _lux) {
      _lastLuxBarLogLux = _lux;
    }
    return progress;
  }

  /// Ratio 0…1 vers le niveau suivant (alias explicite pour le HUD).
  double get scoreProgress => luxToNextLevelProgress;

  int _flightTick = 0;
  int get flightTick => _flightTick;
  FlightFx? _flightFx;
  FlightFx? get flightFx => _flightFx;

  int _floatingTick = 0;
  int get floatingTick => _floatingTick;
  FloatingTextFx? _floatingTextFx;
  FloatingTextFx? get floatingTextFx => _floatingTextFx;

  int _matchParticleTick = 0;
  int get matchParticleTick => _matchParticleTick;
  MatchParticleFx? _matchParticleFx;
  MatchParticleFx? get matchParticleFx => _matchParticleFx;

  /// Incrémenté à chaque étape de cascade (timer match) pour pulse UI.
  int _luxComboFlashTick = 0;
  int get luxComboFlashTick => _luxComboFlashTick;

  List<GameItem> get boardItems => List.unmodifiable(_boardItems);
  List<GameItem> get slotItems => List.unmodifiable(_slotItems);
  Set<String> get removingIds => Set.unmodifiable(_removingIds);
  MatchKind? removalKindFor(String id) => _removalKindById[id];
  int? removalTypeIdFor(String id) => _removalTypeIdById[id];
  int? removalColorIdFor(String id) => _removalColorIdById[id];

  /// Called by the UI once it knows sizes/positions.
  /// Generates the initial items the first time it receives a valid layout.
  void setLayout({
    required Rect playZoneRect,
    required List<Offset> slotTopLefts,
    required Rect luxSafeRect,
    required double boardSpawnMinY,
    required double itemSize,
    required double slotSize,
    required double gridGap,
  }) {
    _playZoneRect = playZoneRect;
    _slotTopLefts = slotTopLefts;
    _luxSafeRect = luxSafeRect;
    _boardSpawnMinY = boardSpawnMinY;
    _itemSize = itemSize;
    _slotSize = slotSize;
    _gridGap = gridGap;

    if (!_initialized) {
      _initialized = true;
      _initBoardItems();
      _startTimeLoop();
      notifyListeners();
    }
  }

  void resetGame() {
    _narrativeReplayThisRun = false;
    _narrativeTutorialReturnToMainMenuTick = 0;
    _narrativeTutorial.hardReset();
    _sessionStakeFooterLine = SessionStakeFooterLine.none;
    _cancelMatchScheduling();
    _stopTimeLoop();
    _matchParticleClearTimer?.cancel();
    _matchParticleClearTimer = null;
    _comboFloaterClearTimer?.cancel();
    _comboFloaterClearTimer = null;
    timeBar.value = 1.0;
    _criticalFailure = false;
    _runStartedAt = null;
    _shapesPlacedThisRun = 0;
    _matchesResolvedThisRun = 0;

    _boardItems.clear();
    _slotItems.clear();
    _slotSeqById.clear();
    _slotInsertSeq = 0;

    _removingIds.clear();
    _removalKindById.clear();
    _removalTypeIdById.clear();
    _removalColorIdById.clear();

    _flightFx = null;
    _floatingTextFx = null;
    // Force UI to drop any in-flight overlays instantly (trail / floating text).
    _flightTick++;
    _floatingTick++;
    _matchParticleFx = null;
    _matchParticleTick++;

    _awaitingScheduledMatch = false;
    _isProcessingMatch = false;
    _deferredTimerGameOver = false;

    _isGameOver = false;
    _sessionStakeResolveConsumed = false;
    _lastOracleInsuranceRefundLux = 0;
    _lux = 0;
    _runMatchLuxRawTotal = 0;
    _lastGameWasPersonalBest = false;
    _runHighScoreBaseline = _economy.highScore;
    _recordVibrateFired = false;
    _lastStakeRewardLuxCoins = 0;
    _lastEndedRunStakeKind = SessionStakeKind.casual;
    _replaySuggestedStake = null;
    _gameLevel = 1;
    _luxAtLevelStart = 0;
    _resetLevelTransitionState();
    _sequenceTick = 0;
    _luxComboFlashTick = 0;
    _comboFloater = null;
    _comboFloaterTick = 0;
    _levelUpFlashTick = 0;
    _lastLuxBarLogLux = null;
    _gameOverFlashTick = 0;

    _lastPlayerActionAt = DateTime.now();
    _lastMatchPerfSampleAt = null;
    _perfEmaLuxPerMinute = MetaProgressionPolicy.neutralLuxPerMinute;

    if (_heatReboundPendingFromTimerDeath) {
      _heatReboundPendingFromTimerDeath = false;
      _heatReboundAvailable = true;
      _heatTier = 0;
      _heatConsecutivePerfects = 0;
      _heatRescueConsumedTiers.clear();
      _heatFreezeEnd = null;
      _perfectHeatUiTick++;
    } else {
      _initPerfectHeatForFreshReset();
    }

    _initBoardItems();
    // Ne pas relancer le chrono ici : hors [GameScreen] (menu, splash) ça ferait
    // tourner [Timer.periodic] 50 ms inutilement. Le timer repart via [startGame]
    // / premier [setLayout] sur l’écran jeu.
    notifyListeners();
  }

  void startNewRun() {
    resetGame();
  }

  /// Called by the game screen to guarantee the timer is running once rendered.
  void startGame() {
    if (_criticalFailure) return;
    if (_timeTimer == null) {
      _startTimeLoop();
    }
    _runStartedAt ??= DateTime.now();
    _lastPlayerActionAt = DateTime.now();
    _runHighScoreBaseline = _economy.highScore;
    // If layout is already known but board hasn't been seeded (e.g. reset before layout),
    // seed now.
    if ((_playZoneRect != null && !(_playZoneRect?.isEmpty ?? true)) &&
        _boardItems.isEmpty &&
        _slotItems.isEmpty) {
      _initBoardItems();
      notifyListeners();
    }
  }

  String _nextId() => '${DateTime.now().microsecondsSinceEpoch}_${_idSeq++}';

  void _initBoardItems() {
    final Rect? zone = _playZoneRect;
    if (zone == null || zone.isEmpty) return;

    // Clean init: reset all collections before seeding test items.
    _cancelMatchScheduling();
    _matchParticleClearTimer?.cancel();
    _matchParticleClearTimer = null;
    _comboFloaterClearTimer?.cancel();
    _comboFloaterClearTimer = null;
    _boardItems.clear();
    _slotItems.clear();
    _slotSeqById.clear();
    _slotInsertSeq = 0;
    _removingIds.clear();
    _removalKindById.clear();
    _removalTypeIdById.clear();
    _removalColorIdById.clear();
    _isGameOver = false;
    _criticalFailure = false;
    _runHighScoreBaseline = _economy.highScore;
    _recordVibrateFired = false;
    _sequenceTick = 0;
    _luxComboFlashTick = 0;
    _comboFloater = null;
    _comboFloaterTick = 0;
    _gameOverFlashTick = 0;
    _flightFx = null;
    _floatingTextFx = null;
    _flightTick++;
    _floatingTick++;
    _matchParticleFx = null;
    _matchParticleTick++;
    _resetLevelTransitionState();

    final bool narrativeFromMenuThisInit =
        _guidedTutorialReplayPending &&
        _sessionStake == SessionStakeKind.casual;
    if (narrativeFromMenuThisInit) {
      _guidedTutorialReplayPending = false;
      _narrativeReplayThisRun = true;
      _trinityTutorial.clearForNarrativeFirstRun();
      _narrativeTutorial.beginCasualFirstRunBoardInit();
      timeBar.value = 0.0;
      _lux = 0;
      _seedNarrativeStep1Board();
    } else {
      _guidedTutorialReplayPending = false;
      _narrativeReplayThisRun = false;
      _trinityTutorial.clearForInactiveBoardInit();
      _fillBoardToCap();
    }
  }

  Future<void> _persistTrinityTutorialDone() async {
    await _localDisk.persistTrinityTutorialComplete();
  }

  void _prepareNarrativeTutorialBoardShell() {
    _boardItems.clear();
    _slotItems.clear();
    _slotSeqById.clear();
    _slotInsertSeq = 0;
    _narrativeTutorial.beginNarrativeStepSeeding();
  }

  Offset _narrativeGemTopLeft(int slotIndex) =>
      _tutorialBoardSlotCenter(slotIndex) -
      Offset(itemSize * 0.5, itemSize * 0.5);

  void _seedNarrativeStep1Board() {
    _prepareNarrativeTutorialBoardShell();
    TutorialBoardPlacer.placeNarrativeStep1Gems(
      board: _boardItems,
      onNarrativeTapId: _narrativeTutorial.addTapId,
      nextId: _nextId,
      topLeftForSlot: _narrativeGemTopLeft,
    );
  }

  void _seedNarrativeStep2Board() {
    _prepareNarrativeTutorialBoardShell();
    TutorialBoardPlacer.placeNarrativeStep2Gems(
      board: _boardItems,
      onNarrativeTapId: _narrativeTutorial.addTapId,
      nextId: _nextId,
      topLeftForSlot: _narrativeGemTopLeft,
    );
  }

  void _seedNarrativeStep3Board() {
    _prepareNarrativeTutorialBoardShell();
    TutorialBoardPlacer.placeNarrativeStep3Gems(
      board: _boardItems,
      onNarrativeTapId: _narrativeTutorial.addTapId,
      nextId: _nextId,
      topLeftForSlot: _narrativeGemTopLeft,
    );
  }

  void _narrativeExplosionShake() {
    _shakeTick++;
    _shakeStrength = 15;
  }

  Future<void> _persistNarrativeTutorialComplete() async {
    _isFirstTimeGame = false;
    _narrativeReplayThisRun = false;
    _guidedTutorialReplayPending = false;
    _trinityTutorial.markCompleteFromNarrative();
    await _localDisk.persistNarrativeTutorialComplete();
    // Respiration après la bannière, puis retour menu (le tutoriel n’est pas une run « à poursuivre »).
    await Future<void>.delayed(const Duration(milliseconds: 700));
    _narrativeTutorial.bumpPostSpawnFade();
    _narrativeTutorialReturnToMainMenuTick++;
    notifyListeners();
  }

  Offset _tutorialBoardSlotCenter(int index) {
    final Rect sb = _boardSpawnRect();
    if (sb.isEmpty) {
      final Rect? pz = _playZoneRect;
      return pz != null ? pz.center : Offset.zero;
    }
    final int col = 1 + index;
    final int row = 1;
    return _topLeftForCell(col, row) + Offset(itemSize * 0.5, itemSize * 0.5);
  }

  void _seedTrinityBoardForCurrentPhase() {
    _boardItems.clear();
    TutorialBoardPlacer.placeTrinityGemsForPhase(
      phase: _trinityTutorial.phase,
      board: _boardItems,
      nextId: _nextId,
      topLeftForSlot: _narrativeGemTopLeft,
    );
  }

  void _clearSlotsAndBoardForTrinityStep() {
    _slotItems.clear();
    _slotSeqById.clear();
    _slotInsertSeq = 0;
    _boardItems.clear();
  }

  bool _tryConsumeChronoPulseRefill() {
    if (!_canUseForgeRunConsumables) return false;
    if (_chronoPulseCharges <= 0) return false;
    _chronoPulseCharges--;
    timeBar.value = 1.0;
    unawaited(_persistForgeShopPrefs());
    AudioHandler.instance.playCredit();
    HapticsHandler.instance.mediumImpact();
    notifyListeners();
    return true;
  }

  bool _tryOracleMercySalvageFromDeadlock() {
    if (!_canUseForgeRunConsumables) return false;
    if (_mercySalvageCharges <= 0) return false;
    if (_slotItems.length != slotCount) return false;

    _mercySalvageCharges--;
    _applyMercySalvageReplaceLastTriple();
    unawaited(_persistForgeShopPrefs());
    return true;
  }

  void _applyMercySalvageReplaceLastTriple() {
    final GameItem anchor = _slotItems.first;
    final int n = _slotItems.length;
    for (int i = n - 3; i < n; i++) {
      final GameItem old = _slotItems[i];
      _slotItems[i] = GameItem(
        id: _nextId(),
        typeId: anchor.typeId,
        colorId: anchor.colorId,
        position: old.position,
        isSelected: false,
        floatPeriodMs: old.floatPeriodMs,
        floatPhase: old.floatPhase,
      );
    }
    _assignSlotPositions(selectedId: '');
  }

  void _startTimeLoop() {
    _timeTimer?.cancel();
    _lastTimeTickAt = DateTime.now();
    _timeTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (_criticalFailure) return;
      if (_paused) return;
      if (isTrinityTutorialChronoFrozen || isNarrativeTutorialChronoFrozen) {
        return;
      }
      final DateTime now = DateTime.now();
      final DateTime last = _lastTimeTickAt ?? now;
      _lastTimeTickAt = now;
      final double dt = now.difference(last).inMilliseconds / 1000.0;
      if (dt <= 0) return;

      if (perfectHeatFreezeActive) {
        return;
      }
      final double clutch = TimerTensionLogic.drainMultiplierForBarFraction(
        timeBar.value,
      );
      final Duration idleDt = now.difference(_lastPlayerActionAt ?? now);
      final double hurry = TimerTensionLogic.idleHurryMultiplier(
        sinceLastPlayerAction: idleDt,
      );
      final double effectiveDrain = _timeDrainPerSecond * clutch * hurry;
      final double next = RunTimerLogic.nextTimeBarAfterTick(
        currentValue: timeBar.value,
        timeDrainPerSecond: effectiveDrain,
        dtSeconds: dt,
      );
      if (next <= 0.0) {
        if (_isProcessingMatch || _awaitingScheduledMatch) {
          timeBar.value = 0.0;
          _deferredTimerGameOver = true;
          velourDebug(
            '[Velour][Timer] chrono à zéro pendant pipeline match — gameOver différé',
          );
          notifyListeners();
          return;
        }
        timeBar.value = next;
        if (_tryConsumeChronoPulseRefill()) {
          return;
        }
        gameOver();
        return;
      }
      timeBar.value = next;

      // Filet : si le verrou pipeline a été relâché sans flush (race rare), exécuter le game over différé.
      if (_deferredTimerGameOver &&
          !_paused &&
          !_criticalFailure &&
          !_isProcessingMatch &&
          !_awaitingScheduledMatch &&
          timeBar.value <= 0.0) {
        _tryFlushDeferredTimerGameOver();
      }
    });
  }

  void _stopTimeLoop() {
    _timeTimer?.cancel();
    _timeTimer = null;
    _lastTimeTickAt = null;
  }

  /// Stats carrière : une seule fois par run ([_runStartedAt] consommé → null).
  Future<void> _recordRunStatsIfNeeded() async {
    final DateTime? started = _runStartedAt;
    if (started == null) return;
    _runStartedAt = null;
    final Duration playTime = DateTime.now().difference(started);
    await StatsService.instance.recordGame(
      scoreLux: _lux,
      luxGained: _lux,
      levelReached: _gameLevel,
      shapes: _shapesPlacedThisRun,
      matches: _matchesResolvedThisRun,
      playTime: playTime,
      stake: _sessionStake,
    );
  }

  void gameOver() {
    if (_criticalFailure) return;
    if (_isProcessingMatch || _awaitingScheduledMatch) {
      _deferredTimerGameOver = true;
      velourDebug(
        '[Velour][GameOver] appel ignoré (match en cours / check armé) — différé',
      );
      notifyListeners();
      return;
    }
    _deferredTimerGameOver = false;
    _isGameOver = true;
    _criticalFailure = true;
    _resetLevelTransitionState();
    _breakPerfectHeatTimerGameOverInternal();
    _cancelMatchScheduling();
    _stopTimeLoop();
    try {
      unawaited(_recordRunStatsIfNeeded());
      _resolveSessionStakeOnGameOver();
      _lastGameWasPersonalBest = _lux > _economy.highScore;
      _persistHighScoreIfNeeded();
      _playGameOverSound();
      AudioHandler.instance.cutAllAudio();
      _gameOverFlashTick++;
    } finally {
      notifyListeners();
    }
  }

  int get _targetBoardCap => BoardConfig.boardCapForLevel(
    _gameLevel,
    heatTierClamp0to5: perfectHeatMechanicsActive ? _heatTier.clamp(0, 5) : 0,
  );

  void _fillBoardToCap() {
    if (isTrinityTutorialChronoFrozen || isNarrativeTutorialChronoFrozen) {
      return;
    }
    final int cap = math.max(BoardConfig.absoluteMinBoardGems, _targetBoardCap);
    final int missing = cap - _boardItems.length;
    if (missing <= 0) return;
    _spawnBoardItems(missing);
  }

  void _spawnBoardItems(int count) {
    if (isTrinityTutorialChronoFrozen || isNarrativeTutorialChronoFrozen) {
      return;
    }
    final Rect? zone = _playZoneRect;
    if (zone == null || zone.isEmpty) return;

    // V1 stability: initial board must not contain an immediate “free” match-3 set.
    // We approximate this by preventing 3+ of the same type on the very first seed.
    final bool isInitialSeed = _boardItems.isEmpty && _slotItems.isEmpty;
    final Map<int, int> shapeCounts = <int, int>{};
    final Map<int, int> colorCounts = <int, int>{};

    for (int i = 0; i < count; i++) {
      final String id = _nextId();
      final int maxShapeId = numberOfGemTypes;
      final int typeId;
      final int colorId;

      if (isInitialSeed) {
        final ({int typeId, int colorId}) rolled =
            BoardSpawnLogic.rollInitialSeedGem(
              maxShapeId: maxShapeId,
              shapeCounts: shapeCounts,
              colorCounts: colorCounts,
              rng: _rng,
              nextColorId: _pickColorId,
            );
        typeId = rolled.typeId;
        colorId = rolled.colorId;
      } else {
        final int heatClamp = perfectHeatMechanicsActive
            ? _heatTier.clamp(0, 5)
            : 0;
        final int t0 = BoardFlowPolicy.useUnderrepresentedShapePick(heatClamp)
            ? BoardSpawnLogic.pickWeightedTypeId(
                maxShapeId: maxShapeId,
                typePopulationCounts: BoardSpawnLogic.mergeShapeCounts(
                  _boardItems,
                  _slotItems,
                ),
                rng: _rng,
              )
            : 1 + _rng.nextInt(maxShapeId);
        final int c0 = _pickColorId();
        final bool spawnBiasActive = _gameLevel > 1 && timeBar.value < 0.8;
        final double biasChance = BoardFlowPolicy.slotCompletionBiasChance(
          heatTierClamp0to5: heatClamp,
          timeBarFraction: timeBar.value,
        );
        final ({int typeId, int colorId}) biased =
            BoardSpawnLogic.maybeApplySlotCompletionBias(
              typeId: t0,
              colorId: c0,
              biasMayApply: spawnBiasActive,
              roll01: _rng.nextDouble(),
              pair: RackLogic.slotPairNeedingThirdCopy(_slotItems),
              biasChance: biasChance,
            );
        if (biased.typeId != t0 || biased.colorId != c0) {
          velourDebug(
            '[Velour][Spawn] biais complétion 30% → type=${biased.typeId} color=${biased.colorId}',
          );
        }
        typeId = biased.typeId;
        colorId = BoardSpawnLogic.clampTriangleColor(typeId, biased.colorId);
      }
      final Offset pos = _findNonOverlappingGridTopLeft();
      _boardItems.add(
        GameItem(
          id: id,
          typeId: typeId,
          colorId: colorId,
          position: pos,
          floatPeriodMs: 1500 + _rng.nextInt(1301), // 1500..2800
          floatPhase: _rng.nextDouble(),
        ),
      );
    }
  }

  int _pickColorId() {
    return BoardSpawnLogic.pickWeightedColorId(
      maxColorId: numberOfGemTypes,
      gameLevel: _gameLevel,
      colorPopulationCounts: BoardSpawnLogic.mergeColorCounts(
        _boardItems,
        _slotItems,
      ),
      rng: _rng,
    );
  }

  double get _cellPitch => BoardLayoutLogic.cellPitch(itemSize, _gridGap);

  Rect _boardSpawnRect() {
    final Rect? pz = _playZoneRect;
    if (pz == null || pz.isEmpty) return Rect.zero;
    return BoardLayoutLogic.boardSpawnRect(
      playZone: pz,
      boardSpawnMinY: _boardSpawnMinY,
      itemSize: itemSize,
    );
  }

  Offset _topLeftForCell(int col, int row) {
    return BoardLayoutLogic.topLeftForCell(
      _boardSpawnRect(),
      _cellPitch,
      col,
      row,
    );
  }

  Offset _findNonOverlappingGridTopLeft() {
    return BoardLayoutLogic.findNonOverlappingGridTopLeft(
      playZone: _playZoneRect,
      luxSafeRect: _luxSafeRect,
      boardSpawnMinY: _boardSpawnMinY,
      itemSize: itemSize,
      gridGap: _gridGap,
      boardGemTopLefts: _boardItems.map((GameItem e) => e.position).toList(),
      rng: _rng,
    );
  }

  void _insertIncomingSlotItem(GameItem incoming) {
    final int insertIndex = RackLogic.computeStrategicSlotInsertIndex(
      incoming,
      _slotItems,
    );
    _slotItems.insert(insertIndex, incoming);
    _assignSlotPositions(selectedId: incoming.id);
  }

  void _assignSlotPositions({required String selectedId}) {
    for (int i = 0; i < _slotItems.length; i++) {
      final GameItem e = _slotItems[i];
      final Offset slotTopLeft = _slotTopLefts[i];
      final double dx = slotTopLeft.dx + (slotSize - itemSize) / 2;
      final double dy = slotTopLeft.dy + (slotSize - itemSize) / 2;
      _slotItems[i] = GameItem(
        id: e.id,
        typeId: e.typeId,
        colorId: e.colorId,
        position: Offset(dx, dy),
        isSelected: selectedId.isNotEmpty && e.id == selectedId,
        floatPeriodMs: e.floatPeriodMs,
        floatPhase: e.floatPhase,
      );
    }
    _recomputeAlerts();
    _recomputeImminentPairs();
  }

  Future<void> selectItem(String id) async {
    if (_criticalFailure) return;
    if (_isGameOver) return;
    if (_isProcessingMatch) {
      velourDebug(
        '[Velour][selectItem] ignoré pendant résolution match (id=$id)',
      );
      return;
    }
    if (_paused) return;
    if (_slotItems.length >= slotCount) return;
    if (_slotTopLefts.length < slotCount) return;

    final int idx = _boardItems.indexWhere((e) => e.id == id);
    if (idx == -1) return;

    if (!_narrativeTutorial.shouldAcceptBoardSelect(id)) {
      return;
    }

    _lastPlayerActionAt = DateTime.now();

    final GameItem item = _boardItems[idx];
    if (_isNarrativeTutorialCoreSteps) {
      _narrativeTutorial.onBoardGemSelectedDuringTutorial(
        itemTopLeft: item.position,
        colorId: item.colorId,
        itemSize: itemSize,
        nextId: _nextId,
      );
    }
    _boardItems.removeAt(idx);
    _shapesPlacedThisRun++;
    final Offset from = item.position;
    _slotSeqById[item.id] ??= _slotInsertSeq++;
    velourDebug(
      '[Velour][selectItem] nouvelle sélection manuelle — chaîne cascade repart à zéro (id=${item.id})',
    );

    final GameItem incomingSlot = GameItem(
      id: item.id,
      typeId: item.typeId,
      colorId: item.colorId,
      position: item.position,
      isSelected: true,
      floatPeriodMs: item.floatPeriodMs,
      floatPhase: item.floatPhase,
    );
    _insertIncomingSlotItem(incomingSlot);
    final Offset to = _slotItems.firstWhere((e) => e.id == item.id).position;
    _flightFx = FlightFx(
      id: item.id,
      from: from,
      to: to,
      typeId: item.typeId,
      colorId: item.colorId,
    );
    _flightTick++;

    _scheduleMatchCheck();
    _reevaluateDeadlock();

    // Non-stop action: spawn 1 immédiatement (désactivé pendant tutoriels).
    if (!isTrinityTutorialChronoFrozen && !isNarrativeTutorialChronoFrozen) {
      _spawnBoardItems(1);
      _fillBoardToCap();
    }

    if (_isNarrativeTutorialCoreSteps) {
      _narrativeTutorial.incrementTapProgress();
    }

    _recomputeAlerts();
    _recomputeImminentPairs();

    notifyListeners();
  }

  void _cancelMatchScheduling() {
    _matchTimer?.cancel();
    _matchTimer = null;
    _matchPipelineGeneration++;
    _awaitingScheduledMatch = false;
    _tryFlushDeferredTimerGameOver();
  }

  void _tryFlushDeferredTimerGameOver() {
    if (!_deferredTimerGameOver) return;
    if (_paused) return;
    if (_criticalFailure) {
      _deferredTimerGameOver = false;
      notifyListeners();
      return;
    }
    if (_isProcessingMatch || _awaitingScheduledMatch) return;

    _deferredTimerGameOver = false;
    if (timeBar.value > 0.0) {
      velourDebug(
        '[Velour][Timer] gameOver différé annulé (temps > 0 après résolution)',
      );
      notifyListeners();
      return;
    }
    if (_tryConsumeChronoPulseRefill()) {
      return;
    }
    velourDebug('[Velour][Timer] exécution gameOver après fin pipeline match');
    gameOver();
  }

  void _scheduleMatchCheck() {
    if (_criticalFailure) return;
    _matchTimer?.cancel();
    _matchTimer = null;
    _matchPipelineGeneration++;
    final int pipelineToken = _matchPipelineGeneration;
    _awaitingScheduledMatch = true;

    _matchTimer = Timer(_effectiveMatchDelay, () async {
      bool pipelineStale() => pipelineToken != _matchPipelineGeneration;

      try {
        if (pipelineStale()) return;
        final RackRun? initial = RackLogic.findBestRun(_slotItems);
        if (initial == null) {
          _recomputeAlerts();
          _reevaluateDeadlock();
          notifyListeners();
          return;
        }

        int chainStep = 0;
        RackRun? run = initial;
        while (run != null && chainStep < 40) {
          if (pipelineStale()) return;
          chainStep++;
          final bool isCascade = chainStep > 1;
          final double chainMult = RackLogic.chainScoreMultiplier(chainStep);
          if (isCascade) {
            _luxComboFlashTick++;
            velourDebug(
              '[Velour][Cascade] étape $chainStep — mult score ×$chainMult',
            );
          }
          _triggerShake(run.count);
          velourDebug(
            '[Velour][Match] résolution démarrée step=$chainStep '
            'kind=${run.kind} count=${run.count} cascade=$isCascade',
          );
          _isProcessingMatch = true;
          final bool closedTrinityTutorial;
          try {
            closedTrinityTutorial = await _removeMatchedGroupOnce(
              run.start,
              run.endExclusive,
              run.kind,
              run.basis,
              run.count,
              chainScoreMult: chainMult,
              isCascade: isCascade,
            );
          } finally {
            // Relâche le verrou dès la mutation d'état terminée (input "snappy").
            _isProcessingMatch = false;
          }
          if (pipelineStale()) return;
          velourDebug('[Velour][Match] résolution terminée step=$chainStep');
          // Petit espacement (réduit ~30%) : laisse lire le feedback sans bloquer l'input.
          await Future<void>.delayed(cascadeStepDelay);
          if (pipelineStale()) return;
          run = (isTrinityTutorialActive || closedTrinityTutorial)
              ? null
              : RackLogic.findBestRun(_slotItems);
        }
        if (run != null) {
          velourDebug(
            '[Velour][Cascade] garde-fou 40 résolutions — match encore détecté, arrêt',
          );
        }
      } finally {
        if (pipelineToken == _matchPipelineGeneration) {
          _awaitingScheduledMatch = false;
          _tryFlushDeferredTimerGameOver();
        }
      }
    });
  }

  /// Retourne `true` si le tutoriel trinité vient de se terminer (évite une cascade
  /// immédiate sur le plateau aléatoire tout juste rempli).
  Future<bool> _removeMatchedGroupOnce(
    int runStart,
    int runEndExclusive,
    MatchKind kind,
    RunBasis basis,
    int runCount, {
    required double chainScoreMult,
    required bool isCascade,
  }) async {
    final List<GameItem> matched = _slotItems.sublist(
      runStart,
      runEndExclusive,
    );
    final int typeId = matched.first.typeId;
    final Offset center =
        matched
            .map((e) => e.position)
            .fold(const Offset(0, 0), (a, b) => a + b) /
        matched.length.toDouble();

    for (final item in matched) {
      _removingIds.add(item.id);
      _removalKindById[item.id] = kind;
      _removalTypeIdById[item.id] = item.typeId;
      _removalColorIdById[item.id] = item.colorId;
    }
    _isGameOver = false;
    _criticalFailure = false;
    notifyListeners();

    final Duration anim = switch (kind) {
      MatchKind.normal => const Duration(milliseconds: 260),
      MatchKind.boosted => const Duration(milliseconds: 180),
      MatchKind.overcharge => const Duration(milliseconds: 220),
      MatchKind.perfect => const Duration(milliseconds: 260),
    };
    await Future<void>.delayed(anim);
    _matchesResolvedThisRun++;
    final bool narrativePerfectForBanner =
        _narrativeRunEngaged &&
        _narrativeTutorial.isStep3Perfect &&
        basis == RunBasis.perfect;
    MatchFeedback.emit(
      kind: kind,
      basis: basis,
      narrativePerfectForBanner: narrativePerfectForBanner,
    );

    final int rawGain = MatchScoring.rawLuxGain(basis, runCount);
    final double timeSnapshotBeforeMatchRefund = timeBar.value;
    final int? heatBonusTier =
        (basis == RunBasis.perfect && perfectHeatMechanicsActive)
        ? _heatBonusTierForPerfect()
        : null;
    final int scoringRaw = heatBonusTier != null
        ? PerfectHeatLogic.applyLuxPercentBonus(rawGain, heatBonusTier)
        : rawGain;
    _runMatchLuxRawTotal += scoringRaw;
    final int levelBeforeGain = _gameLevel;
    final double scoreMult = MatchScoring.sessionScoreMultiplier(
      _sessionStake,
      levelBeforeGain,
      highStakesTargetLevel: highStakesTargetLevel,
      royalTargetLevel: royalTargetLevel,
    );
    final int gain = MatchScoring.roundChainedLux(
      scoringRaw,
      scoreMult,
      chainScoreMult,
    );
    _lux += gain;

    if (_canUseForgeRunConsumables) {
      final DateTime perfT = DateTime.now();
      if (_lastMatchPerfSampleAt != null) {
        final double gapMin =
            perfT.difference(_lastMatchPerfSampleAt!).inMilliseconds / 60000.0;
        if (gapMin > 1e-5) {
          final double sample = (gain / gapMin).clamp(0.0, 14000.0);
          _perfEmaLuxPerMinute = MetaProgressionPolicy.emaLuxPerMinute(
            previousEma: _perfEmaLuxPerMinute,
            sampleLuxPerMinute: sample,
          );
        }
      }
      _lastMatchPerfSampleAt = perfT;
    }

    // Nouveau record en direct (une seule fois par run).
    if (!_recordVibrateFired &&
        _economy.highScoreLoaded &&
        _runHighScoreBaseline > 0 &&
        _lux > _runHighScoreBaseline) {
      _recordVibrateFired = true;
      try {
        if (HapticsHandler.instance.enabled.value) {
          HapticFeedback.vibrate();
        }
      } catch (_) {}
    }
    _maybeAdvanceLevel();
    if (isTrinityTutorialChronoFrozen) {
      timeBar.value = 1.0;
    } else if (_narrativeTutorial.isCoreSteps) {
      // Temps : paliers gérés dans [NarrativeTutorialService.applyAfterMatch].
    } else {
      timeBar.value = (timeBar.value + _matchTimeRefund).clamp(0.0, 1.0);
    }

    if (heatBonusTier != null) {
      _applyHeatPerfectTimeEffects(
        heatBonusTier,
        timeSnapshotBeforeMatchRefund,
      );
      if (heatBonusTier == 5) {
        _heatGhostFlashTick++;
        try {
          if (HapticsHandler.instance.enabled.value) {
            HapticFeedback.mediumImpact();
          }
        } catch (_) {}
      }
      _advanceHeatAfterPerfect();
    } else if (perfectHeatMechanicsActive && basis != RunBasis.perfect) {
      _applyHeatDecayNonPerfect(kind, basis, runCount);
    }

    // "Sequence Completed" est réservé au tutoriel (trinité).

    final String luxLabel = switch ((basis == RunBasis.perfect, isCascade)) {
      (true, true) => '+$gain PERFECT ×${chainScoreMult.toStringAsFixed(1)}',
      (true, false) => '+$gain PERFECT',
      (false, true) => '+$gain LUX ×${chainScoreMult.toStringAsFixed(1)}',
      (false, false) => '+$gain LUX',
    };
    final NarrativeFloatingKey? narrativeFloatKey = _narrativeTutorial
        .floatingKeyForMatch(basis);
    final RuntimeLuxFloatKind? runtimeLuxKind = narrativeFloatKey != null
        ? null
        : switch ((basis == RunBasis.perfect, isCascade)) {
            (true, true) => RuntimeLuxFloatKind.perfectGainMult,
            (true, false) => RuntimeLuxFloatKind.perfectGain,
            (false, true) => RuntimeLuxFloatKind.luxGainMult,
            (false, false) => RuntimeLuxFloatKind.luxGain,
          };
    final String? runtimeChainMult =
        (runtimeLuxKind == RuntimeLuxFloatKind.perfectGainMult ||
            runtimeLuxKind == RuntimeLuxFloatKind.luxGainMult)
        ? chainScoreMult.toStringAsFixed(1)
        : null;

    if (isCascade) {
      _comboFloater = ComboFloaterFx(
        id: _nextId(),
        position: center + Offset(0, -itemSize * 0.85),
        chainMult: chainScoreMult,
      );
      _comboFloaterTick++;
      _comboFloaterClearTimer?.cancel();
      _comboFloaterClearTimer = Timer(const Duration(milliseconds: 420), () {
        _comboFloater = null;
        _comboFloaterTick++;
        notifyListeners();
      });
    }

    final bool narrativePerfectFloat =
        _narrativeRunEngaged &&
        _narrativeTutorial.isStep3Perfect &&
        basis == RunBasis.perfect;
    final bool perfectHeatNear =
        perfectHeatMechanicsActive &&
        PerfectHeatLogic.isNearMiss(kind, basis, runCount);
    // Parfait narratif : la bannière centrale porte le message — pas de floater
    // (évite triple +500 et laisse disparaître l’ancien +150 au même tick).
    if (narrativePerfectFloat) {
      _floatingTextFx = null;
      _floatingTick++;
    } else {
      _floatingTextFx = FloatingTextFx(
        id: _nextId(),
        text: luxLabel,
        position: center,
        typeId: typeId,
        colorId: (basis == RunBasis.perfect) ? 0 : 1,
        isNarrativePerfectBurst: false,
        narrativeFloatKey: narrativeFloatKey,
        runtimeLuxKind: runtimeLuxKind,
        runtimeGain: runtimeLuxKind != null ? gain : null,
        runtimeChainMult: runtimeChainMult,
        textColorOverride: perfectHeatNear ? const Color(0xFFFFB74D) : null,
        appendPerfectHeatNear: perfectHeatNear,
      );
      _floatingTick++;
    }
    final bool perfectBurst = basis == RunBasis.perfect;
    final int dominantColorId = matched.first.colorId;
    final int dustCount = perfectBurst ? 24 : 12;
    _matchParticleFx = MatchParticleFx(
      id: _nextId(),
      center: center + Offset(itemSize * 0.5, itemSize * 0.5),
      typeId: matched.first.typeId,
      colorId: dominantColorId,
      particleCount: dustCount,
      perfectLuxBurst: perfectBurst,
    );
    _matchParticleTick++;
    _matchParticleClearTimer?.cancel();
    _matchParticleClearTimer = Timer(
      perfectBurst
          ? const Duration(milliseconds: 360)
          : const Duration(milliseconds: 260),
      () {
        _matchParticleFx = null;
        _matchParticleTick++;
        notifyListeners();
      },
    );

    _slotItems.removeWhere((e) => _removingIds.contains(e.id));
    for (final item in matched) {
      _removingIds.remove(item.id);
      _removalKindById.remove(item.id);
      _removalTypeIdById.remove(item.id);
      _removalColorIdById.remove(item.id);
    }

    // Overcharge bonus: keep legacy “wipe” but based on COLOR (more tactical).
    if (kind == MatchKind.overcharge) {
      final int c = matched.first.colorId;
      _boardItems.removeWhere((e) => e.colorId == c);
    }

    // Perfect match : gros LUX / FX ; le plateau reste (meilleure continuité tactique).

    bool closedTrinityTutorial = false;
    final TrinityTutorialPhase phaseBefore = _trinityTutorial.phase;
    if (isTrinityTutorialChronoFrozen) {
      _trinityTutorial.advanceAfterMatch(
        basis,
        persistTrinityTutorialComplete: _persistTrinityTutorialDone,
        onClearSlotsAndBoard: _clearSlotsAndBoardForTrinityStep,
        onReseedTrinityBoard: _seedTrinityBoardForCurrentPhase,
        onFillBoardToCap: _fillBoardToCap,
      );
      closedTrinityTutorial =
          phaseBefore == TrinityTutorialPhase.perfect &&
          _trinityTutorial.phase == TrinityTutorialPhase.none;
    } else if (_narrativeTutorial.isCoreSteps) {
      _narrativeTutorial.applyAfterMatch(
        _narrativeRunEngaged,
        basis,
        _baseMatchTimeRefund,
      );
    } else if (_narrativeTutorial.phase != NarrativeTutorialPhase.celebration) {
      _fillBoardToCap();
    }

    // Positions des slots (ordre inchangé après retrait).
    if (_slotItems.isNotEmpty) {
      _assignSlotPositions(selectedId: '');
    }

    _recomputeAlerts();
    _recomputeImminentPairs();
    _reevaluateDeadlock();
    notifyListeners();
    return closedTrinityTutorial;
  }

  void _recomputeAlerts() {
    _alertIds.clear();
    final Map<int, Set<int>> colorsByShape = <int, Set<int>>{};
    final Map<int, List<String>> idsByShape = <int, List<String>>{};

    for (final e in _slotItems) {
      (colorsByShape[e.typeId] ??= <int>{}).add(e.colorId);
      (idsByShape[e.typeId] ??= <String>[]).add(e.id);
    }

    for (final entry in colorsByShape.entries) {
      final List<String>? ids = idsByShape[entry.key];
      if (ids == null) continue;
      if (ids.length == 2 && entry.value.length >= 2) {
        _alertIds.addAll(ids);
      }
    }
  }

  void _recomputeImminentPairs() {
    _imminentSlotIdxs.clear();
    if (_slotItems.length < 2) return;
    for (int i = 0; i < _slotItems.length - 1; i++) {
      final a = _slotItems[i];
      final b = _slotItems[i + 1];
      if (a.typeId == b.typeId || a.colorId == b.colorId) {
        _imminentSlotIdxs.add(i);
        _imminentSlotIdxs.add(i + 1);
      }
    }
  }

  void _triggerShake(int matchCount) {
    _shakeTick++;
    _shakeStrength = switch (matchCount) {
      3 => 4,
      4 => 6,
      _ => 9,
    };
  }

  void _reevaluateDeadlock() {
    if (_slotItems.length < slotCount) {
      _isGameOver = false;
      _criticalFailure = false;
      return;
    }

    final bool hasMatch = RackLogic.slotsHaveAnyTripleRun(_slotItems);
    if (hasMatch) {
      _isGameOver = false;
      _criticalFailure = false;
      return;
    }

    if (_tryOracleMercySalvageFromDeadlock()) {
      _isGameOver = false;
      _criticalFailure = false;
      _cancelMatchScheduling();
      _recomputeAlerts();
      _recomputeImminentPairs();
      AudioHandler.instance.playMatchCombo();
      HapticsHandler.instance.mediumImpact();
      _scheduleMatchCheck();
      notifyListeners();
      return;
    }

    _isGameOver = true;
    final bool wasCritical = _criticalFailure;
    _criticalFailure = true;
    _resetLevelTransitionState();
    _cancelMatchScheduling();
    if (!wasCritical) {
      _breakPerfectHeatDeadlockInternal();
      unawaited(_recordRunStatsIfNeeded());
      _resolveSessionStakeOnGameOver();
      _lastGameWasPersonalBest = _lux > _economy.highScore;
      _playGameOverSound();
      AudioHandler.instance.cutAllAudio();
      _persistHighScoreIfNeeded();
      _stopTimeLoop();
      _gameOverFlashTick++;
    }
  }

  // --- Audio ---

  void _playGameOverSound() {
    HapticsHandler.instance.errorVibrate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Timers annulés ici ; pas de StreamSubscription dans GameState.
    _cancelMatchScheduling();
    _stopTimeLoop();
    _matchParticleClearTimer?.cancel();
    _comboFloaterClearTimer?.cancel();
    _levelTransitionTimer?.cancel();
    _narrativeTutorial.removeListener(notifyListeners);
    _narrativeTutorial.dispose();
    _trinityTutorial.removeListener(notifyListeners);
    _trinityTutorial.dispose();
    _oracleNaming.removeListener(notifyListeners);
    _oracleNaming.dispose();
    _economy.removeListener(notifyListeners);
    _economy.dispose();
    timeBar.dispose();
    super.dispose();
  }
}
