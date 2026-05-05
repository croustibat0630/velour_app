import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:velour_app/l10n/app_localizations.dart';

import '../providers/game_state.dart';
import '../utils/velour_debug_log.dart';
import '../services/app_settings.dart';
import '../services/audio_handler.dart';
import '../services/stats_service.dart';
import '../services/velour_observability.dart';
import '../theme/theme_engine.dart';
import 'main_menu_view.dart';

/// Écran d’accueil : fond noir, logo VELOUR avec balayage néon puis respiration légère.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const Duration _minSplash = Duration(seconds: 2);
  static const Duration _scanDuration = Duration(milliseconds: 1600);
  static const Duration _breatheDuration = Duration(milliseconds: 1800);

  late final AnimationController _scan;
  late final AnimationController _breathe;

  @override
  void initState() {
    super.initState();
    _scan = AnimationController(vsync: this, duration: _scanDuration);
    _breathe = AnimationController(vsync: this, duration: _breatheDuration);

    _scan.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed && mounted) {
        _breathe.repeat(reverse: true);
      }
    });

    _scan.forward();
    unawaited(_bootstrapThenNavigate());
  }

  Future<void> _bootstrapThenNavigate() async {
    final DateTime t0 = DateTime.now();

    try {
      await context.read<GameState>().bootstrapCloudAfterLocalLoad();
    } catch (e, st) {
      velourDebug('bootstrapCloudAfterLocalLoad: $e\n$st');
      VelourObservability.logFirestoreFailure(
        VelourObsCodes.splashBootstrapCloud,
        error: e,
        stackTrace: st,
      );
    }

    // Ne jamais bloquer la navigation sur l’audio (Chrome : AudioContext
    // inactif avant geste → init/preload peut pendre sur resume()).
    await Future.wait<void>([
      AppSettings.instance.load(),
      StatsService.instance.init(),
    ]);
    unawaited(() async {
      try {
        await AudioHandler.instance.init().timeout(
          const Duration(seconds: 5),
          onTimeout: () {},
        );
      } catch (_) {
        // Splash : navigation déjà découplée ; init audio best-effort.
      }
    }());

    final Duration elapsed = DateTime.now().difference(t0);
    if (elapsed < _minSplash) {
      await Future<void>.delayed(_minSplash - elapsed);
    }

    if (!mounted) return;
    if (!_scan.isCompleted) {
      await _scan.forward();
    }

    if (!mounted) return;
    await Navigator.of(context).pushReplacement(_fadeToMainRoute());
  }

  PageRouteBuilder<dynamic> _fadeToMainRoute() {
    return PageRouteBuilder<dynamic>(
      transitionDuration: const Duration(milliseconds: 800),
      reverseTransitionDuration: const Duration(milliseconds: 400),
      pageBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            return const MainMenuView();
          },
      transitionsBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            final Animation<double> curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            );
            return FadeTransition(opacity: curved, child: child);
          },
    );
  }

  @override
  void dispose() {
    _scan.dispose();
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ThemeEngine te = context.watch<ThemeEngine>();
    final Color neon = te.colorForId(1);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[_scan, _breathe]),
          builder: (BuildContext context, Widget? child) {
            final double scanT = Curves.easeInOutCubic.transform(_scan.value);
            final bool scanDone = _scan.isCompleted;
            final double breathe = scanDone
                ? (0.94 + 0.06 * Curves.easeInOutSine.transform(_breathe.value))
                : 1.0;
            final double baseReveal = 0.08 + 0.88 * scanT;
            final double opacity = (baseReveal * breathe).clamp(0.0, 1.0);

            final Color fill = Color.lerp(
              neon.withValues(alpha: 0.35),
              Colors.white,
              scanT,
            )!;

            return Opacity(
              opacity: opacity,
              child: Text(
                l10n.brandTitleDisplay,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontSize: 52,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 10,
                  color: fill.withValues(alpha: 0.94),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
