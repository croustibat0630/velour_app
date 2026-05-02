import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/game_state.dart';
import '../models/skin_config.dart';
import '../services/audio_handler.dart';
import '../utils/responsive.dart';
import '../widgets/ui/dark_matte_overlay.dart';

class ShopView extends StatefulWidget {
  const ShopView({super.key});

  @override
  State<ShopView> createState() => _ShopViewState();
}

class _ShopViewState extends State<ShopView> with TickerProviderStateMixin {
  bool _busy = false;
  int? _successLux;
  int? _highlightLux;

  late final AnimationController _enter;
  late final AnimationController _highlight;
  late final AnimationController _flyCoins;
  late final AnimationController _walletBump;

  final GlobalKey _walletKey = GlobalKey();
  Offset? _flyStart;
  Offset? _flyEnd;
  Offset _lastPurchaseTapGlobal = Offset.zero;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    )..forward();
    _highlight = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _flyCoins = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    );
    _walletBump = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void dispose() {
    _enter.dispose();
    _highlight.dispose();
    _flyCoins.dispose();
    _walletBump.dispose();
    super.dispose();
  }

  Future<void> _simulatePurchase({
    required int luxAmount,
    required Offset startGlobal,
  }) async {
    if (_busy) return;
    final GameState gs = context.read<GameState>();
    setState(() {
      _busy = true;
      _successLux = null;
      _highlightLux = null;
    });

    // Laisser une frame pour le layout du portefeuille (mesure fly) — pas de faux chargement long.
    await Future<void>.delayed(const Duration(milliseconds: 48));
    if (!mounted) return;

    final RenderBox? wbox =
        _walletKey.currentContext?.findRenderObject() as RenderBox?;
    final Offset end = wbox != null
        ? wbox.localToGlobal(wbox.size.center(Offset.zero))
        : Offset(
            MediaQuery.sizeOf(context).width * 0.82,
            MediaQuery.paddingOf(context).top + 36,
          );

    setState(() {
      _flyStart = startGlobal;
      _flyEnd = end;
    });
    await _flyCoins.forward(from: 0);
    if (!mounted) return;
    setState(() {
      _flyStart = null;
    });
    _flyCoins.reset();

    gs.addLuxCoins(luxAmount);
    // Ne bloque pas l'UI sur le disque (la sync cloud est debouncée via addLuxCoins).
    unawaited(gs.flushLuxCoinsPersistence());

    if (!mounted) return;
    _walletBump.forward(from: 0);
    setState(() {
      _busy = false;
      _highlightLux = luxAmount;
      _successLux = luxAmount;
    });
    _highlight.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFFFD700);
    const Color cyan = Color(0xFF00E0ED);
    const Color violet = Color(0xFF9D50BB);
    const Color violetNeon = Color(0xFFE49BFF);

    final double s = Responsive.compactHeightScale(context);
    final double w = MediaQuery.sizeOf(context).width;
    final double h = MediaQuery.sizeOf(context).height;
    final double contentW = (w * 0.875).clamp(280.0, 560.0);
    // Respiration header : SafeArea + ~20px (responsive).
    final double headerPadTop = (h * 0.06 + 20).clamp(32.0, 64.0);
    final double listTopPad = (h * 0.18).clamp(92.0, 140.0);

    return Scaffold(
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
          const Positioned.fill(child: _LuxuryGrainLayer()),
          SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 6,
                  left: 6,
                  child: IconButton(
                    tooltip: 'Retour',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(
                      Icons.close_rounded,
                      size: 22,
                      color: Colors.white.withValues(alpha: 0.62),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 8,
                  child: AnimatedBuilder(
                    animation: _walletBump,
                    builder: (context, Widget? child) {
                      final double s =
                          1.0 + 0.12 * math.sin(_walletBump.value * math.pi);
                      return Transform.scale(
                        scale: s,
                        alignment: Alignment.center,
                        child: child,
                      );
                    },
                    child: Material(
                      key: _walletKey,
                      color: Colors.black.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.monetization_on_rounded,
                              size: 18,
                              color: gold.withValues(alpha: 0.95),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${context.watch<GameState>().luxCoins}',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white.withValues(alpha: 0.92),
                                    letterSpacing: 0.6,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding:
                        EdgeInsets.fromLTRB(16, headerPadTop, 16, 0),
                    child: SizedBox(
                      width: contentW,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 6),
                          Text(
                            'LE COFFRE-FORT',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  letterSpacing: 6,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.88),
                                  fontSize: (16 * s).clamp(14.0, 18.0),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, listTopPad, 16, 20),
                    child: SizedBox(
                      width: contentW,
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          const SizedBox(height: 6),
                          _EnterCard(
                            controller: _enter,
                            index: 0,
                            child: Padding(
                              // Laisse l'halo respirer (évite le clipping).
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 6,
                              ),
                              child: AnimatedBuilder(
                                animation: _highlight,
                                builder: (context, _) {
                                  final double ht = (_highlightLux == 100)
                                      ? Curves.easeOutCubic.transform(
                                          1 - (1 - _highlight.value),
                                        )
                                      : 0;
                                  return _ShopProductCard(
                                    accent: cyan,
                                    title: 'RÉSERVE ÉCLAT',
                                    lux: 100,
                                    price: '0,99€',
                                    badge: null,
                                    intense: false,
                                    highlightT: ht,
                                    onTapDown: (TapDownDetails d) {
                                      _lastPurchaseTapGlobal = d.globalPosition;
                                    },
                                    onTap: () {
                                      AudioHandler.instance.playMatchCombo();
                                      unawaited(_simulatePurchase(
                                        luxAmount: 100,
                                        startGlobal: _lastPurchaseTapGlobal,
                                      ));
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: (25 * s).clamp(22.0, 30.0)),
                          _EnterCard(
                            controller: _enter,
                            index: 1,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 6,
                              ),
                              child: AnimatedBuilder(
                                animation: _highlight,
                                builder: (context, _) {
                                  final double ht = (_highlightLux == 750)
                                      ? Curves.easeOutCubic.transform(
                                          1 - (1 - _highlight.value),
                                        )
                                      : 0;
                                  return _ShopProductCard(
                                    accent: gold,
                                    title: 'TRÉSOR DE L\'ORACLE',
                                    lux: 750,
                                    price: '4,99€',
                                    badge: 'MEILLEURE OFFRE',
                                    intense: true,
                                    highlightT: ht,
                                    onTapDown: (TapDownDetails d) {
                                      _lastPurchaseTapGlobal = d.globalPosition;
                                    },
                                    onTap: () {
                                      AudioHandler.instance.playMatchCombo();
                                      unawaited(_simulatePurchase(
                                        luxAmount: 750,
                                        startGlobal: _lastPurchaseTapGlobal,
                                      ));
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: (25 * s).clamp(22.0, 30.0)),
                          _EnterCard(
                            controller: _enter,
                            index: 2,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 6,
                              ),
                              child: AnimatedBuilder(
                                animation: _highlight,
                                builder: (context, _) {
                                  final double ht = (_highlightLux == 5000)
                                      ? Curves.easeOutCubic.transform(
                                          1 - (1 - _highlight.value),
                                        )
                                      : 0;
                                  return _ShopProductCard(
                                    accent: violet,
                                    title: 'L\'HÉRITAGE ROYAL',
                                    lux: 5000,
                                    price: '19,99€',
                                    badge: null,
                                    intense: true,
                                    haloColor: violetNeon,
                                    highlightT: ht,
                                    onTapDown: (TapDownDetails d) {
                                      _lastPurchaseTapGlobal = d.globalPosition;
                                    },
                                    onTap: () {
                                      AudioHandler.instance.playMatchCombo();
                                      unawaited(_simulatePurchase(
                                        luxAmount: 5000,
                                        startGlobal: _lastPurchaseTapGlobal,
                                      ));
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: (22 * s).clamp(18.0, 28.0)),
                          // Personnalisation (Forge de l'Oracle) — sous le Coffre-Fort.
                          Builder(
                            builder: (context) {
                              final GameState gs = context.watch<GameState>();
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'LA FORGE DE L\'ORACLE',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          letterSpacing: 5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white.withValues(alpha: 0.78),
                                          fontSize: (14 * s).clamp(12.0, 16.0),
                                        ),
                                  ),
                                  SizedBox(height: (12 * s).clamp(10.0, 16.0)),
                                  for (final SkinConfig skin in SkinCatalog.all)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 6,
                                      ),
                                      child: _SkinCard(
                                        skin: skin,
                                        equipped: gs.activeSkinId == skin.id,
                                        owned: gs.unlockedSkins.contains(skin.id),
                                        onTap: () => unawaited(
                                          gs.purchaseAndEquipSkin(skin),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_busy) const _VaultLoadingOverlay(),
          if (_flyStart != null && _flyEnd != null)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _flyCoins,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _ShopFlyCoinsPainter(
                        t: Curves.easeInOutCubic.transform(_flyCoins.value),
                        start: _flyStart!,
                        end: _flyEnd!,
                      ),
                    );
                  },
                ),
              ),
            ),
          if (_successLux != null)
            _PurchaseSuccessOverlay(
              addedLux: _successLux!,
              onBack: () {
                Navigator.of(context).maybePop();
              },
            ),
        ],
      ),
    );
  }
}

class _ShopProductCard extends StatelessWidget {
  const _ShopProductCard({
    required this.accent,
    required this.title,
    required this.lux,
    required this.price,
    required this.onTap,
    required this.onTapDown,
    required this.intense,
    this.badge,
    this.haloColor,
    this.highlightT = 0,
  });

  final Color accent;
  final String title;
  final int lux;
  final String price;
  final String? badge;
  final bool intense;
  final Color? haloColor;
  /// 0 → 1 : flash bordure/halo post-achat.
  final double highlightT;
  final VoidCallback onTap;
  final void Function(TapDownDetails details) onTapDown;

  static const Color _matteTop = Color(0xFF0E1014);
  static const Color _matteBottom = Color(0xFF1A1D26);

  @override
  Widget build(BuildContext context) {
    final Color neon = haloColor ?? accent;
    final double ht = highlightT.clamp(0.0, 1.0);
    final double flash = math.sin(ht * math.pi);
    final List<BoxShadow> glow = [
      BoxShadow(
        color: neon.withValues(alpha: (intense ? 0.30 : 0.18) + 0.18 * flash),
        blurRadius: (intense ? 44 : 34) + 22 * flash,
        spreadRadius: (intense ? 10 : 6) + 5 * flash,
      ),
      BoxShadow(
        color: neon.withValues(alpha: (intense ? 0.18 : 0.10) + 0.10 * flash),
        blurRadius: (intense ? 72 : 60) + 34 * flash,
        spreadRadius: 2,
      ),
    ];

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      // Ne pas clipper : permet aux halos (boxShadow) de respirer.
      clipBehavior: Clip.none,
      child: InkWell(
        onTapDown: onTapDown,
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_matteTop, _matteBottom],
            ),
            border: Border.all(
              color: Color.lerp(
                    accent.withValues(alpha: 0.6),
                    neon.withValues(alpha: 0.95),
                    flash,
                  ) ??
                  accent.withValues(alpha: 0.6),
              width: 1.2 + 0.6 * flash,
            ),
            boxShadow: glow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (badge != null) ...[
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2, right: 2),
                    child: _Badge(label: badge!, accent: accent),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      letterSpacing: 5.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                '$lux LUX',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w800,
                      color: neon.withValues(alpha: 0.96),
                      shadows: [
                        Shadow(
                          color: neon.withValues(alpha: 0.55),
                          blurRadius: 20,
                        ),
                        Shadow(
                          color: neon.withValues(alpha: 0.25),
                          blurRadius: 40,
                        ),
                      ],
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                price,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      letterSpacing: 2.2,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.68),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnterCard extends StatelessWidget {
  const _EnterCard({
    required this.controller,
    required this.index,
    required this.child,
  });

  final AnimationController controller;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double base = (index * 0.12).clamp(0.0, 0.40);
    final double end = (base + 0.72).clamp(0.0, 1.0);
    final Animation<double> t = CurvedAnimation(
      parent: controller,
      curve: Interval(base, end, curve: Curves.easeOutBack),
    );

    return AnimatedBuilder(
      animation: t,
      builder: (context, _) {
        final double v = t.value;
        final double a = v.clamp(0.0, 1.0);
        final double dy = (1 - a) * 22;
        return Opacity(
          opacity: a,
          child: Transform.translate(
            offset: Offset(0, dy),
            child: child,
          ),
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final double sT = Responsive.textScale(context);
    final Color matteGold = Color.lerp(
          accent,
          const Color(0xFFB89A2A),
          0.40,
        ) ??
        accent;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (8 * sT).clamp(7.0, 9.0),
        vertical: (2.5 * sT).clamp(2.0, 3.0),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: matteGold.withValues(alpha: 0.90),
        border: Border.all(
          color: matteGold.withValues(alpha: 0.55),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: matteGold.withValues(alpha: 0.18),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              fontSize: (9.5 * sT).clamp(9.0, 10.0),
              color: const Color(0xFF0C0C10).withValues(alpha: 0.92),
            ),
      ),
    );
  }
}

class _SkinCard extends StatelessWidget {
  const _SkinCard({
    required this.skin,
    required this.equipped,
    required this.owned,
    required this.onTap,
  });

  final SkinConfig skin;
  final bool equipped;
  final bool owned;
  final VoidCallback onTap;

  static const Color _matteTop = Color(0xFF0E1014);
  static const Color _matteBottom = Color(0xFF1A1D26);

  @override
  Widget build(BuildContext context) {
    final Color accent = skin.primaryColor;
    final Color border = equipped
        ? accent.withValues(alpha: 0.85)
        : accent.withValues(alpha: 0.45);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.none,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_matteTop, _matteBottom],
            ),
            border: Border.all(
              color: border,
              width: equipped ? 1.8 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: equipped ? 0.20 : 0.12),
                blurRadius: equipped ? 44 : 30,
                spreadRadius: equipped ? 10 : 6,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.black.withValues(alpha: 0.35),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Icon(
                  equipped ? Icons.check_rounded : Icons.auto_awesome_rounded,
                  size: 18,
                  color: accent.withValues(alpha: 0.90),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skin.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.2,
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      owned
                          ? (equipped ? 'Équipé' : 'Possédé')
                          : '${skin.price} LUX',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            letterSpacing: 1.2,
                            color: Colors.white.withValues(alpha: 0.52),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: skin.primaryColor.withValues(alpha: 0.95),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: skin.secondaryColor.withValues(alpha: 0.95),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VaultLoadingOverlay extends StatelessWidget {
  const _VaultLoadingOverlay();

  static const Color _cyan = Color(0xFF00E0ED);

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.86),
              ),
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: const Color(0xFF0E1014).withValues(alpha: 0.92),
                border: Border.all(
                  color: _cyan.withValues(alpha: 0.55),
                  width: 1.1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _cyan.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'COMMUNICATION AVEC LE COFFRE...',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          letterSpacing: 2.2,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseSuccessOverlay extends StatelessWidget {
  const _PurchaseSuccessOverlay({
    required this.addedLux,
    required this.onBack,
  });

  final int addedLux;
  final VoidCallback onBack;

  static const Color _gold = Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.86),
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: (MediaQuery.sizeOf(context).width * 0.78)
                    .clamp(280.0, 520.0),
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0E1014), Color(0xFF1A1D26)],
                  ),
                  border: Border.all(
                    color: _gold.withValues(alpha: 0.45),
                    width: 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _gold.withValues(alpha: 0.16),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 26,
                      color: _gold.withValues(alpha: 0.9),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'SUCCÈS',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            letterSpacing: 6,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.94),
                            fontSize: 18,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '+$addedLux LUX',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w800,
                            color: _gold.withValues(alpha: 0.95),
                            shadows: const [
                              Shadow(color: _gold, blurRadius: 18),
                              Shadow(color: Color(0x66FFD700), blurRadius: 34),
                            ],
                          ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: onBack,
                      style: FilledButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFF0C0C10),
                        foregroundColor: _gold.withValues(alpha: 0.94),
                        side: BorderSide(
                          color: _gold.withValues(alpha: 0.55),
                          width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'RETOUR AU JEU',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              letterSpacing: 3.0,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 10 pièces d’or animées (achat → portefeuille).
class _ShopFlyCoinsPainter extends CustomPainter {
  _ShopFlyCoinsPainter({
    required this.t,
    required this.start,
    required this.end,
  });

  final double t;
  final Offset start;
  final Offset end;

  static const int _coinCount = 10;
  static const Color _gold = Color(0xFFFFD700);

  Offset _quad(Offset a, Offset b, Offset c, double u) {
    final Offset ab = Offset.lerp(a, b, u)!;
    final Offset bc = Offset.lerp(b, c, u)!;
    return Offset.lerp(ab, bc, u)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Offset ctrl = Offset(
      (start.dx + end.dx) * 0.5,
      math.min(start.dy, end.dy) - 100,
    );
    for (int i = 0; i < _coinCount; i++) {
      final double stagger = i / (_coinCount - 1).clamp(1, 99);
      final double u =
          ((t - stagger * 0.28) / (1.0 - stagger * 0.28)).clamp(0.0, 1.0);
      final double s = u * u * (3.0 - 2.0 * u);
      final Offset p = _quad(start, ctrl, end, s);
      final double alpha = (1.0 - u * 0.92).clamp(0.0, 1.0);
      final double r = 4.0 + (1.0 - u) * 3.2;
      final Paint paint = Paint()
        ..style = PaintingStyle.fill
        ..color = _gold.withValues(alpha: 0.92 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4);
      canvas.drawCircle(p, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ShopFlyCoinsPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.start != start ||
      oldDelegate.end != end;
}

class _LuxuryGrainLayer extends StatelessWidget {
  const _LuxuryGrainLayer();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _LuxuryGrainPainter(seed: 17),
      ),
    );
  }
}

class _LuxuryGrainPainter extends CustomPainter {
  _LuxuryGrainPainter({required this.seed});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final int wq = (size.width * 2).round();
    final int hq = (size.height * 2).round();
    final math.Random r = math.Random(seed ^ (wq << 16) ^ hq);
    final int count = (size.width * size.height / 92).clamp(260, 900).toInt();
    final Paint p = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < count; i++) {
      final double x = r.nextDouble() * size.width;
      final double y = r.nextDouble() * size.height;
      final double a = 0.012 + r.nextDouble() * 0.028;
      p.color = Colors.white.withValues(alpha: a);
      canvas.drawCircle(Offset(x, y), 0.55 + r.nextDouble() * 0.55, p);
    }
  }

  @override
  bool shouldRepaint(covariant _LuxuryGrainPainter oldDelegate) =>
      oldDelegate.seed != seed;
}

