// Combo floater, zone de jeu et rack — même lib que game_screen.

part of 'game_screen.dart';

// LUX Dust a été extrait dans `lib/game/particle_system.dart`.

class _ComboFloater extends StatefulWidget {
  const _ComboFloater({
    super.key,
    required this.chainMult,
    required this.position,
    required this.accent,
  });

  final double chainMult;
  final Offset position;
  final Color accent;

  @override
  State<_ComboFloater> createState() => _ComboFloaterState();
}

class _ComboFloaterState extends State<_ComboFloater>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 780),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String comboText = AppLocalizations.of(
      context,
    )!.gameFloatCombo(widget.chainMult.toStringAsFixed(1));
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final double t = Curves.easeOutCubic.transform(_c.value);
        final double scale = 0.65 + 0.55 * t;
        final double opacity = (1 - t * 0.35).clamp(0.0, 1.0);
        final Offset p = widget.position + Offset(0, -56 * t);
        // [Positioned] must sit under a [Stack]; [AnimatedBuilder] inserts a render
        // object, so we cannot return [Positioned] directly from this builder.
        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned(
              left: p.dx,
              top: p.dy,
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.centerLeft,
                child: Text(
                  comboText,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                    color: widget.accent.withValues(alpha: 0.96 * opacity),
                    shadows: [
                      Shadow(
                        color: widget.accent.withValues(alpha: 0.5 * opacity),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PlayZone extends StatelessWidget {
  const _PlayZone();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand(key: ValueKey('PlayZone'));
  }
}

class _SlotBar extends StatefulWidget {
  const _SlotBar({
    required this.imminentSlotIdxs,
    required this.slotItems,
    required this.accent,
    required this.premium,
  });

  final Set<int> imminentSlotIdxs;
  final List<GameItem> slotItems;
  final Color accent;
  final bool premium;

  @override
  State<_SlotBar> createState() => _SlotBarState();
}

class _SlotBarState extends State<_SlotBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  static const bool _enableBackdropBlur = bool.fromEnvironment(
    'VELOUR_UI_BLUR',
    defaultValue: false,
  );

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  void _syncRackPulse() {
    if (!mounted) return;
    if (velourReduceMotion(context)) {
      _pulse.stop();
      _pulse.value = 0.0;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncRackPulse();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double s = (math.sin(_pulse.value * math.pi * 2) * 0.5 + 0.5);
    final double a = 0.12 + 0.10 * s;
    final double scale = 1.0 + 0.03 * s;
    final Color accent = widget.accent;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final Widget bar = RepaintBoundary(
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xCC1E2228), // semi-transparent, matte
          border: Border(
            top: BorderSide(
              color: accent.withValues(alpha: widget.premium ? 0.42 : 0.3),
              width: 2,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List<Widget>.generate(GameState.slotCount, (index) {
            final bool imminent = widget.imminentSlotIdxs.contains(index);
            return Semantics(
              label: rackSlotSemanticsLabel(
                l10n,
                index,
                widget.slotItems,
                widget.imminentSlotIdxs,
              ),
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) {
                  return Transform.scale(
                    scale: imminent ? scale : 1.0,
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0F),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: imminent
                              ? Colors.white.withValues(alpha: 0.28 + a)
                              : Colors.white.withValues(alpha: 0.22),
                          width: imminent ? 1.2 : 1,
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: accent.withValues(
                              alpha: imminent ? a * 0.95 : 0.07,
                            ),
                            blurRadius: imminent ? 12 : 8,
                            spreadRadius: imminent ? 0.5 : 0,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ),
    );

    if (!_enableBackdropBlur) {
      return bar;
    }
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: bar,
      ),
    );
  }
}
