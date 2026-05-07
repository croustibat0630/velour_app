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

/// Écran d’accueil : fond noir, logo VELOUR avec un seul balayage néon puis menu.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  /// Garde un minimum pour laisser le bootstrap / prefs finir sans écran noir trop bref.
  static const Duration _minSplash = Duration(milliseconds: 900);
  static const Duration _scanDuration = Duration(milliseconds: 1000);

  late final AnimationController _scan;

  @override
  void initState() {
    super.initState();
    _scan = AnimationController(vsync: this, duration: _scanDuration);
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
    await Navigator.of(context).pushReplacement(_instantMainRoute());
  }

  /// Pas de 2ᵉ « cinématique » : le menu remplace le splash sans fondu.
  PageRouteBuilder<dynamic> _instantMainRoute() {
    return PageRouteBuilder<dynamic>(
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
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
            return child;
          },
    );
  }

  @override
  void dispose() {
    _scan.dispose();
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
          animation: _scan,
          builder: (BuildContext context, Widget? child) {
            final double scanT = Curves.easeInOutCubic.transform(_scan.value);
            final double baseReveal = 0.08 + 0.88 * scanT;
            final double opacity = baseReveal.clamp(0.0, 1.0);

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
