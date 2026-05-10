// Rendu des gemmes : [_itemWidget] + tactile [_GemTapJuice].

part of 'game_screen.dart';

Widget _itemWidget(GameItem item, double size, Color neon) {
  return switch (item.typeId) {
    1 => NeonCrystal(neon: neon, size: size),
    2 => NeonSphere(neon: neon, size: size),
    3 => NeonPyramid(neon: neon, size: size),
    4 => NeonStar(neon: neon, size: size),
    5 => NeonDiamond(neon: neon, size: size),
    6 => NeonPentagon(neon: neon, size: size),
    7 => NeonHexaStar(neon: neon, size: size),
    _ => NeonCrystal(neon: neon, size: size),
  };
}

/// Tactile “pop” + color flash before a board piece commits to the slot queue.
class _GemTapJuice extends StatefulWidget {
  const _GemTapJuice({
    required this.semanticsLabel,
    required this.isOnBoard,
    required this.typeId,
    required this.neon,
    required this.onSelect,
    required this.child,
    this.stakeTapTraceColor,
    this.stakeTapParticleBoost = 1.0,
  });

  /// VoiceOver / TalkBack (forme + couleur).
  final String semanticsLabel;

  final bool isOnBoard;
  final int typeId;
  final Color neon;
  final Future<void> Function() onSelect;
  final Widget child;

  /// High Stakes / Royal : liséré + particules au tap (plateau).
  final Color? stakeTapTraceColor;
  final double stakeTapParticleBoost;

  @override
  State<_GemTapJuice> createState() => _GemTapJuiceState();
}

class _GemTapJuiceState extends State<_GemTapJuice>
    with TickerProviderStateMixin {
  late final AnimationController _pop;
  late final CurvedAnimation _popCurved;
  late final AnimationController _goldTrace;
  int _dustSeed = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _popCurved = CurvedAnimation(parent: _pop, curve: Curves.easeOutCubic);
    _goldTrace = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
  }

  @override
  void dispose() {
    _popCurved.dispose();
    _pop.dispose();
    _goldTrace.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_busy) return;
    if (!widget.isOnBoard) {
      await widget.onSelect();
      return;
    }
    _busy = true;
    if (velourReduceMotion(context)) {
      await widget.onSelect();
      if (mounted) {
        _busy = false;
      }
      return;
    }
    await _pop.forward(from: 0);
    if (!mounted) return;
    await widget.onSelect();
    _pop.reset();
    _busy = false;
  }

  @override
  Widget build(BuildContext context) {
    final Color c = widget.neon;
    final bool rm = velourReduceMotion(context);
    return Semantics(
      button: true,
      label: widget.semanticsLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          // Immediate select feedback on press (not release).
          AudioHandler.instance.playGemSelect();
          AudioHandler.instance.primeMatchPoolOnFirstUserTap();
          HapticsHandler.instance.selectionClick();
          if (!rm && widget.stakeTapTraceColor != null && widget.isOnBoard) {
            _dustSeed++;
            _goldTrace.forward(from: 0);
          }
        },
        onTap: _handleTap,
        child: SizedBox.expand(
          child: AnimatedBuilder(
            animation: Listenable.merge([_pop, _goldTrace]),
            builder: (context, child) {
              final double t = rm ? 0.0 : _popCurved.value;
              final double scale = rm ? 1.0 : (1.0 + 0.2 * t);
              final double flash = rm
                  ? 0.0
                  : (math.sin(math.pi * t) * 0.34).clamp(0.0, 1.0);
              return Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Transform.scale(
                    scale: scale,
                    alignment: Alignment.center,
                    child: child,
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: flash,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: c.withValues(alpha: 0.42),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!rm &&
                      widget.stakeTapTraceColor != null &&
                      widget.isOnBoard)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: StakeGemTapFxPainter(
                            typeId: widget.typeId,
                            t: _goldTrace.value,
                            particleSeed: _dustSeed,
                            accentColor: widget.stakeTapTraceColor!,
                            particleBoost: widget.stakeTapParticleBoost,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
