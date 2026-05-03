import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../providers/game_state_local_store.dart';
import 'firestore_service.dart';

void _economyLog(String event, {Map<String, Object?> data = const {}}) {
  final String payload = data.entries
      .map((e) => '${e.key}=${e.value}')
      .join(' ');
  developer.log(
    payload.isEmpty ? event : '$event $payload',
    name: 'velour.economy',
  );
}

/// Persistance LUX / record + synchro cloud (debounce LUX).
///
/// Extrait du [GameState] (strangler) : ne contient pas la logique plateau / match.
///
/// Synchronisation LUX cloud : priorité à la callable **`velourApplyLuxDelta`**
/// (transaction serveur) ; repli sur [FirestoreService.syncLuxToCloud] si besoin.
class EconomyService extends ChangeNotifier {
  EconomyService({GameStateLocalStore? localStore})
    : _local = localStore ?? const GameStateLocalStore();

  final GameStateLocalStore _local;

  /// Plafond par **crédit** LUX positif (anti-injection côté client).
  /// Doit rester ≥ gains premium (ex. royal 1250).
  static const int maxLuxPerPositiveCredit = 2500;

  static const int welcomeLuxGrant = 250;

  Timer? _luxCloudSyncDebounce;

  /// Somme des deltas LUX depuis le dernier flush cloud réussi (callable ou absolu).
  int _pendingLuxDeltaForCloud = 0;

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

  void addLuxCoins(int delta) {
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
    _pendingLuxDeltaForCloud += appliedDelta;
    _economyLog(
      'lux_delta',
      data: {'delta': appliedDelta, 'before': before, 'after': _luxCoins},
    );
    notifyListeners();
    unawaited(_persistLuxCoins());
    _scheduleDebouncedLuxCloudSync();
  }

  /// Dépense LUX (mise, shop) — pas de plafond sur les montants négatifs.
  void consumeLux(int amount) {
    if (amount <= 0) return;
    addLuxCoins(-amount);
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
    _pendingLuxDeltaForCloud += delta;
    _economyLog('welcome_grant', data: {'lux': _luxCoins});
    notifyListeners();
    await _local.persistWelcomeGrant(_luxCoins);
    _scheduleDebouncedLuxCloudSync();
  }

  Future<void> debugResetFirstLaunchWelcome() async {
    await _local.debugResetFirstLaunchWelcome();
    _luxCoins = 0;
    _firstLaunchPendingWelcome = true;
    _pendingLuxDeltaForCloud = 0;
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
    _pendingLuxDeltaForCloud = 0;
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
    _pendingLuxDeltaForCloud = 0;
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
    await _syncLuxToCloud(_luxCoins);
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
          if (_pendingLuxDeltaForCloud != 0) {
            _scheduleDebouncedLuxCloudSync();
          }
        }),
      );
    });
  }

  /// Vide le tampon de deltas LUX (callable puis repli absolu Firestore si besoin).
  Future<void> _drainPendingLuxCloudSync() async {
    while (_pendingLuxDeltaForCloud != 0) {
      final int d = _pendingLuxDeltaForCloud;
      final LuxDeltaApplyResult? r =
          await FirestoreService.instance.tryApplyLuxDeltaViaCallable(d);
      if (r != null && r.ok) {
        _pendingLuxDeltaForCloud -= d;
        final int? serverLux = r.newLux;
        if (serverLux != null && serverLux != _luxCoins) {
          _luxCoins = serverLux;
          await _persistLuxCoins();
          notifyListeners();
        }
        _economyLog('lux_cloud_delta_ok', data: {'delta': d, 'lux': _luxCoins});
      } else {
        await _syncLuxToCloud(_luxCoins);
        _pendingLuxDeltaForCloud = 0;
        _economyLog('lux_cloud_delta_fallback', data: {'lux': _luxCoins});
        break;
      }
    }
  }

  Future<void> _syncLuxToCloud(int amount) async {
    await FirestoreService.instance.syncLuxToCloud(amount);
  }

  Future<void> _syncHighScoreToCloud(int score) async {
    await FirestoreService.instance.syncHighScoreToCloud(score);
  }
}
