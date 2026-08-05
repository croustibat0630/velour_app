import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'firestore_service.dart';
import 'velour_analytics.dart';

/// Sprint 2 — **Activation Funnel** uniquement (pas de marketing secondaire).
///
/// Question produit : *à quel moment perd-on un nouveau joueur ?*
///
/// Événements `velour_ftue_*` (opt-in [VelourAnalytics.enabled]) avec enveloppe
/// commune : `session_id`, `is_first_launch`, `build_version`, `platform`,
/// `elapsed_ms`, et `uid` anonymisé Firebase si dispo.
///
/// KPI dérivés côté GA4 / BigQuery à partir de ces steps +
/// [perfect_before_quit] sur `velour_ftue_session_closed` et `velour_ftue_completed`.
final class VelourActivationFunnel {
  VelourActivationFunnel._();

  static final VelourActivationFunnel instance = VelourActivationFunnel._();

  static const int postPerfectContinueSec = 15;

  String _sessionId = '';
  bool _isFirstLaunch = false;
  String _buildVersion = 'unknown';
  String _platform = 'unknown';
  String? _uid;
  DateTime? _ftueStartedAt;
  bool _warmed = false;
  bool _ftueStartLogged = false;

  bool _firstGemLogged = false;
  bool _firstMatchLogged = false;
  bool _firstPerfectLogged = false;
  bool _ftueCompletedLogged = false;
  bool _sessionClosedLogged = false;

  int _runsStartedThisSession = 0;
  DateTime? _firstPerfectAt;
  Timer? _postPerfectContinueTimer;
  String _lastStep = 'none';

  /// Dernière étape funnel atteinte (debug / tests).
  String get lastStep => _lastStep;

  bool get hasFirstPerfect => _firstPerfectLogged;

  bool get ftueCompleted => _ftueCompletedLogged;

  @visibleForTesting
  void debugReset() {
    _postPerfectContinueTimer?.cancel();
    _postPerfectContinueTimer = null;
    _sessionId = '';
    _isFirstLaunch = false;
    _buildVersion = 'unknown';
    _platform = 'unknown';
    _uid = null;
    _ftueStartedAt = null;
    _warmed = false;
    _ftueStartLogged = false;
    _firstGemLogged = false;
    _firstMatchLogged = false;
    _firstPerfectLogged = false;
    _ftueCompletedLogged = false;
    _sessionClosedLogged = false;
    _runsStartedThisSession = 0;
    _firstPerfectAt = null;
    _lastStep = 'none';
  }

  /// Warm-up synchrone pour tests (évite [PackageInfo] / Auth).
  @visibleForTesting
  void debugWarmUpSync({required bool isFirstLaunch}) {
    _isFirstLaunch = isFirstLaunch;
    _sessionId = 'test_session';
    _platform = 'test';
    _buildVersion = '0.0.0+0';
    _ftueStartedAt = DateTime.now();
    _warmed = true;
  }

  /// Prépare l’enveloppe session. Appeler dès que [isFirstLaunch] est connu (prefs).
  Future<void> warmUp({required bool isFirstLaunch}) async {
    if (_warmed) return;
    _isFirstLaunch = isFirstLaunch;
    _sessionId = _mintSessionId();
    _platform = _resolvePlatform();
    _ftueStartedAt = DateTime.now();
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      _buildVersion = '${info.version}+${info.buildNumber}';
    } catch (_) {
      _buildVersion = 'unknown';
    }
    try {
      final String? uid = FirestoreService.instance.currentFirebaseUserId;
      if (uid != null && uid.isNotEmpty) {
        _uid = uid.length > 36 ? uid.substring(0, 36) : uid;
        if (VelourAnalytics.enabled) {
          await FirebaseAnalytics.instance.setUserId(id: _uid);
        }
      }
    } catch (_) {}
    _warmed = true;
  }

  void noteFtueStart() {
    if (!_warmed || _ftueStartLogged) return;
    _ftueStartLogged = true;
    _lastStep = 'ftue_start';
    _log('velour_ftue_start');
  }

  void noteMenuPlayPressed() {
    if (!_warmed) return;
    _lastStep = 'menu_play_pressed';
    _log('velour_ftue_menu_play');
  }

  void notePrepOpened({required String stakeKind}) {
    if (!_warmed) return;
    _lastStep = 'prep_opened';
    _log('velour_ftue_prep_open', <String, Object>{
      'stake_kind': _truncate(stakeKind),
    });
  }

  void notePrepConfirmed({required String stakeKind, String? runInstanceId}) {
    if (!_warmed) return;
    _lastStep = 'prep_confirmed';
    _log(
      'velour_ftue_prep_confirm',
      _withRun(runInstanceId, <String, Object>{
        'stake_kind': _truncate(stakeKind),
      }),
    );
  }

  void noteRunStarted({required String stakeKind, String? runInstanceId}) {
    if (!_warmed) return;
    _runsStartedThisSession++;
    if (_runsStartedThisSession == 1) {
      _lastStep = 'run_started';
      _log(
        'velour_ftue_run_start',
        _withRun(runInstanceId, <String, Object>{
          'stake_kind': _truncate(stakeKind),
          'run_index': 1,
        }),
      );
    } else if (_runsStartedThisSession == 2) {
      _lastStep = 'second_run_started';
      _log(
        'velour_ftue_second_run',
        _withRun(runInstanceId, <String, Object>{
          'stake_kind': _truncate(stakeKind),
          'run_index': 2,
          'perfect_before_second_run': _firstPerfectLogged ? 1 : 0,
        }),
      );
      _completeFtueIfEligible(reason: 'second_run');
    }
  }

  void noteFirstGemCollected() {
    if (!_warmed || _firstGemLogged) return;
    _firstGemLogged = true;
    _lastStep = 'first_gem_collected';
    _log('velour_ftue_first_gem', <String, Object>{
      'time_to_first_gem_ms': _elapsedMs(),
    });
  }

  void noteFirstMatch({required String basis}) {
    if (!_warmed || _firstMatchLogged) return;
    _firstMatchLogged = true;
    _lastStep = 'first_match';
    _log('velour_ftue_first_match', <String, Object>{
      'basis': _truncate(basis),
      'time_to_first_match_ms': _elapsedMs(),
    });
  }

  void noteFirstPerfect({required String basis}) {
    if (!_warmed || _firstPerfectLogged) return;
    _firstPerfectLogged = true;
    _firstPerfectAt = DateTime.now();
    _lastStep = 'first_perfect';
    _log('velour_ftue_first_perfect', <String, Object>{
      'basis': _truncate(basis),
      'time_to_first_perfect_ms': _elapsedMs(),
    });
    _armPostPerfectContinueTimer();
  }

  void noteRunFinished({
    required String endReason,
    required int runDurationSec,
    String? runInstanceId,
  }) {
    if (!_warmed) return;
    _lastStep = 'run_finished';
    _log(
      'velour_ftue_run_end',
      _withRun(runInstanceId, <String, Object>{
        'end_reason': _truncate(endReason),
        'run_duration_sec': runDurationSec.clamp(0, 86400),
        'run_index': _runsStartedThisSession.clamp(1, 99),
        'had_perfect': _firstPerfectLogged ? 1 : 0,
        'time_to_run_end_ms': _elapsedMs(),
      }),
    );
  }

  /// Fermeture / arrière-plan : émet [perfect_before_quit] une fois par session.
  void noteSessionClosed({required String lifecycle}) {
    if (!_warmed || _sessionClosedLogged) return;
    _sessionClosedLogged = true;
    _postPerfectContinueTimer?.cancel();
    _postPerfectContinueTimer = null;
    // [lastStep] n’est pas encore session_closed au moment de construire les params.
    _log('velour_ftue_session_closed', <String, Object>{
      'lifecycle': _truncate(lifecycle),
      'perfect_before_quit': _firstPerfectLogged ? 1 : 0,
      'last_funnel_step': _truncate(_snapshotLastMeaningfulStep()),
      'runs_started': _runsStartedThisSession.clamp(0, 99),
      'ftue_completed': _ftueCompletedLogged ? 1 : 0,
    });
    _lastStep = 'session_closed';
  }

  String _snapshotLastMeaningfulStep() {
    if (_ftueCompletedLogged) return 'ftue_completed';
    if (_runsStartedThisSession >= 2) return 'second_run_started';
    if (_firstPerfectLogged) return 'first_perfect';
    if (_firstMatchLogged) return 'first_match';
    if (_firstGemLogged) return 'first_gem_collected';
    if (_runsStartedThisSession >= 1) return 'run_started';
    if (_ftueStartLogged) return 'ftue_start';
    return 'none';
  }

  void _armPostPerfectContinueTimer() {
    _postPerfectContinueTimer?.cancel();
    _postPerfectContinueTimer = Timer(
      const Duration(seconds: postPerfectContinueSec),
      () {
        _completeFtueIfEligible(reason: 'post_perfect_15s');
      },
    );
  }

  void _completeFtueIfEligible({required String reason}) {
    if (!_warmed || _ftueCompletedLogged || !_firstPerfectLogged) return;
    if (reason != 'post_perfect_15s' && reason != 'second_run') {
      return;
    }
    _ftueCompletedLogged = true;
    _postPerfectContinueTimer?.cancel();
    _postPerfectContinueTimer = null;
    _lastStep = 'ftue_completed';
    final int? ttp = _firstPerfectAt == null || _ftueStartedAt == null
        ? null
        : _firstPerfectAt!.difference(_ftueStartedAt!).inMilliseconds;
    _log('velour_ftue_completed', <String, Object>{
      'reason': reason,
      if (ttp != null) 'time_to_first_perfect_ms': ttp.clamp(0, 86400000),
    });
  }

  Map<String, Object> _envelope([Map<String, Object>? extra]) {
    final Map<String, Object> params = <String, Object>{
      'session_id': _truncate(_sessionId, 36),
      'is_first_launch': _isFirstLaunch ? 1 : 0,
      'build_version': _truncate(_buildVersion, 40),
      'platform': _truncate(_platform, 16),
      'elapsed_ms': _elapsedMs(),
    };
    final String? uid = _uid;
    if (uid != null && uid.isNotEmpty) {
      params['uid'] = uid;
    }
    if (extra != null) {
      params.addAll(extra);
    }
    return params;
  }

  Map<String, Object> _withRun(
    String? runInstanceId,
    Map<String, Object> base,
  ) {
    final String? id = runInstanceId;
    if (id == null || id.isEmpty) return base;
    return <String, Object>{...base, 'run_instance_id': _truncate(id, 40)};
  }

  int _elapsedMs() {
    final DateTime? start = _ftueStartedAt;
    if (start == null) return 0;
    return DateTime.now().difference(start).inMilliseconds.clamp(0, 86400000);
  }

  void _log(String name, [Map<String, Object>? extra]) {
    if (!VelourAnalytics.enabled) return;
    final Map<String, Object> parameters = _envelope(extra);
    unawaited(VelourAnalytics.safeLogEvent(name: name, parameters: parameters));
  }

  static String _mintSessionId() {
    final int ms = DateTime.now().millisecondsSinceEpoch & 0xffffff;
    final int r = math.Random().nextInt(0xffff);
    return 'a_${ms.toRadixString(16)}_$r';
  }

  static String _resolvePlatform() {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }

  static String _truncate(String value, [int max = 100]) {
    if (value.length <= max) return value;
    return value.substring(0, max);
  }
}
