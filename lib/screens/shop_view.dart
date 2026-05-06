import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:velour_app/l10n/app_localizations.dart';

import '../providers/game_state.dart';
import '../services/audio_handler.dart';
import '../services/lux_apply_motifs.dart';
import '../services/lux_iap_service.dart';
import '../utils/responsive.dart';
import '../widgets/ui/dark_matte_overlay.dart';

class ShopView extends StatefulWidget {
  const ShopView({super.key});

  @override
  State<ShopView> createState() => _ShopViewState();
}

class _ShopViewState extends State<ShopView> with TickerProviderStateMixin {
  bool _busy = false;
  bool _vaultIapLoading = false;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(LuxIapService.instance.reloadProductsForDebug());
    });
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
    bool recordCloudPending = true,
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

    gs.addLuxCoins(
      luxAmount,
      luxCloudMotif: LuxApplyMotifs.vaultSoftCredit,
      recordCloudPending: recordCloudPending,
    );
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

  Future<void> _purchaseVaultPackWithStore({
    required BuildContext context,
    required String productId,
    required int luxAmount,
    required Offset startGlobal,
  }) async {
    if (_busy || _vaultIapLoading) return;
    _vaultIapLoading = true;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
      context,
    );
    try {
      final LuxIapBuyOutcome r = await LuxIapService.instance
          .buyVaultConsumable(productId);
      if (!mounted) return;
      switch (r.kind) {
        case LuxIapBuyKind.success:
          final int grant = r.luxAmount > 0 ? r.luxAmount : luxAmount;
          await _simulatePurchase(
            luxAmount: grant,
            startGlobal: startGlobal,
            recordCloudPending: false,
          );
          break;
        case LuxIapBuyKind.cancelled:
          messenger?.showSnackBar(
            SnackBar(content: Text(l10n.shopIapCancelled)),
          );
          break;
        case LuxIapBuyKind.unavailable:
          messenger?.showSnackBar(
            SnackBar(content: Text(l10n.shopIapUnavailable)),
          );
          break;
        case LuxIapBuyKind.productsUnavailable:
          messenger?.showSnackBar(
            SnackBar(content: Text(l10n.shopIapProductsUnavailable)),
          );
          break;
        case LuxIapBuyKind.busy:
          messenger?.showSnackBar(
            SnackBar(content: Text(l10n.shopIapError('busy'))),
          );
          break;
        case LuxIapBuyKind.error:
          if (r.errorDetail == 'offline') {
            messenger?.showSnackBar(
              SnackBar(content: Text(l10n.shopIapOffline)),
            );
            break;
          }
          messenger?.showSnackBar(
            SnackBar(
              content: Text(l10n.shopIapError(r.errorDetail ?? 'unknown')),
            ),
          );
          break;
      }
    } finally {
      await LuxIapService.instance.finalizeAfterLuxDelivered();
      if (mounted) setState(() => _vaultIapLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
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
                    tooltip: l10n.shopBackTooltip,
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
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
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
                    padding: EdgeInsets.fromLTRB(16, headerPadTop, 16, 0),
                    child: SizedBox(
                      width: contentW,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 6),
                          Text(
                            l10n.shopVaultTitle,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  letterSpacing: 3.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.9),
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
                          ValueListenableBuilder<int>(
                            valueListenable:
                                LuxIapService.instance.vaultStorePricesEpoch,
                            builder: (BuildContext context, int _, Widget? child) {
                              final LuxIapService iap = LuxIapService.instance;
                              final String price100 =
                                  iap.storePriceLabelForProduct(
                                    LuxIapProducts.sparkReserve,
                                  ) ??
                                  l10n.shopVaultPricePending;
                              final String price750 =
                                  iap.storePriceLabelForProduct(
                                    LuxIapProducts.oracleTreasure,
                                  ) ??
                                  l10n.shopVaultPricePending;
                              final String price5000 =
                                  iap.storePriceLabelForProduct(
                                    LuxIapProducts.royalLegacy,
                                  ) ??
                                  l10n.shopVaultPricePending;
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                          final double ht =
                                              (_highlightLux == 100)
                                              ? Curves.easeOutCubic.transform(
                                                  1 - (1 - _highlight.value),
                                                )
                                              : 0;
                                          return _ShopProductCard(
                                            accent: cyan,
                                            title: l10n.shopProductSparkReserve,
                                            lux: 100,
                                            price: price100,
                                            badge: null,
                                            intense: false,
                                            highlightT: ht,
                                            onTapDown: (TapDownDetails d) {
                                              _lastPurchaseTapGlobal =
                                                  d.globalPosition;
                                            },
                                            onTap: () {
                                              AudioHandler.instance
                                                  .playMenuClick();
                                              unawaited(
                                                _purchaseVaultPackWithStore(
                                                  context: context,
                                                  productId: LuxIapProducts
                                                      .sparkReserve,
                                                  luxAmount: 100,
                                                  startGlobal:
                                                      _lastPurchaseTapGlobal,
                                                ),
                                              );
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
                                          final double ht =
                                              (_highlightLux == 750)
                                              ? Curves.easeOutCubic.transform(
                                                  1 - (1 - _highlight.value),
                                                )
                                              : 0;
                                          return _ShopProductCard(
                                            accent: gold,
                                            title:
                                                l10n.shopProductOracleTreasure,
                                            lux: 750,
                                            price: price750,
                                            badge: l10n.shopBadgeBestDeal,
                                            intense: true,
                                            highlightT: ht,
                                            onTapDown: (TapDownDetails d) {
                                              _lastPurchaseTapGlobal =
                                                  d.globalPosition;
                                            },
                                            onTap: () {
                                              AudioHandler.instance
                                                  .playMenuClick();
                                              unawaited(
                                                _purchaseVaultPackWithStore(
                                                  context: context,
                                                  productId: LuxIapProducts
                                                      .oracleTreasure,
                                                  luxAmount: 750,
                                                  startGlobal:
                                                      _lastPurchaseTapGlobal,
                                                ),
                                              );
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
                                          final double ht =
                                              (_highlightLux == 5000)
                                              ? Curves.easeOutCubic.transform(
                                                  1 - (1 - _highlight.value),
                                                )
                                              : 0;
                                          return _ShopProductCard(
                                            accent: violet,
                                            title: l10n.shopProductRoyalLegacy,
                                            lux: 5000,
                                            price: price5000,
                                            badge: null,
                                            intense: true,
                                            haloColor: violetNeon,
                                            highlightT: ht,
                                            onTapDown: (TapDownDetails d) {
                                              _lastPurchaseTapGlobal =
                                                  d.globalPosition;
                                            },
                                            onTap: () {
                                              AudioHandler.instance
                                                  .playMenuClick();
                                              unawaited(
                                                _purchaseVaultPackWithStore(
                                                  context: context,
                                                  productId: LuxIapProducts
                                                      .royalLegacy,
                                                  luxAmount: 5000,
                                                  startGlobal:
                                                      _lastPurchaseTapGlobal,
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: (22 * s).clamp(18.0, 28.0)),
                                ],
                              );
                            },
                          ),
                          // Forge de l'Oracle — boosts de session (sous le Coffre-Fort).
                          Builder(
                            builder: (context) {
                              final GameState gs = context.watch<GameState>();
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    l10n.shopForgeTitle,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          letterSpacing: 5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white.withValues(
                                            alpha: 0.78,
                                          ),
                                          fontSize: (14 * s).clamp(12.0, 16.0),
                                        ),
                                  ),
                                  SizedBox(height: (12 * s).clamp(10.0, 16.0)),
                                  Text(
                                    l10n.shopForgeBoostsSection,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          letterSpacing: 3.2,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white.withValues(
                                            alpha: 0.52,
                                          ),
                                          fontSize: (11 * s).clamp(10.0, 13.0),
                                        ),
                                  ),
                                  SizedBox(height: (10 * s).clamp(8.0, 14.0)),
                                  _ShopForgeSubsectionHeader(
                                    label: l10n.shopForgeSectionRunSalvage,
                                    scale: s,
                                  ),
                                  SizedBox(height: (4 * s).clamp(2.0, 8.0)),
                                  _ForgeBoostCard(
                                    title: l10n.shopForgeChronoPulseTitle,
                                    body: l10n.shopForgeChronoPulseBody(
                                      GameState.forgeChronoPulseMaxCharges,
                                    ),
                                    priceLux:
                                        GameState.forgeChronoPulsePriceLux,
                                    accent: cyan,
                                    metaLine: l10n.shopForgeChronoPulseCharges(
                                      gs.chronoPulseCharges,
                                      GameState.forgeChronoPulseMaxCharges,
                                    ),
                                    enabled:
                                        gs.chronoPulseCharges <
                                        GameState.forgeChronoPulseMaxCharges,
                                    showStockedBadge: gs.chronoPulseCharges > 0,
                                    onTap: () async {
                                      AudioHandler.instance.playMenuClick();
                                      final ForgePurchaseOutcome r = await gs
                                          .purchaseForgeChronoPulse();
                                      if (!context.mounted) return;
                                      final AppLocalizations sl10n =
                                          AppLocalizations.of(context)!;
                                      switch (r) {
                                        case ForgePurchaseOutcome
                                            .insufficientLux:
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                sl10n.shopSnackInsufficientLux,
                                              ),
                                            ),
                                          );
                                        case ForgePurchaseOutcome
                                            .purchasedChronoPulse:
                                          break;
                                        case ForgePurchaseOutcome
                                            .chronoPulseStackFull:
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                sl10n
                                                    .shopSnackForgeChronoPulseFull,
                                              ),
                                            ),
                                          );
                                        default:
                                          break;
                                      }
                                    },
                                  ),
                                  SizedBox(height: (8 * s).clamp(6.0, 12.0)),
                                  _ForgeBoostCard(
                                    title: l10n.shopForgeMercySalvageTitle,
                                    body: l10n.shopForgeMercySalvageBody(
                                      GameState.forgeMercySalvageMaxCharges,
                                    ),
                                    priceLux:
                                        GameState.forgeMercySalvagePriceLux,
                                    accent: const Color(0xFFFF6B4A),
                                    metaLine: l10n.shopForgeMercySalvageCharges(
                                      gs.mercySalvageCharges,
                                      GameState.forgeMercySalvageMaxCharges,
                                    ),
                                    enabled:
                                        gs.mercySalvageCharges <
                                        GameState.forgeMercySalvageMaxCharges,
                                    showStockedBadge:
                                        gs.mercySalvageCharges > 0,
                                    onTap: () async {
                                      AudioHandler.instance.playMenuClick();
                                      final ForgePurchaseOutcome r = await gs
                                          .purchaseForgeMercySalvage();
                                      if (!context.mounted) return;
                                      final AppLocalizations sl10n =
                                          AppLocalizations.of(context)!;
                                      switch (r) {
                                        case ForgePurchaseOutcome
                                            .insufficientLux:
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                sl10n.shopSnackInsufficientLux,
                                              ),
                                            ),
                                          );
                                        case ForgePurchaseOutcome
                                            .purchasedMercySalvage:
                                          break;
                                        case ForgePurchaseOutcome
                                            .mercySalvageStackFull:
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                sl10n
                                                    .shopSnackForgeMercySalvageFull,
                                              ),
                                            ),
                                          );
                                        default:
                                          break;
                                      }
                                    },
                                  ),
                                  SizedBox(height: (8 * s).clamp(6.0, 12.0)),
                                  _ShopForgeSubsectionHeader(
                                    label: l10n.shopForgeSectionStrategyStakes,
                                    scale: s,
                                  ),
                                  SizedBox(height: (4 * s).clamp(2.0, 8.0)),
                                  _ForgeBoostCard(
                                    title: l10n.shopForgeInsuranceTitle,
                                    body: l10n.shopForgeInsuranceBody(
                                      GameState.highStakesAnteLux,
                                      GameState.royalAnteLux,
                                      GameState
                                          .forgeOracleInsuranceRefundPercent,
                                      GameState.forgeOracleInsuranceMaxCharges,
                                    ),
                                    priceLux:
                                        GameState.forgeOracleInsurancePriceLux,
                                    accent: const Color(0xFFFFD700),
                                    metaLine: l10n.shopForgeInsuranceCharges(
                                      gs.oracleInsuranceCharges,
                                      GameState.forgeOracleInsuranceMaxCharges,
                                    ),
                                    enabled:
                                        gs.oracleInsuranceCharges <
                                        GameState
                                            .forgeOracleInsuranceMaxCharges,
                                    showStockedBadge:
                                        gs.oracleInsuranceCharges > 0,
                                    onTap: () async {
                                      AudioHandler.instance.playMenuClick();
                                      final ForgePurchaseOutcome r = await gs
                                          .purchaseForgeOracleInsurance();
                                      if (!context.mounted) return;
                                      final AppLocalizations sl10n =
                                          AppLocalizations.of(context)!;
                                      switch (r) {
                                        case ForgePurchaseOutcome
                                            .insufficientLux:
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                sl10n.shopSnackInsufficientLux,
                                              ),
                                            ),
                                          );
                                        case ForgePurchaseOutcome
                                            .purchasedInsurance:
                                          break;
                                        case ForgePurchaseOutcome
                                            .insuranceStackFull:
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                sl10n
                                                    .shopSnackForgeInsuranceFull,
                                              ),
                                            ),
                                          );
                                        default:
                                          break;
                                      }
                                    },
                                  ),
                                  SizedBox(height: (8 * s).clamp(6.0, 12.0)),
                                  _ForgeBoostCard(
                                    title: l10n.shopForgeRoyalBountyTitle,
                                    body: l10n.shopForgeRoyalBountyBody(
                                      GameState.forgeRoyalBountyBonusLux,
                                      GameState.royalWinLux,
                                    ),
                                    priceLux:
                                        GameState.forgeRoyalBountyPriceLux,
                                    accent: const Color(0xFFE49BFF),
                                    metaLine: gs.royalVictoryBountyPending
                                        ? l10n.shopForgeRoyalBountyActive
                                        : null,
                                    enabled: !gs.royalVictoryBountyPending,
                                    showPrimeActiveBadge:
                                        gs.royalVictoryBountyPending,
                                    onTap: () async {
                                      AudioHandler.instance.playMenuClick();
                                      final ForgePurchaseOutcome r = await gs
                                          .purchaseForgeRoyalVictoryBounty();
                                      if (!context.mounted) return;
                                      final AppLocalizations sl10n =
                                          AppLocalizations.of(context)!;
                                      switch (r) {
                                        case ForgePurchaseOutcome
                                            .insufficientLux:
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                sl10n.shopSnackInsufficientLux,
                                              ),
                                            ),
                                          );
                                        case ForgePurchaseOutcome
                                            .purchasedRoyalBounty:
                                          break;
                                        case ForgePurchaseOutcome
                                            .royalBountyAlreadyActive:
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                sl10n
                                                    .shopSnackForgeRoyalBountyActive,
                                              ),
                                            ),
                                          );
                                        default:
                                          break;
                                      }
                                    },
                                  ),
                                  SizedBox(height: (16 * s).clamp(12.0, 20.0)),
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
          if (_busy || _vaultIapLoading) const _VaultLoadingOverlay(),
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
              color:
                  Color.lerp(
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
                AppLocalizations.of(context)!.shopLuxAmount(lux),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w800,
                  color: neon.withValues(alpha: 0.96),
                  shadows: [
                    Shadow(color: neon.withValues(alpha: 0.55), blurRadius: 20),
                    Shadow(color: neon.withValues(alpha: 0.25), blurRadius: 40),
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
          child: Transform.translate(offset: Offset(0, dy), child: child),
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
    final Color matteGold =
        Color.lerp(accent, const Color(0xFFB89A2A), 0.40) ?? accent;
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

class _ShopForgeSubsectionHeader extends StatelessWidget {
  const _ShopForgeSubsectionHeader({required this.label, required this.scale});

  final String label;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        letterSpacing: 2.8,
        fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.40),
        fontSize: (9.5 * scale).clamp(8.5, 11.0),
      ),
    );
  }
}

class _ForgeBoostCard extends StatelessWidget {
  const _ForgeBoostCard({
    required this.title,
    required this.body,
    required this.priceLux,
    required this.accent,
    required this.enabled,
    required this.onTap,
    this.metaLine,
    this.showStockedBadge = false,
    this.showPrimeActiveBadge = false,
  });

  final String title;
  final String body;
  final int priceLux;
  final Color accent;
  final bool enabled;
  final VoidCallback onTap;
  final String? metaLine;

  /// Au moins une charge d’assurance en poche (icône + halo).
  final bool showStockedBadge;

  /// Prime royale active (icône + halo).
  final bool showPrimeActiveBadge;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final List<BoxShadow> glow = (showStockedBadge || showPrimeActiveBadge)
        ? <BoxShadow>[
            BoxShadow(
              color: accent.withValues(alpha: 0.22),
              blurRadius: 20,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: accent.withValues(alpha: 0.10),
              blurRadius: 40,
              spreadRadius: 2,
            ),
          ]
        : const <BoxShadow>[];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF0A0C12,
                  ).withValues(alpha: enabled ? 0.88 : 0.52),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: accent.withValues(
                      alpha: (showStockedBadge || showPrimeActiveBadge)
                          ? 0.58
                          : (enabled ? 0.42 : 0.18),
                    ),
                    width: (showStockedBadge || showPrimeActiveBadge)
                        ? 1.35
                        : 1,
                  ),
                  boxShadow: glow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  letterSpacing: 2.4,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white.withValues(alpha: 0.90),
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.shopPriceLux(priceLux),
                          textAlign: TextAlign.right,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: accent.withValues(
                                  alpha: enabled ? 0.95 : 0.45,
                                ),
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      body,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.35,
                        color: Colors.white.withValues(
                          alpha: enabled ? 0.52 : 0.38,
                        ),
                      ),
                    ),
                    if (metaLine != null && metaLine!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        metaLine!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              letterSpacing: 1.6,
                              fontWeight: FontWeight.w700,
                              color: accent.withValues(
                                alpha: enabled ? 0.72 : 0.40,
                              ),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (showStockedBadge || showPrimeActiveBadge)
                Positioned(
                  top: 4,
                  right: 6,
                  child: Icon(
                    Icons.verified_rounded,
                    size: 22,
                    color: accent.withValues(alpha: 0.95),
                    shadows: [
                      Shadow(
                        color: accent.withValues(alpha: 0.45),
                        blurRadius: 10,
                      ),
                    ],
                  ),
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
                    AppLocalizations.of(context)!.shopVaultLoading,
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
  const _PurchaseSuccessOverlay({required this.addedLux, required this.onBack});

  final int addedLux;
  final VoidCallback onBack;

  static const Color _gold = Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
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
                maxWidth: (MediaQuery.sizeOf(context).width * 0.78).clamp(
                  280.0,
                  520.0,
                ),
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
                      l10n.shopPurchaseSuccess,
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
                      l10n.shopPurchaseLuxAdded(addedLux),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
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
                        l10n.shopBackToGame,
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
      final double u = ((t - stagger * 0.28) / (1.0 - stagger * 0.28)).clamp(
        0.0,
        1.0,
      );
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
      child: CustomPaint(painter: _LuxuryGrainPainter(seed: 17)),
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
