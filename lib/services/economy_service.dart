import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../providers/game_state_local_store.dart';
import 'firestore_service.dart';
import 'lux_apply_motifs.dart';
import 'lux_credit_limits.dart';
import '../utils/velour_audit_log.dart';
import 'remote_config_service.dart';
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

  /// Erreurs Functions où retenter le **même** delta est sans espoir (évite boucle drain).
  static const Set<String> _luxCallableUnrecoverableCodes = <String>{
    'invalid-argument',
    'failed-precondition',
  };

  final GameStateLocalStore _local;

  int _luxCloudUnrecoverableNoticeId = 0;
  ({int id, String code, String motif})? _luxCloudUnrecoverableNotice;

  ({int id, String code, String motif})? consumeLuxCloudUnrecoverableNotice() {
    final ({int id, String code, String motif})? n =
        _luxCloudUnrecoverableNotice;
    _luxCloudUnrecoverableNotice = null;
    return n;
  }

  /// Plafond par **crédit** LUX positif (anti-injection côté client).
  /// Aligné sur [LuxCreditLimits.maxPositiveCreditPerApply].
  static const int maxLuxPerPositiveCredit =
      LuxCreditLimits.maxPositiveCreditPerApply;

  static int get welcomeLuxGrant => VelourRemoteConfig.instance.welcomeLuxGrant;

  /// Bonus quotidien gratuit (aligné Cloud Function `daily_bonus`).
  static int get dailyLuxBonusAmount =>
      VelourRemoteConfig.instance.dailyLuxBonus;

  Timer? _luxCloudSyncDebounce;
  Timer? _pendingLuxPersistDebounce;

  /// Deltas LUX à pousser vers la callable, **par motif** (journal / plafonds serveur).
  final Map<String, List<int>> _pendingLuxByMotifForCloud =
      <String, List<int>>{};

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
    _pendingLuxPersistDebounce?.cancel();
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

  void hydratePendingLuxByMotifFromDisk(Map<String, List<int>> pending) {
    if (pending.isEmpty) return;
    if (_pendingLuxByMotifForCloud.isNotEmpty) return;
    _pendingLuxByMotifForCloud.addAll(pending);
    _economyLog(
      'lux_pending_hydrate_disk',
      data: <String, Object?>{'motifs': pending.length},
    );
    _schedulePersistPendingLuxByMotif();
  }

  void _schedulePersistPendingLuxByMotif() {
    _pendingLuxPersistDebounce?.cancel();
    _pendingLuxPersistDebounce = Timer(const Duration(milliseconds: 500), () {
      unawaited(
        _local.persistPendingLuxByMotifForCloud(_pendingLuxByMotifForCloud),
      );
    });
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
      final List<int> q = _pendingLuxByMotifForCloud[luxCloudMotif] ?? <int>[];
      q.add(appliedDelta);
      _pendingLuxByMotifForCloud[luxCloudMotif] = q;
      _schedulePersistPendingLuxByMotif();
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
    // (prevP unused) keep intent visible without aggregating.
    final List<int> q =
        _pendingLuxByMotifForCloud[LuxApplyMotifs.welcomeGrant] ?? <int>[];
    q.add(delta);
    _pendingLuxByMotifForCloud[LuxApplyMotifs.welcomeGrant] = q;
    _schedulePersistPendingLuxByMotif();
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
    _schedulePersistPendingLuxByMotif();
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
    _schedulePersistPendingLuxByMotif();
    _luxCloudSyncDebounce?.cancel();
    _luxCloudSyncDebounce = null;
    _economyLog('hard_reset', data: const {});
    notifyListeners();
  }

  /// Somme des deltas **positifs** encore en attente d’envoi cloud (avant merge bootstrap).
  int sumPendingPositiveLuxForCloud() {
    int sum = 0;
    for (final List<int> q in _pendingLuxByMotifForCloud.values) {
      for (final int v in q) {
        if (v > 0) sum += v;
      }
    }
    return sum;
  }

  /// Plafonne le solde local après bootstrap lorsque le reconcile serveur est borné.
  Future<void> clampLuxCoinsToCeiling(int ceiling) async {
    final int c = math.max(0, ceiling);
    if (_luxCoins <= c) return;
    _luxCoins = c;
    await _persistLuxCoins();
    _economyLog('lux_ceiling_clamp', data: <String, Object?>{'lux': _luxCoins});
    notifyListeners();
  }

  /// Monte le solde local au minimum du total serveur (sans rejouer une sync cloud).
  Future<void> applyLuxCoinsFloorFromServer(int serverLux) async {
    final int floor = math.max(0, serverLux);
    if (_luxCoins >= floor) return;
    final int delta = floor - _luxCoins;
    _luxCoins = floor;
    pendingLuxAnimation += delta;
    await _persistLuxCoins();
    _economyLog(
      'lux_floor_from_server',
      data: <String, Object?>{'lux': _luxCoins, 'delta': delta},
    );
    notifyListeners();
  }

  Future<void> mergeBootstrapFromCloud({
    required PlayerCloudPull pulled,
    required int? pendingLux,
    required int? pendingHigh,
  }) async {
    final Map<String, List<int>> preserved = <String, List<int>>{};
    for (final MapEntry<String, List<int>> e
        in _pendingLuxByMotifForCloud.entries) {
      if (e.value.isEmpty) continue;
      preserved[e.key] = List<int>.from(e.value);
    }
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

    for (final MapEntry<String, List<int>> e in preserved.entries) {
      _pendingLuxByMotifForCloud[e.key] = List<int>.from(e.value);
    }
    await _local.persistPendingLuxByMotifForCloud(_pendingLuxByMotifForCloud);
    _schedulePersistPendingLuxByMotif();

    _economyLog(
      'bootstrap_merge',
      data: <String, Object?>{
        'lux': mergedLux,
        'highScore': mergedHs,
        'pendingMotifsPreserved': preserved.length,
      },
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
    for (final List<int> q in _pendingLuxByMotifForCloud.values) {
      if (q.isEmpty) continue;
      for (final int v in q) {
        if (v != 0) return true;
      }
    }
    return false;
  }

  String? _firstPendingLuxCloudMotif() {
    for (final String m in LuxApplyMotifs.cloudDrainOrder) {
      final List<int>? q = _pendingLuxByMotifForCloud[m];
      if (q == null || q.isEmpty) continue;
      if (q.any((int v) => v != 0)) return m;
    }
    for (final MapEntry<String, List<int>> e
        in _pendingLuxByMotifForCloud.entries) {
      final List<int> q = e.value;
      if (q.isEmpty) continue;
      if (q.any((int v) => v != 0)) return e.key;
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
      final List<int> q = _pendingLuxByMotifForCloud[motif] ?? <int>[];
      if (q.isEmpty) {
        _pendingLuxByMotifForCloud.remove(motif);
        continue;
      }
      // Nettoie les zéros en tête si besoin.
      while (q.isNotEmpty && q.first == 0) {
        q.removeAt(0);
      }
      if (q.isEmpty) {
        _pendingLuxByMotifForCloud.remove(motif);
        _schedulePersistPendingLuxByMotif();
        continue;
      }

      final int d0 = q.first;
      final int step = FirestoreService.chunkLuxDeltaForCallable(d0);
      if (step == 0) break;

      final String idempotencyKey =
          '$motif|drain|d0=$d0|${DateTime.now().microsecondsSinceEpoch}|${math.Random().nextInt(0x7fffffff)}';
      final LuxDeltaApplyResult? r = await FirestoreService.instance
          .tryApplyLuxDeltaViaCallable(
            step,
            motif: motif,
            idempotencyKey: idempotencyKey,
          );
      if (r != null && r.ok) {
        final int applied = r.appliedDelta ?? step;
        if (applied == 0 && d0 != 0) {
          // Ex. plafond journalier motif (`daily_bonus`) : évite boucle infinie sur la file.
          q.removeAt(0);
          VelourObservability.logEconomySecurity(
            'lux_cloud_delta_ok_zero_applied',
            data: <String, Object?>{'motif': motif, 'requested': d0},
          );
          _economyLog(
            'lux_cloud_delta_ok_zero_applied',
            data: <String, Object?>{'motif': motif, 'requested': d0},
          );
        } else {
          final int remaining = d0 - applied;
          if (remaining == 0) {
            q.removeAt(0);
          } else {
            q[0] = remaining;
          }
        }
        if (q.isEmpty) {
          _pendingLuxByMotifForCloud.remove(motif);
        } else {
          _pendingLuxByMotifForCloud[motif] = q;
        }
        _schedulePersistPendingLuxByMotif();
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
            'requested': d0,
            'chunk': step,
            'applied': applied,
            'lux': _luxCoins,
          },
        );
      } else {
        final String? fe = r?.functionErrorCode;
        if (fe != null && _luxCallableUnrecoverableCodes.contains(fe)) {
          // Drop uniquement le delta courant pour ce motif (pas tout le motif).
          if (q.isNotEmpty) {
            q.removeAt(0);
          }
          if (q.isEmpty) {
            _pendingLuxByMotifForCloud.remove(motif);
          } else {
            _pendingLuxByMotifForCloud[motif] = q;
          }
          _schedulePersistPendingLuxByMotif();
          _luxCloudUnrecoverableNoticeId++;
          _luxCloudUnrecoverableNotice = (
            id: _luxCloudUnrecoverableNoticeId,
            code: fe,
            motif: motif,
          );
          notifyListeners();
          _economyLog(
            'lux_cloud_delta_unrecoverable',
            data: <String, Object?>{
              'motif': motif,
              'chunk': step,
              'firebaseCode': fe,
              'lux': _luxCoins,
            },
          );
          VelourObservability.logEconomySecurity(
            'lux_cloud_unrecoverable_motif_dropped',
            data: <String, Object?>{'motif': motif, 'code': fe, 'chunk': step},
          );
          FirestoreService.instance.queuePendingLuxCloudHint(_luxCoins);
          break;
        }
        final int now = DateTime.now().microsecondsSinceEpoch;
        final String failKey = '$motif|$d0';
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
              'requested': d0,
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
            'pending': d0,
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
