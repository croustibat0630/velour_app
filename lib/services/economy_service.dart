import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../providers/game_state_local_store.dart';
import 'firestore_service.dart';
import 'lux_apply_motifs.dart';
import 'lux_credit_limits.dart';
import '../utils/velour_audit_log.dart';
import 'velour_observability.dart';

void _economyLog(String event, {Map<String, Object?> data = const {}}) {
  VelourAuditLog.event('economy.$event', data: data);
}

/// Persistance LUX / record + synchro cloud (debounce LUX).
///
/// Extrait du [GameState] (strangler) : ne contient pas la logique plateau / match.
///
/// Synchronisation LUX cloud : uniquement la callable **`velourApplyLuxDelta`**
/// (économie server-authoritative — pas d’écriture Firestore client sur `totalLux`).
class EconomyService extends ChangeNotifier {
  EconomyService({GameStateLocalStore? localStore})
    : _local = localStore ?? const GameStateLocalStore();

  final GameStateLocalStore _local;

  /// Plafond par **crédit** LUX positif (anti-injection côté client).
  /// Aligné sur [LuxCreditLimits.maxPositiveCreditPerApply].
  static const int maxLuxPerPositiveCredit =
      LuxCreditLimits.maxPositiveCreditPerApply;

  static const int welcomeLuxGrant = 250;

  Timer? _luxCloudSyncDebounce;

  /// Deltas LUX à pousser vers la callable, **par motif** (journal / plafonds serveur).
  final Map<String, int> _pendingLuxByMotifForCloud = <String, int>{};

  // Avoid log spam when offline: we only emit a fail log periodically,
  // or when the pending amount changes.
  int _lastLuxCloudFailLogMicros = 0;
  String? _lastLuxCloudFailPending;

  int _luxCoins = 0;
  int get luxCoins => _luxCoins;

  int pendingLuxAnimation = 0;
  bool _pendingLuxJuiceSilent = false;

  int _highScore = 0;
  int get highScore => _highScore;

  bool _highScoreLoaded = false;
  bool get highScoreLoaded => _highScoreLoaded;

  bool _economyLoaded = false;
  bool get economyLoadedFromDisk => _economyLoaded;

  bool _firstLaunchPendingWelcome = false;
  bool get hasPendingWelcomeGift => _firstLaunchPendingWelcome;

  /// Appelé après un nouveau record persistant (déclenchement cérémonie Oracle).
  Future<void> Function(int newHighScore)? onPersonalBestCommitted;

  @override
  void dispose() {
    _luxCloudSyncDebounce?.cancel();
    super.dispose();
  }

  /// Hydrate LUX + drapeau cadeau depuis le disque (une fois).
  void hydrateLuxAndWelcomeFromDisk(EconomyWelcomeLoad disk) {
    if (_economyLoaded) return;
    _economyLoaded = true;
    _luxCoins = math.max(0, disk.luxCoinsRaw);
    _firstLaunchPendingWelcome = disk.isFirstLaunch;
    _economyLog(
      'hydrate_disk',
      data: {'lux': _luxCoins, 'firstLaunch': _firstLaunchPendingWelcome},
    );
    notifyListeners();
  }

  Future<void> loadHighScoreFromDisk() async {
    if (_highScoreLoaded) return;
    _highScoreLoaded = true;
    _highScore = await _local.loadHighScoreOrZero();
    _economyLog('high_score_disk_load', data: {'highScore': _highScore});
    notifyListeners();
  }

  /// [luxCloudMotif] : voir [LuxApplyMotifs] — aligné sur la callable `velourApplyLuxDelta`.
  /// Si [recordCloudPending] est `false`, le solde local bouge mais aucune sync LUX
  /// n’est planifiée (ex. miroir après crédit IAP déjà appliqué côté serveur).
  void addLuxCoins(
    int delta, {
    required String luxCloudMotif,
    bool recordCloudPending = true,
  }) {
    if (delta == 0) return;

    int appliedDelta = delta;
    if (delta > 0) {
      final int capped = delta.clamp(0, maxLuxPerPositiveCredit);
      if (capped < delta) {
        _economyLog(
          'lux_credit_clamped',
          data: {'requested': delta, 'applied': capped},
        );
        appliedDelta = capped;
      }
    }

    final int before = _luxCoins;
    _luxCoins = math.max(0, _luxCoins + appliedDelta);
    if (appliedDelta > 0) {
      pendingLuxAnimation += appliedDelta;
    }
    if (recordCloudPending) {
      final int prevP = _pendingLuxByMotifForCloud[luxCloudMotif] ?? 0;
      _pendingLuxByMotifForCloud[luxCloudMotif] = prevP + appliedDelta;
    }
    _economyLog(
      'lux_delta',
      data: <String, Object?>{
        'delta': appliedDelta,
        'before': before,
        'after': _luxCoins,
        'motif': luxCloudMotif,
        'cloudPending': recordCloudPending,
      },
    );
    notifyListeners();
    unawaited(_persistLuxCoins());
    if (recordCloudPending) {
      _scheduleDebouncedLuxCloudSync();
    }
  }

  /// Dépense LUX (mise, shop) — pas de plafond sur les montants négatifs.
  void consumeLux(int amount, {required String luxCloudMotif}) {
    if (amount <= 0) return;
    addLuxCoins(-amount, luxCloudMotif: luxCloudMotif);
  }

  ({int amount, bool silent}) takePendingLuxJuice() {
    final int v = pendingLuxAnimation;
    final bool silent = _pendingLuxJuiceSilent;
    pendingLuxAnimation = 0;
    _pendingLuxJuiceSilent = false;
    return (amount: v, silent: silent);
  }

  Future<void> grantWelcomeLuxIfPending() async {
    if (!_firstLaunchPendingWelcome) return;
    _firstLaunchPendingWelcome = false;
    final int before = _luxCoins;
    _luxCoins = welcomeLuxGrant;
    final int delta = _luxCoins - before;
    if (delta > 0) {
      pendingLuxAnimation += delta;
      _pendingLuxJuiceSilent = true;
    }
    final int prevP =
        _pendingLuxByMotifForCloud[LuxApplyMotifs.welcomeGrant] ?? 0;
    _pendingLuxByMotifForCloud[LuxApplyMotifs.welcomeGrant] = prevP + delta;
    _economyLog('welcome_grant', data: {'lux': _luxCoins});
    notifyListeners();
    await _local.persistWelcomeGrant(_luxCoins);
    _scheduleDebouncedLuxCloudSync();
  }

  Future<void> debugResetFirstLaunchWelcome() async {
    await _local.debugResetFirstLaunchWelcome();
    _luxCoins = 0;
    _firstLaunchPendingWelcome = true;
    _pendingLuxByMotifForCloud.clear();
    _economyLog('debug_reset_welcome', data: const {});
    notifyListeners();
  }

  void resetForFullHardReset() {
    _economyLoaded = false;
    _highScoreLoaded = false;
    _luxCoins = 0;
    _highScore = 0;
    _firstLaunchPendingWelcome = true;
    pendingLuxAnimation = 0;
    _pendingLuxJuiceSilent = false;
    _pendingLuxByMotifForCloud.clear();
    _luxCloudSyncDebounce?.cancel();
    _luxCloudSyncDebounce = null;
    _economyLog('hard_reset', data: const {});
    notifyListeners();
  }

  Future<void> mergeBootstrapFromCloud({
    required PlayerCloudPull pulled,
    required int? pendingLux,
    required int? pendingHigh,
  }) async {
    _pendingLuxByMotifForCloud.clear();
    final int mergedLux = math.max(
      math.max(_luxCoins, pulled.cloudLuxCoins),
      pendingLux ?? 0,
    );
    final int mergedHs = math.max(
      math.max(_highScore, pulled.cloudHighScore),
      pendingHigh ?? 0,
    );
    _luxCoins = mergedLux;
    _highScore = mergedHs;
    _economyLog(
      'bootstrap_merge',
      data: {'lux': mergedLux, 'highScore': mergedHs},
    );
    notifyListeners();
  }

  Future<void> persistLuxAndHighScoreLocalAfterBootstrap() async {
    await _persistLuxCoins();
    await _local.persistHighScore(_highScore);
  }

  Future<void> flushCloudSyncOnLifecycleHide() async {
    _luxCloudSyncDebounce?.cancel();
    _luxCloudSyncDebounce = null;

    if (!_economyLoaded) return;

    await _persistLuxCoins();
    await _drainPendingLuxCloudSync();
    if (_highScoreLoaded) {
      await _syncHighScoreToCloud(_highScore);
    }
    _economyLog(
      'lifecycle_flush',
      data: {'lux': _luxCoins, 'highScore': _highScore},
    );
  }

  Future<void> flushLuxCoinsPersistenceOnly() async {
    await _persistLuxCoins();
  }

  Future<void> commitRunHighScoreIfBetter(int runLux) async {
    if (runLux <= _highScore) return;
    _highScore = runLux;
    await _local.persistHighScore(_highScore);
    unawaited(_syncHighScoreToCloud(_highScore));
    _economyLog('personal_best', data: {'highScore': _highScore});
    notifyListeners();
    if (onPersonalBestCommitted != null) {
      await onPersonalBestCommitted!.call(_highScore);
    }
  }

  Future<void> _persistLuxCoins() async {
    await _local.persistLuxCoins(_luxCoins);
  }

  void _scheduleDebouncedLuxCloudSync() {
    _luxCloudSyncDebounce?.cancel();
    _luxCloudSyncDebounce = Timer(const Duration(milliseconds: 650), () {
      unawaited(
        _drainPendingLuxCloudSync().then((_) {
          if (_hasPendingLuxCloudDeltas()) {
            _scheduleDebouncedLuxCloudSync();
          }
        }),
      );
    });
  }

  bool _hasPendingLuxCloudDeltas() {
    for (final int v in _pendingLuxByMotifForCloud.values) {
      if (v != 0) return true;
    }
    return false;
  }

  String? _firstPendingLuxCloudMotif() {
    for (final String m in LuxApplyMotifs.cloudDrainOrder) {
      if ((_pendingLuxByMotifForCloud[m] ?? 0) != 0) return m;
    }
    for (final MapEntry<String, int> e in _pendingLuxByMotifForCloud.entries) {
      if (e.value != 0) return e.key;
    }
    return null;
  }

  /// Vide le tampon de deltas LUX via la callable (chunks côté serveur si plafond).
  Future<void> _drainPendingLuxCloudSync() async {
    const bool forceOffline = bool.fromEnvironment(
      'VELOUR_FORCE_OFFLINE',
      defaultValue: false,
    );
    while (_hasPendingLuxCloudDeltas()) {
      final String? motif = _firstPendingLuxCloudMotif();
      if (motif == null) break;
      final int pendingForMotif = _pendingLuxByMotifForCloud[motif] ?? 0;
      if (pendingForMotif == 0) continue;

      final int d = pendingForMotif;
      final int step = FirestoreService.chunkLuxDeltaForCallable(d);
      if (step == 0) break;

      final LuxDeltaApplyResult? r = await FirestoreService.instance
          .tryApplyLuxDeltaViaCallable(step, motif: motif);
      if (r != null && r.ok) {
        final int applied = r.appliedDelta ?? step;
        final int nextP = pendingForMotif - applied;
        if (nextP == 0) {
          _pendingLuxByMotifForCloud.remove(motif);
        } else {
          _pendingLuxByMotifForCloud[motif] = nextP;
        }
        final int? serverLux = r.newLux;
        if (serverLux != null && serverLux != _luxCoins) {
          _luxCoins = math.max(_luxCoins, serverLux);
          await _persistLuxCoins();
          notifyListeners();
        }
        _economyLog(
          'lux_cloud_delta_ok',
          data: <String, Object?>{
            'motif': motif,
            'requested': d,
            'chunk': step,
            'applied': applied,
            'lux': _luxCoins,
          },
        );
      } else {
        final int now = DateTime.now().microsecondsSinceEpoch;
        final String failKey = '$motif|$d';
        final bool pendingChanged = _lastLuxCloudFailPending != failKey;
        final bool rateOk =
            (now - _lastLuxCloudFailLogMicros) > 5 * 1000 * 1000;
        if (pendingChanged || rateOk) {
          _lastLuxCloudFailLogMicros = now;
          _lastLuxCloudFailPending = failKey;
          _economyLog(
            'lux_cloud_delta_fail',
            data: <String, Object?>{
              'motif': motif,
              'requested': d,
              'chunk': step,
              'lux': _luxCoins,
              if (forceOffline) 'forcedOffline': true,
            },
          );
        }
        VelourObservability.logEconomySecurity(
          'lux_cloud_drain_failed',
          data: <String, Object?>{
            'motif': motif,
            'pending': d,
            'lux': _luxCoins,
          },
        );
        FirestoreService.instance.queuePendingLuxCloudHint(_luxCoins);
        break;
      }
    }
  }

  Future<void> _syncHighScoreToCloud(int score) async {
    await FirestoreService.instance.syncHighScoreToCloud(score);
  }
}
