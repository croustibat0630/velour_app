import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:velour_app/l10n/app_localizations.dart';

import '../providers/game_state.dart';
import '../services/audio_handler.dart';
import '../services/stats_service.dart';
import '../theme/theme_engine.dart';
import '../utils/responsive.dart';
import '../utils/velour_route_observer.dart';
import '../widgets/ui/dark_matte_overlay.dart';
import '../widgets/ui/menu_text_button.dart';
import '../widgets/ui/lux_score_displayer.dart';
import '../widgets/oracle_naming_dialog.dart';
import 'preparation_view.dart';

class MainMenuView extends StatefulWidget {
  const MainMenuView({super.key});

  @override
  State<MainMenuView> createState() => _MainMenuViewState();
}

class _MainMenuViewState extends State<MainMenuView>
    with SingleTickerProviderStateMixin, RouteAware {
  late final AnimationController _pulse;

  bool _menuMusicStarted = false;
  bool _menuBgmUnlockInFlight = false;
  int? _overrideInitialValue;
  bool _namingDialogOpen = false;
  int _streakDays = 0;

  Future<void> _refreshStreak() async {
    await StatsService.instance.load();
    if (!mounted) return;
    setState(() {
      _streakDays = StatsService.instance.snapshot().streakDays;
    });
  }

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final GameState gs = context.read<GameState>();
      gs.loadHighScore();
      gs.loadEconomyWelcome();
      unawaited(_refreshStreak());
    });
  }

  void _onFirstPointerDown() {
    if (_menuMusicStarted || _menuBgmUnlockInFlight) return;
    _menuBgmUnlockInFlight = true;
    unawaited(() async {
      bool ok = false;
      try {
        ok = await AudioHandler.instance.resumeAudioThenStartMenuBgm();
      } finally {
        _menuBgmUnlockInFlight = false;
      }
      if (!mounted) return;
      setState(() => _menuMusicStarted = ok);
    }());
  }

  /// Dotation premier lancement (non bloquant) + déverrouillage audio, puis navigation.
  void _primeMenuInteraction(VoidCallback navigate) {
    final GameState gs = context.read<GameState>();
    unawaited(gs.fireWelcomeGiftFromFirstMenuGestureIfPending());
    unawaited(AudioHandler.instance.unlockAudio());
    navigate();
  }

  @override
  void dispose() {
    velourRouteObserver.unsubscribe(this);
    _pulse.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    if (route is PageRoute<dynamic>) {
      velourRouteObserver.subscribe(this, route);
    }
  }

  void _syncPendingLuxJuiceIfAny() {
    final GameState gs = context.read<GameState>();
    final ({int amount, bool silent}) juice = gs.takePendingLuxJuice();
    final int pending = juice.amount;
    if (pending <= 0) return;
    _overrideInitialValue = (gs.luxCoins - pending).clamp(0, gs.luxCoins);
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Synchronise le son/haptique avec le **premier frame** où l’animation LUX démarre
      // (réduit la sensation de “son en retard”).
      if (!juice.silent) {
        try {
          AudioHandler.instance.playCredit();
          HapticFeedback.heavyImpact();
        } catch (_) {}
      }
      // Important: keep the override only for the first frame.
      _overrideInitialValue = null;
    });
  }

  @override
  void didPopNext() {
    _syncPendingLuxJuiceIfAny();
    unawaited(_refreshStreak());
  }

  @override
  void didPush() {
    _syncPendingLuxJuiceIfAny();
    unawaited(_refreshStreak());
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ThemeEngine te = context.watch<ThemeEngine>();
    final GameState gs = context.watch<GameState>();
    final double scaleH = Responsive.compactHeightScale(context);
    final bool tightHeight = scaleH < 1.0;
    const Color gold = Color(0xFFFFD700);

    if (gs.shouldShowNamingDialog && !_namingDialogOpen) {
      _namingDialogOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final bool? sealed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const OracleNamingDialog(),
        );
        if (!mounted) return;
        _namingDialogOpen = false;
        // Succès : montrer tout de suite le classement (où le nom apparaît).
        if (sealed == true) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).pushNamed('/leaderboard');
          });
        }
        unawaited(_refreshStreak());
      });
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _onFirstPointerDown(),
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, 0.10),
                    radius: 1.2,
                    colors: [Color(0xFF0B1020), Color(0xFF000000)],
                  ),
                ),
              ),
            ),
            const Positioned.fill(child: DarkMatteOverlay()),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: SingleChildScrollView(
                      physics: tightHeight
                          ? const BouncingScrollPhysics()
                          : const NeverScrollableScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: tightHeight ? 10 : 0,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedBuilder(
                              animation: _pulse,
                              builder: (context, _) {
                                final double s =
                                    (math.sin(_pulse.value * math.pi * 2) *
                                        0.5 +
                                    0.5);
                                final double glow = 0.18 + 0.12 * s;
                                final Color skinGlow =
                                    gs.currentSkin.primaryColor;
                                return FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    l10n.brandTitleDisplay,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    style: Theme.of(context)
                                        .textTheme
                                        .displaySmall
                                        ?.copyWith(
                                          fontSize: 68 * scaleH,
                                          fontWeight: FontWeight.w200,
                                          letterSpacing: 8,
                                          color: te
                                              .colorForId(1)
                                              .withValues(alpha: 0.96),
                                          shadows: [
                                            Shadow(
                                              color: skinGlow.withValues(
                                                alpha: 0.55 * glow,
                                              ),
                                              blurRadius: 42,
                                            ),
                                            Shadow(
                                              color: skinGlow.withValues(
                                                alpha: 0.35 + 0.25 * s,
                                              ),
                                              blurRadius: 18,
                                            ),
                                            Shadow(
                                              color: skinGlow.withValues(
                                                alpha: glow,
                                              ),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 22 * scaleH),
                            Text(
                              l10n.menuEditionSubtitle,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontSize: 12 * scaleH,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 4,
                                    color: Colors.white.withValues(alpha: 0.52),
                                  ),
                            ),
                            SizedBox(height: 14 * scaleH),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 28 * scaleH,
                              ),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      gold.withValues(alpha: 0.22),
                                      gold.withValues(alpha: 0.38),
                                      gold.withValues(alpha: 0.22),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.22, 0.5, 0.78, 1.0],
                                  ),
                                ),
                                child: const SizedBox(
                                  height: 1,
                                  width: double.infinity,
                                ),
                              ),
                            ),
                            SizedBox(height: 30 * scaleH),
                            if (_streakDays > 0) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.local_fire_department_rounded,
                                    size: 18 * scaleH,
                                    color: gold.withValues(alpha: 0.88),
                                  ),
                                  SizedBox(width: 8 * scaleH),
                                  Flexible(
                                    child: Text(
                                      l10n.menuStreakDays(_streakDays),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            letterSpacing: 2.4,
                                            fontWeight: FontWeight.w700,
                                            fontSize: (11 * scaleH).clamp(
                                              10.0,
                                              13.0,
                                            ),
                                            color: gold.withValues(alpha: 0.86),
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16 * scaleH),
                            ],
                            MenuTextButton(
                              label: l10n.menuPlay,
                              neon: te.colorForId(1),
                              scale: scaleH * 1.04,
                              baseAlpha: 0.96,
                              neonShadowBlur: 22,
                              fontSize: 17,
                              letterSpacing: 5.2,
                              onPressed: () => _primeMenuInteraction(() {
                                Navigator.of(
                                  context,
                                ).push(fadeRoute(const PreparationView()));
                              }),
                            ),
                            SizedBox(height: 12 * scaleH),
                            MenuTextButton(
                              label: l10n.menuGuidedTutorial,
                              neon: te.colorForId(3),
                              scale: scaleH,
                              baseAlpha: 0.72,
                              onPressed: () => _primeMenuInteraction(() {
                                gs.requestGuidedTutorialReplay();
                                Navigator.of(context).push(
                                  fadeRoute(
                                    const PreparationView(
                                      initialStake: SessionStakeKind.casual,
                                      casualStakeOnly: true,
                                    ),
                                  ),
                                );
                              }),
                            ),
                            SizedBox(height: 14 * scaleH),
                            MenuTextButton(
                              label: l10n.menuLeaderboard,
                              neon: te.colorForId(5),
                              scale: scaleH,
                              baseAlpha: 0.72,
                              onPressed: () => _primeMenuInteraction(
                                () => Navigator.of(
                                  context,
                                ).pushNamed('/leaderboard'),
                              ),
                            ),
                            SizedBox(height: 14 * scaleH),
                            MenuTextButton(
                              label: l10n.menuShop,
                              neon: te.colorForId(2),
                              scale: scaleH,
                              baseAlpha: 0.72,
                              onPressed: () => _primeMenuInteraction(
                                () => Navigator.of(context).pushNamed('/shop'),
                              ),
                            ),
                            SizedBox(height: 14 * scaleH),
                            MenuTextButton(
                              label: l10n.menuCareer,
                              neon: const Color(0xFFFFD700),
                              scale: scaleH,
                              baseAlpha: 0.72,
                              onPressed: () => _primeMenuInteraction(
                                () => Navigator.of(context).pushNamed('/stats'),
                              ),
                            ),
                            SizedBox(height: 14 * scaleH),
                            MenuTextButton(
                              label: l10n.menuSettings,
                              neon: te.colorForId(4),
                              scale: scaleH,
                              baseAlpha: 0.72,
                              onPressed: () => _primeMenuInteraction(
                                () => Navigator.of(
                                  context,
                                ).pushNamed('/settings'),
                              ),
                            ),
                            SizedBox(height: 28 * scaleH),
                            Consumer<GameState>(
                              builder: (context, gs, _) {
                                // Une seule ligne, rendue par `LuxScoreDisplayer` (pas de doublon).
                                return Center(
                                  child: LuxScoreDisplayer(
                                    lux: gs.luxCoins,
                                    initialValue: _overrideInitialValue,
                                    color: gold,
                                    prefix: l10n.luxHudPrefix(gs.highScore),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
