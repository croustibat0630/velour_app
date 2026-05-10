// Effets au retrait d'une gemme ([_ItemFx]) + halo néon ([_NeonHalo]).

part of 'game_screen.dart';

class _ItemFx extends StatefulWidget {
  const _ItemFx({
    required this.id,
    required this.isRemoving,
    required this.kind,
    required this.typeId,
    required this.neon,
    required this.child,
  });

  final String id;
  final bool isRemoving;
  final MatchKind? kind;
  final int typeId;
  final Color neon;
  final Widget child;

  @override
  State<_ItemFx> createState() => _ItemFxState();
}

class _ItemFxState extends State<_ItemFx> with TickerProviderStateMixin {
  late final AnimationController _implode;
  late final AnimationController _particles;
  List<Offset>? _sparkOffsets;
  bool _sparkBurstActive = false;

  @override
  void initState() {
    super.initState();
    _implode = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _particles = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _particles.addStatusListener(_onParticlesStatus);
  }

  void _onParticlesStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (!mounted) return;
      setState(() {
        _sparkBurstActive = false;
        _sparkOffsets = null;
      });
      _particles.reset();
    }
  }

  @override
  void didUpdateWidget(covariant _ItemFx oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isRemoving && widget.isRemoving) {
      final int count = widget.kind == MatchKind.perfect ? 16 : 5;
      final double spread = widget.kind == MatchKind.perfect ? 46 : 28;
      final math.Random rnd = math.Random(widget.id.hashCode ^ 0x1a2b3c4d);
      _sparkOffsets = List<Offset>.generate(count, (_) {
        return Offset(
          (rnd.nextDouble() - 0.5) * spread,
          (rnd.nextDouble() - 0.5) * spread,
        );
      });
      _sparkBurstActive = true;
      _implode.forward(from: 0);
      _particles.forward(from: 0);
    }
    if (oldWidget.isRemoving && !widget.isRemoving) {
      _implode.reset();
      _particles.reset();
      _sparkOffsets = null;
      _sparkBurstActive = false;
    }
  }

  @override
  void dispose() {
    _particles.removeStatusListener(_onParticlesStatus);
    _implode.dispose();
    _particles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isRemoving) {
      return widget.child;
    }

    final Color flashColor = widget.neon;
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[_implode, _particles]),
      builder: (context, _) {
        final double u = Curves.easeIn.transform(_implode.value);
        final double scale = (1.0 - u).clamp(0.0, 1.0);
        final double opacity = (1.0 - u * 0.92).clamp(0.0, 1.0);
        final double pt = Curves.easeOut.transform(_particles.value);
        final bool perfect = widget.kind == MatchKind.perfect;

        return SizedBox.expand(
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: <Widget>[
              Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.center,
                  child: widget.child,
                ),
              ),
              if (_sparkBurstActive && _sparkOffsets != null)
                for (int i = 0; i < _sparkOffsets!.length; i++)
                  Transform.translate(
                    offset:
                        _sparkOffsets![i] +
                        Offset(0, -(perfect ? 70 : 46) * pt),
                    child: Opacity(
                      opacity: (1 - pt).clamp(0.0, 1.0),
                      child: Container(
                        width: perfect ? 6 : 4,
                        height: perfect ? 6 : 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: flashColor.withValues(alpha: 0.92),
                          boxShadow: [
                            BoxShadow(
                              color: flashColor.withValues(alpha: 0.55),
                              blurRadius: perfect ? 10 : 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _NeonHalo extends StatelessWidget {
  const _NeonHalo({
    required this.color,
    required this.alert,
    required this.child,
    this.lowGlow = false,
  });

  final Color color;
  final bool alert;
  final Widget child;
  final bool lowGlow;

  @override
  Widget build(BuildContext context) {
    final double a = lowGlow ? 0.22 : 0.45;
    final double blur = lowGlow ? 8 : 15;
    final double spread = lowGlow ? 0.0 : 1.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: a),
            blurRadius: blur,
            spreadRadius: spread,
          ),
          if (alert)
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.22),
              blurRadius: 10,
              spreadRadius: 0,
            ),
        ],
      ),
      child: child,
    );
  }
}
