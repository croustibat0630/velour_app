import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:velour_app/l10n/app_localizations.dart';

import '../providers/game_state.dart';
import '../services/audio_handler.dart';
import '../services/velour_analytics.dart';
import '../theme/theme_engine.dart';
import '../utils/responsive.dart';
import '../utils/velour_accessibility.dart';
import '../utils/velour_route_observer.dart';
import '../widgets/ui/dark_matte_overlay.dart';
import '../widgets/ui/universal_back_button.dart';
import '../widgets/ui/lux_score_displayer.dart';
import 'game_screen.dart';

Route<void> fadeRoute(Widget child) {
  return PageRouteBuilder<void>(
    pageBuilder: (_, _, _) => child,
    transitionDuration: const Duration(milliseconds: 380),
    transitionsBuilder: (_, animation, _, c) =>
        FadeTransition(opacity: animation, child: c),
  );
}

class PreparationView extends StatefulWidget {
  const PreparationView({
    super.key,
    this.initialStake,
    this.casualStakeOnly = false,
  });

  /// Pré-sélectionne une mise (ex. « Rejouer » depuis l’écran de fin).
  final SessionStakeKind? initialStake;

  /// Tutoriel (menu) : uniquement le mode casual — pas d’autres mises sur cet écran.
  final bool casualStakeOnly;

  @override
  State<PreparationView> createState() => _PreparationViewState();
}

class _PreparationViewState extends State<PreparationView> with RouteAware {
  bool _stakeBeginError = false;
  SessionStakeKind? _selectedStake;
  int? _overrideInitialValue;
  GameState? _listenedGs;

  void _onGameStateChanged() {
    // If LUX was credited while this screen is visible (e.g. welcome gift),
    // animate the footer counter the same way as on the main menu.
    if (!mounted) return;
    _syncPendingLuxJuiceIfAny();
  }

  @override
  void initState() {
    super.initState();
    if (widget.casualStakeOnly) {
      _selectedStake = SessionStakeKind.casual;
    } else if (widget.initialStake != null) {
      _selectedStake = widget.initialStake;
    }
    // RouteAware callbacks can be missed if subscription happens after the push;
    // this guarantees the first frame consumes any pending LUX juice.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncPendingLuxJuiceIfAny();
    });
    VelourAnalytics.logPrepOpen(stakeKind: _selectedStake?.name ?? 'unset');
  }

  @override
  void dispose() {
    velourRouteObserver.unsubscribe(this);
    _listenedGs?.removeListener(_onGameStateChanged);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final GameState gs = context.read<GameState>();
    if (!identical(_listenedGs, gs)) {
      _listenedGs?.removeListener(_onGameStateChanged);
      _listenedGs = gs;
      _listenedGs!.addListener(_onGameStateChanged);
    }
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
    if (!juice.silent) {
      try {
        AudioHandler.instance.playCredit();
        HapticFeedback.heavyImpact();
      } catch (_) {}
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _overrideInitialValue = null;
    });
  }

  @override
  void didPopNext() {
    _syncPendingLuxJuiceIfAny();
  }

  @override
  void didPush() {
    _syncPendingLuxJuiceIfAny();
  }

  static bool _canAffordStake(GameState gs, SessionStakeKind stake) {
    switch (stake) {
      case SessionStakeKind.casual:
        return true;
      case SessionStakeKind.highStakes:
        return gs.luxCoins >= GameState.highStakesAnteLux;
      case SessionStakeKind.royal:
        return gs.luxCoins >= GameState.royalAnteLux;
    }
  }

  Future<void> _launchGame(SessionStakeKind stake) async {
    setState(() => _stakeBeginError = false);
    final GameState gs = context.read<GameState>();
    if (!await gs.consumeStake(stake)) {
      setState(() => _stakeBeginError = true);
      return;
    }
    await HapticFeedback.mediumImpact();
    await AudioHandler.instance.stopMusic();
    if (!mounted) return;
    gs.startNewRun();
    VelourAnalytics.logPrepLaunchConfirmed(
      stakeKind: stake.name,
      runInstanceId: gs.analyticsRunInstanceId,
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(fadeRoute(const GameScreen()));
  }

  void _selectStake(SessionStakeKind stake) {
    if (widget.casualStakeOnly && stake != SessionStakeKind.casual) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _selectedStake = stake;
      _stakeBeginError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ThemeEngine te = context.watch<ThemeEngine>();
    final GameState gs = context.watch<GameState>();
    final double scaleH = Responsive.compactHeightScale(context);
    const Color gold = Color(0xFFFFD700);
    const Color royalViolet = Color(0xFF9D50BB);

    return Scaffold(
      body: RepaintBoundary(
        child: Stack(
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
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: UniversalBackButton(),
                    ),
                    SizedBox(height: 8 * scaleH),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        widget.casualStakeOnly
                            ? l10n.menuGuidedTutorial
                            : l10n.prepTitle,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              letterSpacing: 3,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.78),
                            ),
                      ),
                    ),
                    if (widget.casualStakeOnly) ...[
                      SizedBox(height: 8 * scaleH),
                      Text(
                        l10n.prepGuidedTutorialCasualOnly,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          height: 1.35,
                          letterSpacing: 0.6,
                          color: Colors.white.withValues(alpha: 0.48),
                        ),
                      ),
                    ],
                    SizedBox(height: 18 * scaleH),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, cons) {
                          final double gap = (26 * scaleH).clamp(20.0, 30.0);
                          // ~87,5 % de la largeur (cible 85–90 %).
                          final double cardW = cons.maxWidth * 0.875;
                          final double availH = cons.maxHeight;
                          final int cardCount = widget.casualStakeOnly ? 1 : 3;
                          final int gapCount = math.max(0, cardCount - 1);
                          double cardH = (availH - gap * gapCount) / cardCount;
                          final double minCardH = 148.0;
                          final double maxCardH = 280.0;
                          if (widget.casualStakeOnly) {
                            cardH = cardH.clamp(minCardH, maxCardH * 1.15);
                          } else if (cardH >= minCardH) {
                            cardH = cardH.clamp(minCardH, maxCardH);
                          } else {
                            cardH = minCardH;
                          }
                          const double outerCardPadV = 6;
                          final double contentH =
                              cardH * cardCount +
                              gap * gapCount +
                              outerCardPadV * 2 * cardCount;
                          final bool scroll =
                              widget.casualStakeOnly || contentH > availH + 0.5;

                          Widget stakeCard(_LuxuryModeCard child) => Center(
                            child: Padding(
                              // Laisse respirer les halos des cartes.
                              padding: EdgeInsets.symmetric(
                                vertical: scroll ? outerCardPadV : 0,
                              ),
                              child: SizedBox(
                                width: cardW,
                                height: cardH,
                                child: child,
                              ),
                            ),
                          );

                          final Widget casualModeCard = stakeCard(
                            _LuxuryModeCard(
                              title: l10n.prepModeCasualTitle,
                              titleColor: te.colorForId(1),
                              body: l10n.prepModeCasualBody(0),
                              selectedChipLabel: l10n.prepSelectedChip,
                              mode: SessionStakeKind.casual,
                              hasSelection: _selectedStake != null,
                              selected:
                                  _selectedStake == SessionStakeKind.casual,
                              enabled: true,
                              errorText: null,
                              onSelect: () =>
                                  _selectStake(SessionStakeKind.casual),
                            ),
                          );

                          if (widget.casualStakeOnly) {
                            return ListView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 12),
                              children: <Widget>[
                                _GuidedTutorialStrategySection(
                                  scaleH: scaleH,
                                  maxWidth: cons.maxWidth,
                                ),
                                SizedBox(height: gap * 0.75),
                                casualModeCard,
                              ],
                            );
                          }

                          final List<Widget> stack = <Widget>[
                            casualModeCard,
                            SizedBox(height: gap),
                            stakeCard(
                              _LuxuryModeCard(
                                title: l10n.prepModeHighStakesTitle,
                                titleColor: gold,
                                body: l10n.prepModeHighStakesBody(
                                  GameState.highStakesAnteLux,
                                  GameState.highStakesTargetLevel,
                                  GameState.highStakesWinLux,
                                ),
                                selectedChipLabel: l10n.prepSelectedChip,
                                mode: SessionStakeKind.highStakes,
                                hasSelection: _selectedStake != null,
                                selected:
                                    _selectedStake ==
                                    SessionStakeKind.highStakes,
                                enabled: true,
                                errorText:
                                    _stakeBeginError &&
                                        _selectedStake ==
                                            SessionStakeKind.highStakes
                                    ? l10n.prepInsufficientLux
                                    : null,
                                onSelect: () =>
                                    _selectStake(SessionStakeKind.highStakes),
                              ),
                            ),
                            SizedBox(height: gap),
                            stakeCard(
                              _LuxuryModeCard(
                                title: l10n.prepModeRoyalTitle,
                                titleColor: royalViolet,
                                body: l10n.prepModeRoyalBody(
                                  GameState.royalAnteLux,
                                  GameState.royalTargetLevel,
                                  GameState.royalWinLux,
                                ),
                                selectedChipLabel: l10n.prepSelectedChip,
                                mode: SessionStakeKind.royal,
                                hasSelection: _selectedStake != null,
                                selected:
                                    _selectedStake == SessionStakeKind.royal,
                                enabled: true,
                                errorText:
                                    _stakeBeginError &&
                                        _selectedStake == SessionStakeKind.royal
                                    ? l10n.prepInsufficientLux
                                    : null,
                                onSelect: () =>
                                    _selectStake(SessionStakeKind.royal),
                              ),
                            ),
                          ];

                          if (scroll) {
                            return ListView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 8),
                              children: stack,
                            );
                          }
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: stack,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Material(
        color: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.0),
                Colors.black.withValues(alpha: 0.78),
              ],
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: RepaintBoundary(
                      child: LuxScoreDisplayer(
                        lux: gs.luxCoins,
                        initialValue: _overrideInitialValue,
                        color: gold,
                        prefix: l10n.prepLuxScoreCaption,
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: Duration(
                      milliseconds: velourReduceMotion(context) ? 0 : 220,
                    ),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: _selectedStake == null
                        ? SizedBox(key: const ValueKey('no'), height: 8)
                        : Padding(
                            key: ValueKey(
                              'cta_${_selectedStake}_${gs.luxCoins}',
                            ),
                            padding: EdgeInsets.only(top: 12 * scaleH),
                            child: _canAffordStake(gs, _selectedStake!)
                                ? _ConfirmSessionButton(
                                    scale: scaleH,
                                    label: l10n.prepConfirm,
                                    accent:
                                        _selectedStake ==
                                            SessionStakeKind.highStakes
                                        ? gold
                                        : _selectedStake ==
                                              SessionStakeKind.royal
                                        ? royalViolet
                                        : te.colorForId(1),
                                    onPressed: () =>
                                        _launchGame(_selectedStake!),
                                  )
                                : _BuyLuxButton(
                                    scale: scaleH,
                                    label: l10n.prepBuyLux,
                                    onPressed: () {
                                      Navigator.of(context).pushNamed('/shop');
                                    },
                                  ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfirmSessionButton extends StatelessWidget {
  const _ConfirmSessionButton({
    required this.scale,
    required this.label,
    required this.accent,
    required this.onPressed,
  });

  final double scale;
  final String label;
  final Color accent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: 16 * scale, horizontal: 20),
          backgroundColor: const Color(0xFF0C0C10),
          foregroundColor: accent.withValues(alpha: 0.95),
          side: BorderSide(color: accent.withValues(alpha: 0.55), width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: 12 * scale,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _BuyLuxButton extends StatelessWidget {
  const _BuyLuxButton({
    required this.scale,
    required this.label,
    required this.onPressed,
  });

  final double scale;
  final String label;
  final VoidCallback onPressed;

  static const Color _violet = Color(0xFF9D50BB);
  static const Color _neon = Color(0xFFE49BFF);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: 16 * scale, horizontal: 18),
          backgroundColor: const Color(0xFF120818),
          foregroundColor: _neon.withValues(alpha: 0.96),
          side: BorderSide(color: _violet.withValues(alpha: 0.65), width: 1.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: 11.5 * scale,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.2,
            ),
          ),
        ),
      ),
    );
  }
}

/// Texte pédagogique avant la carte mode classique (tutoriel depuis le menu).
class _GuidedTutorialStrategySection extends StatelessWidget {
  const _GuidedTutorialStrategySection({
    required this.scaleH,
    required this.maxWidth,
  });

  final double scaleH;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final double hPad = (10 * scaleH).clamp(8.0, 14.0);
    const Color gold = Color(0xFFFFD700);

    Widget section(String title, String body) {
      return Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth * 0.94),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w700,
                  color: gold.withValues(alpha: 0.88),
                  fontSize: (11 * scaleH).clamp(10.0, 13.0),
                ),
              ),
              SizedBox(height: (6 * scaleH).clamp(5.0, 9.0)),
              Text(
                body,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  height: 1.42,
                  letterSpacing: 0.35,
                  color: Colors.white.withValues(alpha: 0.58),
                  fontSize: (12 * scaleH).clamp(11.0, 14.0),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0C12).withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            (12 * scaleH).clamp(10.0, 16.0),
            (14 * scaleH).clamp(12.0, 18.0),
            (12 * scaleH).clamp(10.0, 16.0),
            (14 * scaleH).clamp(12.0, 18.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              section(
                l10n.prepGuidedTutorialGoalTitle,
                l10n.prepGuidedTutorialGoalBody,
              ),
              SizedBox(height: (16 * scaleH).clamp(14.0, 22.0)),
              section(
                l10n.prepGuidedTutorialStrategyTitle,
                l10n.prepGuidedTutorialStrategyBody,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LuxuryModeCard extends StatelessWidget {
  const _LuxuryModeCard({
    required this.title,
    required this.titleColor,
    required this.body,
    required this.selectedChipLabel,
    required this.mode,
    required this.hasSelection,
    required this.selected,
    required this.enabled,
    required this.errorText,
    required this.onSelect,
  });

  final String title;
  final Color titleColor;
  final String body;
  final String selectedChipLabel;
  final SessionStakeKind mode;
  final bool hasSelection;
  final bool selected;
  final bool enabled;
  final String? errorText;
  final VoidCallback? onSelect;

  static const Color _matteTop = Color(0xFF060608);
  static const Color _matteBottom = Color(0xFF15171E);

  /// Fond carte sélectionnée : gris très sombre (plus clair que le noir mat).
  static const Color _matteLitTop = Color(0xFF1E222C);
  static const Color _matteLitBottom = Color(0xFF323844);

  static const Color _cyanPure = Color(0xFF00FFFF);
  static const Color _cyanDeep = Color(0xFF00C8E8);
  static const Color _goldPure = Color(0xFFFFD700);
  static const Color _goldDeep = Color(0xFFFFC400);
  static const Color _royalPure = Color(0xFF9D50BB);
  static const Color _royalDeep = Color(0xFF6E48AA);
  static const Color _royalNeon = Color(0xFFE49BFF);

  Color get _accentBorder {
    switch (mode) {
      case SessionStakeKind.casual:
        return Colors.white.withValues(alpha: 0.18);
      case SessionStakeKind.highStakes:
        return _goldPure;
      case SessionStakeKind.royal:
        return _royalPure.withValues(alpha: 0.52);
    }
  }

  int get _grainSeed {
    switch (mode) {
      case SessionStakeKind.casual:
        return 3;
      case SessionStakeKind.highStakes:
        return 7;
      case SessionStakeKind.royal:
        return 11;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool rm = velourReduceMotion(context);
    final bool tappable = enabled && onSelect != null;
    final bool muted = hasSelection && !selected && enabled;
    final bool lit = selected && enabled;

    final double outerOpacity = !enabled ? 0.46 : (muted ? 0.4 : 1.0);

    final Color glyphColor = switch (mode) {
      SessionStakeKind.casual => titleColor,
      SessionStakeKind.highStakes => _goldPure,
      SessionStakeKind.royal => _royalPure,
    };
    final Color accentNeon = switch (mode) {
      SessionStakeKind.casual => _cyanPure,
      SessionStakeKind.highStakes => _goldPure,
      SessionStakeKind.royal => _royalNeon,
    };

    final List<BoxShadow> idlePremiumGlow = <BoxShadow>[
      if (enabled && mode == SessionStakeKind.highStakes && !hasSelection)
        BoxShadow(
          color: _goldPure.withValues(alpha: 0.10),
          blurRadius: 22,
          spreadRadius: 0.4,
        ),
      if (enabled && mode == SessionStakeKind.royal && !hasSelection)
        BoxShadow(
          color: _royalPure.withValues(alpha: 0.14),
          blurRadius: 26,
          spreadRadius: 0.55,
        ),
    ];

    final Widget modeGlyph = switch (mode) {
      SessionStakeKind.casual => _ClassicGlyph(color: glyphColor, bright: lit),
      SessionStakeKind.highStakes => _HighStakesGlyph(
        color: glyphColor,
        dim: !enabled,
        bright: lit,
      ),
      SessionStakeKind.royal => _RoyalDiamondGlyph(
        color: glyphColor,
        dim: !enabled,
        bright: lit,
      ),
    };

    final Widget innerContent = Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: lit ? 0.18 : 0.12,
              child: CustomPaint(painter: _MatteGrainPainter(seed: _grainSeed)),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _InnerShadowPainter(
                radius: 18,
                strength: lit ? 0.34 : 0.26,
              ),
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, c) {
            // Anti-overflow : si la carte devient trop basse (petit device / split),
            // on réduit l'ensemble de manière élégante au lieu de déborder.
            return Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: SizedBox(
                  width: c.maxWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                        child: AnimatedScale(
                          scale: lit ? 1.22 : 1.0,
                          duration: Duration(
                            milliseconds: rm ? 0 : (lit ? 620 : 180),
                          ),
                          curve: lit ? Curves.elasticOut : Curves.easeOutCubic,
                          child: AnimatedOpacity(
                            duration: Duration(milliseconds: rm ? 0 : 150),
                            curve: Curves.linear,
                            opacity: lit ? 1.0 : (muted ? 0.75 : 0.82),
                            child: modeGlyph,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              letterSpacing: title.length > 18 ? 3.2 : 5.0,
                              fontWeight: FontWeight.w600,
                              color: titleColor.withValues(
                                alpha: lit ? 1.0 : (muted ? 0.45 : 0.95),
                              ),
                            ),
                      ),
                      if (lit) ...[
                        const SizedBox(height: 6),
                        Text(
                          selectedChipLabel,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.6,
                                color: accentNeon.withValues(alpha: 0.92),
                                shadows: [
                                  Shadow(
                                    color: accentNeon.withValues(alpha: 0.55),
                                    blurRadius: 10,
                                  ),
                                  Shadow(
                                    color: accentNeon.withValues(alpha: 0.25),
                                    blurRadius: 22,
                                  ),
                                ],
                              ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        body,
                        textAlign: TextAlign.center,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.48,
                          letterSpacing: 0.65,
                          color: Colors.white.withValues(
                            alpha: lit ? 0.72 : (muted ? 0.38 : 0.64),
                          ),
                        ),
                      ),
                      if (errorText != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          errorText!,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: const Color(
                                  0xFFFF6B6B,
                                ).withValues(alpha: 0.94),
                                letterSpacing: 0.5,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );

    final List<Color> litStrokeColors = switch (mode) {
      SessionStakeKind.casual => const [_cyanPure, _cyanDeep],
      SessionStakeKind.highStakes => const [_goldPure, _goldDeep],
      SessionStakeKind.royal => const [_royalPure, _royalDeep],
    };

    // Responsive: keep halos sane on tablets (avoid gigantic blur/spread).
    final double halo = Responsive.heightScale(context).clamp(0.9, 1.05);
    double br(double v) => (v * halo).clamp(v * 0.9, v * 1.15);
    double sr(double v) => (v * halo).clamp(v * 0.85, v * 1.10);

    final List<BoxShadow> litGlowShadows = switch (mode) {
      SessionStakeKind.casual => <BoxShadow>[
        BoxShadow(
          color: accentNeon.withValues(alpha: 0.55),
          blurRadius: br(30),
          spreadRadius: sr(15),
        ),
        BoxShadow(
          color: accentNeon.withValues(alpha: 0.28),
          blurRadius: br(52),
          spreadRadius: sr(4),
        ),
        BoxShadow(
          color: accentNeon.withValues(alpha: 0.14),
          blurRadius: br(72),
          spreadRadius: sr(2),
        ),
      ],
      SessionStakeKind.highStakes => <BoxShadow>[
        BoxShadow(
          color: accentNeon.withValues(alpha: 0.55),
          blurRadius: br(30),
          spreadRadius: sr(15),
        ),
        BoxShadow(
          color: accentNeon.withValues(alpha: 0.28),
          blurRadius: br(52),
          spreadRadius: sr(4),
        ),
        BoxShadow(
          color: accentNeon.withValues(alpha: 0.16),
          blurRadius: br(72),
          spreadRadius: sr(2),
        ),
      ],
      SessionStakeKind.royal => <BoxShadow>[
        BoxShadow(
          color: _royalNeon.withValues(alpha: 0.62),
          blurRadius: br(36),
          spreadRadius: sr(18),
        ),
        BoxShadow(
          color: _royalPure.withValues(alpha: 0.36),
          blurRadius: br(58),
          spreadRadius: sr(6),
        ),
        BoxShadow(
          color: _royalNeon.withValues(alpha: 0.22),
          blurRadius: br(78),
          spreadRadius: sr(3),
        ),
      ],
    };

    final Widget cardBody = lit
        ? Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: litStrokeColors,
              ),
              boxShadow: litGlowShadows,
            ),
            padding: const EdgeInsets.all(3),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_matteLitTop, _matteLitBottom],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(13, 13, 13, 11),
                child: innerContent,
              ),
            ),
          )
        : AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_matteTop, _matteBottom],
              ),
              border: Border.all(
                color: muted
                    ? Colors.white.withValues(alpha: 0.10)
                    : _accentBorder.withValues(alpha: enabled ? 0.22 : 0.28),
                width: 1,
              ),
              boxShadow: muted || idlePremiumGlow.isEmpty
                  ? null
                  : idlePremiumGlow,
            ),
            child: innerContent,
          );

    final String modeA11yLabel = <String>[
      title,
      body,
      ?errorText,
      if (selected) selectedChipLabel,
    ].join('. ');

    return Semantics(
      container: true,
      button: tappable,
      enabled: enabled,
      selected: selected,
      label: modeA11yLabel,
      excludeSemantics: true,
      child: AnimatedOpacity(
        opacity: outerOpacity,
        duration: Duration(milliseconds: rm ? 0 : 150),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: tappable ? () => onSelect!() : null,
            borderRadius: BorderRadius.circular(18),
            splashColor: titleColor.withValues(alpha: lit ? 0.18 : 0.10),
            highlightColor: titleColor.withValues(alpha: lit ? 0.10 : 0.05),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              child: cardBody,
            ),
          ),
        ),
      ),
    );
  }
}

class _MatteGrainPainter extends CustomPainter {
  _MatteGrainPainter({required this.seed});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    // Deterministic grain: depends only on seed + quantized size.
    // This prevents any “moving noise” sensation during animations.
    final int wq = (size.width * 2).round(); // 0.5px buckets
    final int hq = (size.height * 2).round();
    final math.Random r = math.Random(seed ^ (wq << 16) ^ hq);
    final int count = (size.width * size.height / 80).clamp(220, 900).toInt();
    final Paint p = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final double x = r.nextDouble() * size.width;
      final double y = r.nextDouble() * size.height;
      final double a = 0.015 + r.nextDouble() * 0.03;
      p.color = Colors.white.withValues(alpha: a);
      canvas.drawCircle(Offset(x, y), 0.55 + r.nextDouble() * 0.45, p);
    }
  }

  @override
  bool shouldRepaint(covariant _MatteGrainPainter oldDelegate) =>
      oldDelegate.seed != seed;
}

class _InnerShadowPainter extends CustomPainter {
  _InnerShadowPainter({required this.radius, required this.strength});

  final double radius;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final RRect rr = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    // Top-left highlight (soft)
    final Paint light = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.center,
        colors: [Color(0x26FFFFFF), Color(0x00FFFFFF)],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(rr, light);

    // Inner shadow: draw a bigger rect and cut the inside (even-odd)
    final Rect outer = Rect.fromLTWH(
      -40,
      -40,
      size.width + 80,
      size.height + 80,
    );
    final Path cut = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(outer)
      ..addRRect(rr);

    final Paint shadow = Paint()
      ..color = Colors.black.withValues(alpha: strength)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawPath(cut, shadow);
  }

  @override
  bool shouldRepaint(covariant _InnerShadowPainter oldDelegate) =>
      oldDelegate.strength != strength || oldDelegate.radius != radius;
}

/// Hexagone minimaliste (contour fin).
class _ClassicGlyph extends StatelessWidget {
  const _ClassicGlyph({required this.color, required this.bright});

  final Color color;
  final bool bright;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: CustomPaint(
        painter: _HexOutlinePainter(
          color: color.withValues(alpha: bright ? 0.98 : 0.82),
          bright: bright,
        ),
      ),
    );
  }
}

class _HexOutlinePainter extends CustomPainter {
  _HexOutlinePainter({required this.color, required this.bright});

  final Color color;
  final bool bright;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = Offset(size.width / 2, size.height / 2);
    final double r = size.shortestSide * 0.42;
    final Path path = Path();
    for (int i = 0; i < 6; i++) {
      final double a = (i * 60 - 90) * math.pi / 180;
      final Offset p = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.35;
    canvas.drawPath(path, paint);

    if (bright) {
      final Paint glow = Paint()
        ..color = color.withValues(alpha: 0.20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.35
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawPath(path, glow);
    }
  }

  @override
  bool shouldRepaint(covariant _HexOutlinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.bright != bright;
}

/// Couronne stylisée (or).
class _HighStakesGlyph extends StatelessWidget {
  const _HighStakesGlyph({
    required this.color,
    this.dim = false,
    this.bright = false,
  });

  final Color color;
  final bool dim;
  final bool bright;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 44,
      child: CustomPaint(
        painter: _CrownPainter(
          color: color.withValues(alpha: dim ? 0.38 : (bright ? 0.98 : 0.90)),
          bright: bright && !dim,
        ),
      ),
    );
  }
}

class _CrownPainter extends CustomPainter {
  _CrownPainter({required this.color, required this.bright});

  final Color color;
  final bool bright;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Path path = Path()
      ..moveTo(w * 0.08, h * 0.72)
      ..lineTo(w * 0.12, h * 0.38)
      ..lineTo(w * 0.28, h * 0.52)
      ..lineTo(w * 0.5, h * 0.12)
      ..lineTo(w * 0.72, h * 0.52)
      ..lineTo(w * 0.88, h * 0.38)
      ..lineTo(w * 0.92, h * 0.72)
      ..close();

    final Paint fill = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.45
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);

    if (bright) {
      final Paint glow = Paint()
        ..color = color.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.45
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawPath(path, glow);
    }
  }

  @override
  bool shouldRepaint(covariant _CrownPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.bright != bright;
}

/// Diamant stylisé (néon royal).
class _RoyalDiamondGlyph extends StatelessWidget {
  const _RoyalDiamondGlyph({
    required this.color,
    this.dim = false,
    this.bright = false,
  });

  final Color color;
  final bool dim;
  final bool bright;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 46,
      child: CustomPaint(
        painter: _RoyalDiamondPainter(
          color: color.withValues(alpha: dim ? 0.38 : (bright ? 0.98 : 0.88)),
          bright: bright && !dim,
        ),
      ),
    );
  }
}

class _RoyalDiamondPainter extends CustomPainter {
  _RoyalDiamondPainter({required this.color, required this.bright});

  final Color color;
  final bool bright;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double w = size.shortestSide * 0.36;
    final Path outer = Path()
      ..moveTo(c.dx, c.dy - w)
      ..lineTo(c.dx + w * 0.92, c.dy)
      ..lineTo(c.dx, c.dy + w * 0.95)
      ..lineTo(c.dx - w * 0.92, c.dy)
      ..close();

    final Path facet = Path()
      ..moveTo(c.dx, c.dy - w * 0.55)
      ..lineTo(c.dx + w * 0.42, c.dy)
      ..lineTo(c.dx, c.dy + w * 0.48)
      ..lineTo(c.dx - w * 0.42, c.dy)
      ..close();

    final Paint fill = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeJoin = StrokeJoin.miter;

    canvas.drawPath(outer, fill);
    canvas.drawPath(outer, stroke);
    canvas.drawPath(
      facet,
      Paint()
        ..color = color.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );

    if (bright) {
      final Paint glow = Paint()
        ..color = color.withValues(alpha: 0.26)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeJoin = StrokeJoin.miter
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 11);
      canvas.drawPath(outer, glow);
    }
  }

  @override
  bool shouldRepaint(covariant _RoyalDiamondPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.bright != bright;
}
