// Pulse cible tutoriel + bannière célébration « perfect » narratif.

part of 'game_screen.dart';

/// Pulse discret sur la gemme attendue (tutoriel narratif, sans main).
class _NarrativeTargetGemPulse extends StatefulWidget {
  const _NarrativeTargetGemPulse({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_NarrativeTargetGemPulse> createState() =>
      _NarrativeTargetGemPulseState();
}

class _NarrativeTargetGemPulseState extends State<_NarrativeTargetGemPulse>
    with SingleTickerProviderStateMixin {
  AnimationController? _c;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncNarrativeTargetPulse();
  }

  @override
  void didUpdateWidget(covariant _NarrativeTargetGemPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.active && oldWidget.active) {
      _c?.dispose();
      _c = null;
    } else if (widget.active) {
      _syncNarrativeTargetPulse();
    }
  }

  void _syncNarrativeTargetPulse() {
    if (!widget.active) {
      return;
    }
    if (velourReduceMotion(context)) {
      if (_c != null) {
        _c!.dispose();
        _c = null;
      }
      return;
    }
    _c ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    if (!_c!.isAnimating) {
      _c!.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active || _c == null || velourReduceMotion(context)) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _c!,
      builder: (BuildContext context, Widget? child) {
        final double t = Curves.easeInOutSine.transform(_c!.value);
        final double s = 1.0 + 0.045 * t;
        return Transform.scale(
          scale: s,
          filterQuality: FilterQuality.low,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Bannière « PERFECT MATCH » seule : le +500 reste dans le HUD LUX.
class _NarrativePerfectCelebrationBanner extends StatefulWidget {
  const _NarrativePerfectCelebrationBanner({super.key});

  @override
  State<_NarrativePerfectCelebrationBanner> createState() =>
      _NarrativePerfectCelebrationBannerState();
}

class _NarrativePerfectCelebrationBannerState
    extends State<_NarrativePerfectCelebrationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    )..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final double u = Curves.easeOutCubic.transform(
              _c.value.clamp(0.0, 1.0),
            );
            final double scale = 0.94 + 0.06 * u;
            return Transform.scale(
              scale: scale,
              filterQuality: FilterQuality.low,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(26, 22, 26, 22),
                  child: Text(
                    AppLocalizations.of(
                      context,
                    )!.gameNarrativePerfectMatchBanner,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 21,
                      height: 1.15,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 3.2,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
