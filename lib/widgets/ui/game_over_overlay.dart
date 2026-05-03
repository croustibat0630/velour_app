import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:velour_app/l10n/app_localizations.dart';

import '../../providers/game_state.dart';
import '../../services/audio_handler.dart';
import '../../utils/responsive.dart';
import 'dark_matte_overlay.dart';
import 'menu_text_button.dart';

class GameOverOverlay extends StatefulWidget {
  const GameOverOverlay({
    super.key,
    required this.rawMatchLuxTotal,
    required this.finalLux,
    required this.finalLevel,
    required this.endedStakeKind,
    required this.prestigeMultiplier,
    required this.stakeRewardLuxCoins,
    required this.isPremiumWin,
    required this.isPersonalBest,
    required this.recordAccentColor,
    required this.onReplay,
    required this.onMenu,
    this.sessionStakeFooter = SessionStakeFooterLine.none,
    this.oracleInsuranceRefundLux = 0,
  });

  /// Somme des gains bruts (matches) avant multiplicateur prestige.
  final int rawMatchLuxTotal;

  /// Score final in‑run (somme des gains avec multiplicateur actif le cas échéant).
  final int finalLux;

  final int finalLevel;
  final SessionStakeKind endedStakeKind;

  /// `null` ou `1.0` = pas de bonus affiché ; sinon `1.5` / `3.0`.
  final double? prestigeMultiplier;

  /// LUX meta gagnés sur victoire premium (ex. 150 / 1250), sinon 0.
  final int stakeRewardLuxCoins;

  final bool isPremiumWin;
  final bool isPersonalBest;
  final Color recordAccentColor;

  final Future<void> Function() onReplay;
  final VoidCallback onMenu;
  final SessionStakeFooterLine sessionStakeFooter;

  /// Remboursement LUX d’assurance Oracle sur échec premium (0 = masqué).
  final int oracleInsuranceRefundLux;

  @override
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay>
    with TickerProviderStateMixin {
  static const Color _cyan = Color(0xFF00FFFF);
  static const Color _gold = Color(0xFFFFD700);

  late final AnimationController _in;
  late final AnimationController _badgePulse;

  @override
  void initState() {
    super.initState();
    _in = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
    _badgePulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    if (widget.oracleInsuranceRefundLux > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AudioHandler.instance.playCredit();
      });
    }
  }

  @override
  void dispose() {
    _in.dispose();
    _badgePulse.dispose();
    super.dispose();
  }

  /// Entrée en cascade du contenu (court, lisible).
  double _itemT(int i) {
    final double start = (0.055 * i).clamp(0.0, 0.34);
    final double end = (start + 0.38).clamp(0.0, 0.82);
    return Curves.easeOutCubic.transform(
      Interval(start, end).transform(_in.value),
    );
  }

  /// Les CTA apparaissent tôt : cliquables en ~0,4 s même si le joueur skip mentalement le reste.
  double _ctaT() {
    return Curves.easeOutCubic.transform(
      const Interval(0.20, 0.76).transform(_in.value),
    );
  }

  Widget _enterCta(Widget child) {
    final double t = _ctaT();
    return Opacity(
      opacity: t,
      child: Transform.translate(offset: Offset(0, (1 - t) * 10), child: child),
    );
  }

  String _title(AppLocalizations l10n) {
    if (widget.endedStakeKind == SessionStakeKind.casual) {
      return l10n.gameOverTitleSessionEnd;
    }
    if (widget.isPremiumWin) return l10n.gameOverTitleVictory;
    return l10n.gameOverTitleDefeat;
  }

  Color _titleAccent() {
    if (widget.endedStakeKind == SessionStakeKind.royal) {
      return const Color(0xFFE49BFF);
    }
    if (widget.endedStakeKind == SessionStakeKind.highStakes) {
      return _gold;
    }
    return _cyan;
  }

  bool get _showPrestige =>
      widget.prestigeMultiplier != null && widget.prestigeMultiplier! > 1.01;

  /// Multiplicateur prestige réellement reflété dans les totaux (évite doublon UI).
  bool get _showScoreFinal => widget.finalLux != widget.rawMatchLuxTotal;

  /// Quand le total matchs reste à 0 : expliciter sans accuser le joueur.
  String? _zeroMatchLuxHint(AppLocalizations l10n) {
    if (widget.rawMatchLuxTotal != 0) return null;
    if (widget.isPremiumWin) return null;
    return switch (widget.endedStakeKind) {
      SessionStakeKind.casual => l10n.gameOverZeroLuxHintCasual,
      SessionStakeKind.highStakes => l10n.gameOverZeroLuxHintHighStakes,
      SessionStakeKind.royal => l10n.gameOverZeroLuxHintRoyal,
    };
  }

  String? _resolvedSessionStakeFooter(AppLocalizations l10n) {
    return switch (widget.sessionStakeFooter) {
      SessionStakeFooterLine.none => null,
      SessionStakeFooterLine.highStakesFail =>
        l10n.gameOverFooterHighStakesFail,
      SessionStakeFooterLine.highStakesWin150Lux =>
        l10n.gameOverFooterHighStakesWin150,
      SessionStakeFooterLine.royalFail => l10n.gameOverFooterRoyalFail,
      SessionStakeFooterLine.royalWin1250Lux => l10n.gameOverFooterRoyalWin1250,
    };
  }

  bool get _sessionStakeFooterIsFailure =>
      widget.sessionStakeFooter == SessionStakeFooterLine.highStakesFail ||
      widget.sessionStakeFooter == SessionStakeFooterLine.royalFail;

  String _multLabel() {
    final double? m = widget.prestigeMultiplier;
    if (m == null) return '';
    if ((m - 1.5).abs() < 0.01) return 'x1.5';
    if ((m - 3.0).abs() < 0.01) return 'x3.0';
    return 'x${m.toStringAsFixed(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final double sH = Responsive.heightScale(context);
    final double sT = Responsive.textScale(context);
    final Color titleNeon = _titleAccent();
    final Color replayNeon = widget.endedStakeKind == SessionStakeKind.royal
        ? const Color(0xFFE49BFF)
        : widget.endedStakeKind == SessionStakeKind.highStakes
        ? _gold
        : _cyan;

    final TextStyle monoNum = GoogleFonts.robotoMono(
      fontSize: (22 * sT).clamp(18.0, 28.0),
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
      color: Colors.white.withValues(alpha: 0.92),
    );

    final TextStyle labelSmall =
        Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: (11 * sT).clamp(10.0, 13.0),
          fontWeight: FontWeight.w600,
          letterSpacing: 3.0,
          color: Colors.white.withValues(alpha: 0.42),
        ) ??
        TextStyle(
          fontSize: (11 * sT).clamp(10.0, 13.0),
          fontWeight: FontWeight.w600,
          letterSpacing: 3.0,
          color: Colors.white.withValues(alpha: 0.42),
        );

    Widget enter(int i, Widget child) {
      final double t = _itemT(i);
      return Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 10),
          child: child,
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.78),
              ),
            ),
          ),
        ),
        const Positioned.fill(child: DarkMatteOverlay()),
        SafeArea(
          child: AnimatedBuilder(
            animation: Listenable.merge([_in, _badgePulse]),
            builder: (context, _) {
              final String? footerText = _resolvedSessionStakeFooter(l10n);
              int step = 0;
              final double bottomPad =
                  (30 * sH).clamp(28.0, 44.0) +
                  MediaQuery.paddingOf(context).bottom;

              final double glow = 0.14 + 0.10 * _itemT(0);
              final TextStyle titleStyle =
                  Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontSize: (40 * sT).clamp(32.0, 52.0),
                    fontWeight: FontWeight.w200,
                    letterSpacing: 13.0,
                    height: 1.15,
                    color: titleNeon.withValues(alpha: 0.95),
                    shadows: [
                      Shadow(
                        color: titleNeon.withValues(alpha: glow * 0.85),
                        blurRadius: 9,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ) ??
                  TextStyle(
                    fontSize: (40 * sT).clamp(32.0, 52.0),
                    fontWeight: FontWeight.w200,
                    letterSpacing: 13.0,
                    height: 1.15,
                    color: titleNeon.withValues(alpha: 0.95),
                    shadows: [
                      Shadow(
                        color: titleNeon.withValues(alpha: glow * 0.85),
                        blurRadius: 9,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  );

              return LayoutBuilder(
                builder: (context, constraints) {
                  final double maxW = (constraints.maxWidth - 36)
                      .clamp(0.0, 460.0)
                      .toDouble();
                  return Align(
                    alignment: Alignment.topCenter,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        18,
                        (12 * sH).clamp(10.0, 20.0),
                        18,
                        bottomPad,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxW),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            enter(
                              step++,
                              Text(
                                _title(l10n),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: titleStyle,
                              ),
                            ),
                            SizedBox(height: 20 * sH),
                            enter(
                              step++,
                              Column(
                                children: [
                                  Text(
                                    l10n.gameOverSessionScore,
                                    textAlign: TextAlign.center,
                                    style: labelSmall,
                                  ),
                                  SizedBox(height: 6 * sH),
                                  Text(
                                    '${widget.rawMatchLuxTotal}',
                                    textAlign: TextAlign.center,
                                    style: monoNum,
                                  ),
                                  if (_zeroMatchLuxHint(l10n) != null) ...[
                                    SizedBox(height: 12 * sH),
                                    Text(
                                      _zeroMatchLuxHint(l10n)!,
                                      textAlign: TextAlign.center,
                                      maxLines: 5,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.copyWith(
                                            fontSize: (12 * sT).clamp(
                                              11.0,
                                              14.0,
                                            ),
                                            height: 1.35,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white.withValues(
                                              alpha: 0.64,
                                            ),
                                          ) ??
                                          TextStyle(
                                            fontSize: (12 * sT).clamp(
                                              11.0,
                                              14.0,
                                            ),
                                            height: 1.35,
                                            color: Colors.white.withValues(
                                              alpha: 0.64,
                                            ),
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (_showPrestige) ...[
                              SizedBox(height: 18 * sH),
                              enter(
                                step++,
                                _PrestigeBonusBadge(
                                  label: l10n.gameOverPrestigeBonus,
                                  multiplierLabel: _multLabel(),
                                  pulse: _badgePulse.value,
                                  scaleT: sT,
                                ),
                              ),
                            ],
                            if (_showScoreFinal) ...[
                              SizedBox(height: 18 * sH),
                              enter(
                                step++,
                                Column(
                                  children: [
                                    Text(
                                      l10n.gameOverFinalScore,
                                      textAlign: TextAlign.center,
                                      style: labelSmall,
                                    ),
                                    SizedBox(height: 6 * sH),
                                    Text(
                                      '${widget.finalLux}',
                                      textAlign: TextAlign.center,
                                      style: monoNum.copyWith(
                                        color: _gold.withValues(alpha: 0.95),
                                        shadows: [
                                          Shadow(
                                            color: _gold.withValues(
                                              alpha: 0.45,
                                            ),
                                            blurRadius: 18,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (widget.isPremiumWin &&
                                widget.stakeRewardLuxCoins > 0) ...[
                              SizedBox(height: 22 * sH),
                              enter(
                                step++,
                                Column(
                                  children: [
                                    Text(
                                      l10n.gameOverLuxWon,
                                      textAlign: TextAlign.center,
                                      style: labelSmall,
                                    ),
                                    SizedBox(height: 10 * sH),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.brightness_1,
                                          size: (26 * sT).clamp(22.0, 32.0),
                                          color: _gold.withValues(alpha: 0.95),
                                        ),
                                        SizedBox(width: 12 * sH),
                                        Text(
                                          '+${widget.stakeRewardLuxCoins}',
                                          style: GoogleFonts.robotoMono(
                                            fontSize: (34 * sT).clamp(
                                              26.0,
                                              44.0,
                                            ),
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.0,
                                            color: _gold.withValues(
                                              alpha: 0.98,
                                            ),
                                            shadows: const [
                                              Shadow(
                                                color: _gold,
                                                blurRadius: 26,
                                              ),
                                              Shadow(
                                                color: Color(0x88FFD700),
                                                blurRadius: 42,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (footerText != null) ...[
                              SizedBox(height: 14 * sH),
                              enter(
                                step++,
                                Text(
                                  footerText,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: labelSmall.copyWith(
                                    fontSize: (10.5 * sT).clamp(10.0, 12.5),
                                    letterSpacing: 2.0,
                                    color: _sessionStakeFooterIsFailure
                                        ? const Color(
                                            0xFFFF6B6B,
                                          ).withValues(alpha: 0.92)
                                        : _gold.withValues(alpha: 0.88),
                                  ),
                                ),
                              ),
                            ],
                            if (widget.oracleInsuranceRefundLux > 0) ...[
                              SizedBox(height: 18 * sH),
                              enter(
                                step++,
                                AnimatedBuilder(
                                  animation: _badgePulse,
                                  builder: (context, _) {
                                    final double pulse = Curves.easeInOutSine
                                        .transform(_badgePulse.value);
                                    return _OracleInsuranceRefundCallout(
                                      lux: widget.oracleInsuranceRefundLux,
                                      pulse: pulse,
                                      scaleT: sT,
                                      scaleH: sH,
                                    );
                                  },
                                ),
                              ),
                            ],
                            if (widget.isPersonalBest) ...[
                              SizedBox(height: 16 * sH),
                              enter(
                                step++,
                                Text(
                                  l10n.gameOverPersonalBest,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      Theme.of(
                                        context,
                                      ).textTheme.titleSmall?.copyWith(
                                        fontSize: (13 * sT).clamp(12.0, 16.0),
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 3.2,
                                        color: widget.recordAccentColor
                                            .withValues(alpha: 0.95),
                                        shadows: [
                                          Shadow(
                                            color: widget.recordAccentColor
                                                .withValues(alpha: 0.35),
                                            blurRadius: 18,
                                          ),
                                        ],
                                      ) ??
                                      TextStyle(
                                        fontSize: (13 * sT).clamp(12.0, 16.0),
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 3.2,
                                        color: widget.recordAccentColor,
                                      ),
                                ),
                              ),
                            ],
                            SizedBox(height: (22 * sH).clamp(16.0, 28.0)),
                            _enterCta(
                              Material(
                                color: Colors.transparent,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: (10 * sH).clamp(8.0, 14.0),
                                    vertical: (6 * sH).clamp(4.0, 8.0),
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(22),
                                    color: Colors.white.withValues(alpha: 0.10),
                                    border: Border.all(
                                      color: replayNeon.withValues(alpha: 0.55),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: replayNeon.withValues(
                                          alpha: 0.22,
                                        ),
                                        blurRadius: 14,
                                        spreadRadius: 0,
                                        offset: const Offset(0, 0),
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.35,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: MenuTextButton(
                                    label: l10n.gameOverReplay,
                                    neon: replayNeon,
                                    scale: sH,
                                    baseAlpha: 1.0,
                                    neonShadowBlur: 0,
                                    letterSpacing: 2.2,
                                    transformFilterQuality: FilterQuality.none,
                                    onPressed: () async => widget.onReplay(),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: (12 * sH).clamp(10.0, 16.0)),
                            _enterCta(
                              _SecondaryMenuTextButton(
                                label: l10n.gameOverMainMenu,
                                onPressed: widget.onMenu,
                                scale: sH,
                              ),
                            ),
                            SizedBox(height: (14 * sH).clamp(10.0, 20.0)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PrestigeBonusBadge extends StatelessWidget {
  const _PrestigeBonusBadge({
    required this.label,
    required this.multiplierLabel,
    required this.pulse,
    required this.scaleT,
  });

  final String label;
  final String multiplierLabel;
  final double pulse;
  final double scaleT;

  @override
  Widget build(BuildContext context) {
    final double s = 1.0 + 0.04 * pulse;
    return Transform.scale(
      scale: s,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: (16 * scaleT).clamp(14.0, 20.0),
          vertical: (10 * scaleT).clamp(8.0, 12.0),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: const Color(0xFF0A0C12).withValues(alpha: 0.82),
          border: Border.all(
            color: const Color(
              0xFFFFD700,
            ).withValues(alpha: 0.55 + 0.12 * pulse),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFFFFD700,
              ).withValues(alpha: 0.18 + 0.10 * pulse),
              blurRadius: 22,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: (11 * scaleT).clamp(10.0, 13.0),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                  color: Colors.white.withValues(alpha: 0.82),
                ),
              ),
            ),
            SizedBox(width: (10 * scaleT).clamp(8.0, 12.0)),
            Text(
              multiplierLabel,
              style: GoogleFonts.robotoMono(
                fontSize: (14 * scaleT).clamp(12.0, 17.0),
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: const Color(0xFFFFD700).withValues(alpha: 0.96),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OracleInsuranceRefundCallout extends StatelessWidget {
  const _OracleInsuranceRefundCallout({
    required this.lux,
    required this.pulse,
    required this.scaleT,
    required this.scaleH,
  });

  final int lux;
  final double pulse;
  final double scaleT;
  final double scaleH;

  static const Color _gold = Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final double glow = 0.72 + 0.28 * pulse;
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        (14 * scaleH).clamp(12.0, 18.0),
        16,
        (14 * scaleH).clamp(12.0, 18.0),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF0C0E16).withValues(alpha: 0.94),
        border: Border.all(
          color: _gold.withValues(alpha: 0.35 + 0.35 * pulse),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _gold.withValues(alpha: 0.18 * glow),
            blurRadius: 22 + 18 * pulse,
            spreadRadius: 1 + pulse,
          ),
          BoxShadow(
            color: _gold.withValues(alpha: 0.08 * glow),
            blurRadius: 48,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: (36 * scaleT).clamp(30.0, 44.0),
            color: _gold.withValues(alpha: 0.92),
            shadows: [
              Shadow(
                color: _gold.withValues(alpha: 0.45 * glow),
                blurRadius: 20,
              ),
            ],
          ),
          SizedBox(height: (10 * scaleH).clamp(8.0, 14.0)),
          Text(
            l10n.gameOverOracleInsuranceTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              letterSpacing: 3.6,
              fontWeight: FontWeight.w800,
              color: _gold.withValues(alpha: 0.88),
            ),
          ),
          SizedBox(height: (10 * scaleH).clamp(8.0, 12.0)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.brightness_1,
                size: (22 * scaleT).clamp(18.0, 28.0),
                color: _gold.withValues(alpha: 0.95),
              ),
              SizedBox(width: (10 * scaleH).clamp(8.0, 12.0)),
              Flexible(
                child: Text(
                  l10n.gameOverOracleInsuranceRefund(lux),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  style: GoogleFonts.robotoMono(
                    fontSize: (20 * scaleT).clamp(17.0, 26.0),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Colors.white.withValues(alpha: 0.94),
                    shadows: [
                      Shadow(
                        color: _gold.withValues(alpha: 0.35 * glow),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SecondaryMenuTextButton extends StatefulWidget {
  const _SecondaryMenuTextButton({
    required this.label,
    required this.onPressed,
    required this.scale,
  });

  final String label;
  final VoidCallback onPressed;
  final double scale;

  @override
  State<_SecondaryMenuTextButton> createState() =>
      _SecondaryMenuTextButtonState();
}

class _SecondaryMenuTextButtonState extends State<_SecondaryMenuTextButton> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final double sT = Responsive.textScale(context);
    // Lisible sur fond noir (les 0,42 d’origine passaient pour « invisibles »).
    final Color c = Colors.white.withValues(
      alpha: _hover || _down ? 0.92 : 0.78,
    );
    final double scale = (_down ? 1.03 : 1.0) * widget.scale;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
        _hover = false;
        _down = false;
      }),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          setState(() => _down = true);
        },
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: () {
          AudioHandler.instance.playMenuClick();
          widget.onPressed();
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Center(
            child: Transform.scale(
              scale: scale,
              filterQuality: FilterQuality.high,
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: (12 * sT).clamp(11.0, 14.0),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 4,
                      color: c,
                    ) ??
                    TextStyle(
                      fontSize: (12 * sT).clamp(11.0, 14.0),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 4,
                      color: c,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
