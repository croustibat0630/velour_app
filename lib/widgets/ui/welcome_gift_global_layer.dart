import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/game_state.dart';
import '../../utils/responsive.dart';
import '../../utils/route_transition_notifier.dart';

/// Affiche la bannière + compteur LUX (0 → 250) au-dessus de toute la navigation,
/// pour respecter l’AudioContext dès le premier geste menu (même si l’utilisateur
/// ouvre Boutique / Paramètres immédiatement).
class WelcomeGiftGlobalLayer extends StatefulWidget {
  const WelcomeGiftGlobalLayer({super.key});

  @override
  State<WelcomeGiftGlobalLayer> createState() => _WelcomeGiftGlobalLayerState();
}

class _WelcomeGiftGlobalLayerState extends State<WelcomeGiftGlobalLayer>
    with TickerProviderStateMixin {
  GameState? _gameState;
  int _consumedBurstId = 0;
  bool _busy = false;

  late final AnimationController _luxCounter;
  Animation<int>? _luxAnim;
  late final AnimationController _welcomeBanner;
  late final Animation<Offset> _welcomeBannerSlide;
  late final Animation<double> _welcomeBannerFade;
  late final AnimationController _luxPulse;

  bool _showWelcomeBanner = false;
  bool _frozenByRouteTransition = false;
  bool _pulseWasAnimating = false;
  bool _counterWasAnimating = false;

  void _onRouteTransitionTick() {
    final bool transitioning = RouteTransitionNotifier.isTransitioning;
    if (transitioning == _frozenByRouteTransition) return;

    _frozenByRouteTransition = transitioning;
    if (transitioning) {
      _pulseWasAnimating = _luxPulse.isAnimating;
      _counterWasAnimating = _luxCounter.isAnimating;
      _luxPulse.stop(canceled: false);
      _luxCounter.stop(canceled: false);
      // Don’t call setState: we want *less* rebuild while routes animate.
      return;
    }

    if (_pulseWasAnimating) {
      _luxPulse.forward(from: _luxPulse.value);
    }
    if (_counterWasAnimating) {
      _luxCounter.forward(from: _luxCounter.value);
    }
    _pulseWasAnimating = false;
    _counterWasAnimating = false;
  }

  @override
  void initState() {
    super.initState();
    _luxCounter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _luxPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _welcomeBanner = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );
    _welcomeBannerSlide = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0, -1.15),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 0.5,
      ),
      TweenSequenceItem(tween: ConstantTween<Offset>(Offset.zero), weight: 3.5),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0, -1.15),
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 0.5,
      ),
    ]).animate(_welcomeBanner);
    _welcomeBannerFade = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 0.5,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 3.5),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 0.5,
      ),
    ]).animate(_welcomeBanner);

    RouteTransitionNotifier.activeTransitions.addListener(
      _onRouteTransitionTick,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final GameState g = context.read<GameState>();
    if (_gameState == g) return;
    _gameState?.removeListener(_onGameState);
    _gameState = g;
    _gameState!.addListener(_onGameState);
  }

  @override
  void dispose() {
    RouteTransitionNotifier.activeTransitions.removeListener(
      _onRouteTransitionTick,
    );
    _gameState?.removeListener(_onGameState);
    _luxCounter.dispose();
    _luxPulse.dispose();
    _welcomeBanner.dispose();
    super.dispose();
  }

  void _onGameState() {
    if (!mounted || _busy) return;
    final int burst = _gameState?.welcomeGiftVisualBurstId ?? 0;
    if (burst <= _consumedBurstId) return;
    unawaited(_runBurst(burst));
  }

  Future<void> _runBurst(int burstId) async {
    _luxAnim = IntTween(
      begin: 0,
      end: GameState.welcomeLuxGrant,
    ).animate(CurvedAnimation(parent: _luxCounter, curve: Curves.easeOutCubic));
    setState(() {
      _busy = true;
      _showWelcomeBanner = true;
    });
    try {
      _luxPulse.forward(from: 0);
      final Future<void> banner = _welcomeBanner.forward(from: 0);
      final Future<void> counter = _luxCounter.forward(from: 0);
      await Future.wait<void>([banner, counter]);
      if (mounted) {
        _luxPulse
          ..stop()
          ..reset();
        setState(() {
          _luxAnim = null;
          _showWelcomeBanner = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _consumedBurstId = burstId;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_busy && !_showWelcomeBanner && _luxAnim == null) {
      return const SizedBox.shrink();
    }
    final double scaleH = Responsive.compactHeightScale(context);
    // `scaleH` is intentionally kept: it drives `_WelcomeLuxBanner` sizing.

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          if (_showWelcomeBanner)
            SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _welcomeBanner,
                      builder: (context, _) {
                        // Use GPU-friendly translation to avoid affecting other layers.
                        // `_welcomeBannerSlide` is in fractional units; map to px.
                        final double dy = _welcomeBannerSlide.value.dy;
                        final double dyPx = dy * (78 * scaleH);
                        return Transform.translate(
                          offset: Offset(0, dyPx),
                          child: FadeTransition(
                            opacity: _welcomeBannerFade,
                            child: RepaintBoundary(
                              child: _WelcomeLuxBanner(
                                scale: scaleH,
                                luxAmount: GameState.welcomeLuxGrant,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WelcomeLuxBanner extends StatelessWidget {
  const _WelcomeLuxBanner({required this.scale, required this.luxAmount});

  final double scale;
  final int luxAmount;
  static const Color _gold = Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: EdgeInsets.symmetric(
            horizontal: 14 * scale,
            vertical: 10 * scale,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF000000).withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _gold.withValues(alpha: 0.55), width: 1),
            boxShadow: [
              BoxShadow(color: _gold.withValues(alpha: 0.12), blurRadius: 24),
            ],
          ),
          child: Text(
            AppLocalizations.of(context)!.welcomeGiftBannerLux(luxAmount),
            textAlign: TextAlign.center,
            style:
                Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12 * scale,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 3.2,
                  color: _gold.withValues(alpha: 0.92),
                  shadows: [
                    Shadow(
                      color: _gold.withValues(alpha: 0.22),
                      blurRadius: 18,
                    ),
                  ],
                ) ??
                TextStyle(
                  fontSize: 12 * scale,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 3.2,
                  color: _gold.withValues(alpha: 0.92),
                ),
          ),
        ),
      ),
    );
  }
}
