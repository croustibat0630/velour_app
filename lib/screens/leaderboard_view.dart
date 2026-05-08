import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:velour_app/l10n/app_localizations.dart';

import '../game/oracle_pseudo.dart';
import '../providers/game_state.dart';
import '../services/firestore_service.dart';
import '../theme/theme_engine.dart';
import '../utils/responsive.dart';
import '../widgets/ui/dark_matte_overlay.dart';
import '../widgets/ui/universal_back_button.dart';

int _docHighScore(QueryDocumentSnapshot<Map<String, dynamic>> d) =>
    (d.data()['highScore'] as num?)?.toInt() ?? 0;

/// Tri client `highScore` ↓ puis `documentId` ↑ (filet de sécurité si l’ordre snapshot diverge).
List<QueryDocumentSnapshot<Map<String, dynamic>>> sortedLeaderboardDocs(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> raw,
) {
  if (raw.length <= 1) return raw;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> out =
      List<QueryDocumentSnapshot<Map<String, dynamic>>>.of(raw);
  out.sort((
    QueryDocumentSnapshot<Map<String, dynamic>> a,
    QueryDocumentSnapshot<Map<String, dynamic>> b,
  ) {
    final int c = _docHighScore(b).compareTo(_docHighScore(a));
    if (c != 0) return c;
    return a.id.compareTo(b.id);
  });
  return out;
}

/// Rang dense (1,1,2…) pour une liste déjà triée par score décroissant.
List<int> denseRanksForSortedLeaderboardDocs(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
) {
  if (docs.isEmpty) return const <int>[];
  final List<int> out = <int>[];
  int dense = 0;
  int? prevScore;
  for (final QueryDocumentSnapshot<Map<String, dynamic>> d in docs) {
    final int s = _docHighScore(d);
    if (prevScore == null || s != prevScore) {
      dense++;
      prevScore = s;
    }
    out.add(dense);
  }
  return out;
}

String _ordinalRankCore(BuildContext context, int d) {
  final String lang = Localizations.localeOf(
    context,
  ).languageCode.toLowerCase();
  if (lang == 'fr') {
    return d == 1 ? '1ᵉʳ' : '$dᵉ';
  }
  if (d % 100 >= 11 && d % 100 <= 13) {
    return '${d}th';
  }
  return switch (d % 10) {
    1 => '${d}st',
    2 => '${d}nd',
    3 => '${d}rd',
    _ => '${d}th',
  };
}

String _denseRankOrdinalLabel(BuildContext context, int d, bool tie) {
  if (d <= 0) return '—';
  final String core = _ordinalRankCore(context, d);
  return tie ? '=$core' : core;
}

String _leaderboardDisplayName(
  AppLocalizations l10n,
  Map<String, dynamic> data,
  String id,
) {
  final String? raw = data['pseudo'] as String?;
  final String t = raw?.trim() ?? '';
  if (t.isEmpty || t.startsWith('Oracle_') || t.startsWith('oracle_')) {
    final String frag = id.length >= 4 ? id.substring(0, 4).toUpperCase() : id;
    return l10n.leaderboardPlayerAnon(frag);
  }
  return OraclePseudo.formatForDisplay(t);
}

class LeaderboardView extends StatefulWidget {
  const LeaderboardView({super.key});

  @override
  State<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<LeaderboardView> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _top10Stream;

  @override
  void initState() {
    super.initState();
    _top10Stream = FirestoreService.instance.leaderboardTopTenStream;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final te = context.watch<ThemeEngine>();
    final gs = context.watch<GameState>();
    final double sH = Responsive.heightScale(context);
    final double sT = Responsive.textScale(context);
    final double rankColW = (34 * sH).clamp(30.0, 40.0);
    final double rankGap = (12 * sH).clamp(10.0, 14.0);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(color: Color(0xFF000000)),
            ),
          ),
          const Positioned.fill(child: DarkMatteOverlay()),
          SafeArea(
            bottom: false,
            child: Stack(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        18,
                        (20 * sH).clamp(14.0, 26.0),
                        18,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: 6 * sH),
                          Text(
                            l10n.leaderboardTitle,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  letterSpacing: 3.5,
                                  fontWeight: FontWeight.w500,
                                  color: te
                                      .colorForId(5)
                                      .withValues(alpha: 0.94),
                                  fontSize: (16 * sT).clamp(14.0, 18.0),
                                ),
                          ),
                          SizedBox(height: (16 * sH).clamp(12.0, 20.0)),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              4,
                              0,
                              4,
                              (8 * sH).clamp(6.0, 12.0),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: rankColW,
                                  child: Text(
                                    l10n.leaderboardColRank,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          letterSpacing: 2.2,
                                          fontWeight: FontWeight.w600,
                                          fontSize: (10 * sT).clamp(9.0, 12.0),
                                          color: Colors.white.withValues(
                                            alpha: 0.42,
                                          ),
                                        ),
                                  ),
                                ),
                                SizedBox(width: rankGap),
                                Expanded(
                                  child: Text(
                                    l10n.leaderboardColPlayer,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          letterSpacing: 2.2,
                                          fontWeight: FontWeight.w600,
                                          fontSize: (10 * sT).clamp(9.0, 12.0),
                                          color: Colors.white.withValues(
                                            alpha: 0.42,
                                          ),
                                        ),
                                  ),
                                ),
                                Text(
                                  l10n.leaderboardColScore,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        letterSpacing: 2.2,
                                        fontWeight: FontWeight.w600,
                                        fontSize: (10 * sT).clamp(9.0, 12.0),
                                        color: Colors.white.withValues(
                                          alpha: 0.42,
                                        ),
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child:
                                StreamBuilder<
                                  QuerySnapshot<Map<String, dynamic>>
                                >(
                                  stream: _top10Stream,
                                  builder: (context, snap) {
                                    if (snap.hasError) {
                                      return Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                          ),
                                          child: Text(
                                            l10n.leaderboardError(
                                              snap.error.toString(),
                                            ),
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.65),
                                                  height: 1.4,
                                                ),
                                          ),
                                        ),
                                      );
                                    }
                                    if (snap.connectionState ==
                                            ConnectionState.waiting &&
                                        !snap.hasData) {
                                      return Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const CircularProgressIndicator.adaptive(),
                                            SizedBox(
                                              height: (14 * sH).clamp(
                                                12.0,
                                                20.0,
                                              ),
                                            ),
                                            Text(
                                              l10n.leaderboardLoading,
                                              textAlign: TextAlign.center,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.5),
                                                    letterSpacing: 1.1,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    final List<
                                      QueryDocumentSnapshot<
                                        Map<String, dynamic>
                                      >
                                    >
                                    docs = sortedLeaderboardDocs(
                                      snap.data?.docs ??
                                          const <
                                            QueryDocumentSnapshot<
                                              Map<String, dynamic>
                                            >
                                          >[],
                                    );
                                    if (docs.isEmpty) {
                                      return Center(
                                        child: Text(
                                          l10n.leaderboardEmpty,
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: Colors.white.withValues(
                                                  alpha: 0.55,
                                                ),
                                              ),
                                        ),
                                      );
                                    }
                                    final List<int> denseRanks =
                                        denseRanksForSortedLeaderboardDocs(
                                          docs,
                                        );
                                    return ListView.builder(
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: docs.length,
                                      padding: EdgeInsets.only(bottom: 12 * sH),
                                      itemBuilder: (context, i) {
                                        final Map<String, dynamic> data =
                                            docs[i].data();
                                        final String id = docs[i].id;
                                        final String username =
                                            _leaderboardDisplayName(
                                              l10n,
                                              data,
                                              id,
                                            );
                                        final int lux =
                                            (data['highScore'] as num?)
                                                ?.toInt() ??
                                            0;
                                        final int d = denseRanks[i];
                                        final bool tiedAbove =
                                            i > 0 && denseRanks[i - 1] == d;
                                        final String rankLabel = tiedAbove
                                            ? '=$d'
                                            : '$d';
                                        return Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: (8 * sH).clamp(6.0, 10.0),
                                          ),
                                          child: _LeaderboardTile(
                                            denseRank: d,
                                            rankLabel: rankLabel,
                                            username: username,
                                            lux: lux,
                                            scaleH: sH,
                                            scaleT: sT,
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Positioned(top: 6, left: 6, child: UniversalBackButton()),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _LeaderboardBottomBar(
        scaleH: sH,
        scaleT: sT,
        fallbackLux: gs.highScore,
        yourRankFooterLabel: l10n.leaderboardYourRankFooter,
      ),
    );
  }
}

/// Pied de page : doc `players` (propriétaire) pour le score affiché + rang dense
/// ([FirestoreService.getMyRankStream] sur `leaderboardPublic` pour le classement mondial).
class _LeaderboardBottomBar extends StatefulWidget {
  const _LeaderboardBottomBar({
    required this.scaleH,
    required this.scaleT,
    required this.fallbackLux,
    required this.yourRankFooterLabel,
  });

  final double scaleH;
  final double scaleT;
  final int fallbackLux;
  final String yourRankFooterLabel;

  @override
  State<_LeaderboardBottomBar> createState() => _LeaderboardBottomBarState();
}

class _LeaderboardBottomBarState extends State<_LeaderboardBottomBar> {
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _playerDocStream;
  Stream<MyDenseWorldRank>? _footerRankStream;

  @override
  void initState() {
    super.initState();
    final String? uid = FirestoreService.instance.currentFirebaseUserId;
    if (uid != null) {
      _playerDocStream = FirestoreService.instance.getPlayerDocStream(uid);
      _footerRankStream = FirestoreService.instance.getMyRankStream(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_playerDocStream == null || _footerRankStream == null) {
      return _YourRankBar(
        scaleH: widget.scaleH,
        scaleT: widget.scaleT,
        yourRankFooterLabel: widget.yourRankFooterLabel,
        rankLabel: '—',
        yourLux: widget.fallbackLux,
      );
    }
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _playerDocStream,
      builder: (context, docSnap) {
        final Map<String, dynamic>? data = docSnap.data?.data();
        final int myScore =
            (data?['highScore'] as num?)?.toInt() ?? widget.fallbackLux;
        return StreamBuilder<MyDenseWorldRank>(
          stream: _footerRankStream,
          builder: (context, rankSnap) {
            final MyDenseWorldRank? fr = rankSnap.data;
            final int d = fr?.denseRank ?? 0;
            final bool tie = fr?.tiedWithOthersSameScore ?? false;
            final String label = _denseRankOrdinalLabel(context, d, tie);
            return _YourRankBar(
              scaleH: widget.scaleH,
              scaleT: widget.scaleT,
              yourRankFooterLabel: widget.yourRankFooterLabel,
              rankLabel: label,
              yourLux: myScore,
            );
          },
        );
      },
    );
  }
}

/// Icône discrète à côté du pseudo pour le top 3 (coupe / médailles).
class _PodiumGlyph extends StatelessWidget {
  const _PodiumGlyph({
    required this.denseRank,
    required this.accent,
    required this.scaleT,
  });

  final int denseRank;
  final Color accent;
  final double scaleT;

  @override
  Widget build(BuildContext context) {
    if (denseRank > 3) return const SizedBox.shrink();
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final IconData icon = switch (denseRank) {
      1 => Icons.emoji_events_rounded, // coupe
      2 => Icons.workspace_premium_rounded, // médaille (argent)
      3 => Icons.military_tech_rounded, // médaille (bronze)
      _ => Icons.military_tech_rounded,
    };
    final double size = (22 * scaleT).clamp(20.0, 28.0);
    final bool isFirst = denseRank == 1;
    final String semLabel = switch (denseRank) {
      1 => l10n.leaderboardPodiumFirst,
      2 => l10n.leaderboardPodiumSecond,
      3 => l10n.leaderboardPodiumThird,
      _ => l10n.leaderboardPodiumOther,
    };
    return Semantics(
      label: semLabel,
      child: Icon(
        icon,
        size: size,
        color: accent.withValues(alpha: 0.96),
        shadows: <Shadow>[
          Shadow(
            color: accent.withValues(alpha: isFirst ? 0.58 : 0.44),
            blurRadius: isFirst ? 18 : 13,
            offset: const Offset(0, 0.6),
          ),
          Shadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2.5),
          ),
        ],
      ),
    );
  }
}

class _PodiumBadge extends StatelessWidget {
  const _PodiumBadge({
    required this.denseRank,
    required this.size,
    required this.accent,
    required this.scaleT,
  });

  final int denseRank;
  final double size;
  final Color accent;
  final double scaleT;

  @override
  Widget build(BuildContext context) {
    if (denseRank > 3) return const SizedBox.shrink();
    final bool isFirst = denseRank == 1;
    final double glow = isFirst ? 0.30 : 0.22;
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(0, -0.25),
            radius: 0.95,
            colors: [
              accent.withValues(alpha: glow),
              const Color(0xFF000000).withValues(alpha: 0.55),
            ],
          ),
          border: Border.all(
            color: accent.withValues(alpha: isFirst ? 0.62 : 0.50),
            width: 1.15,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: isFirst ? 0.30 : 0.22),
              blurRadius: isFirst ? 22 : 16,
              spreadRadius: isFirst ? 2 : 1,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 10,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: _PodiumGlyph(
            denseRank: denseRank,
            accent: accent,
            scaleT: scaleT * 1.05,
          ),
        ),
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({
    required this.denseRank,
    required this.rankLabel,
    required this.username,
    required this.lux,
    required this.scaleH,
    required this.scaleT,
  });

  /// Rang dense (1,1,2…) pour médailles or / argent / bronze.
  final int denseRank;
  final String rankLabel;
  final String username;
  final int lux;
  final double scaleH;
  final double scaleT;

  static const Color _gold = Color(0xFFFFD700);
  static const Color _silver = Color(0xFFC9D3E6);
  static const Color _bronze = Color(0xFFC08457);
  static const Color _cyan = Color(0xFF00E5FF);

  ({Color accent, bool glow}) _accentForRank() {
    return switch (denseRank) {
      1 => (accent: _gold, glow: true),
      2 => (accent: _silver, glow: true),
      3 => (accent: _bronze, glow: true),
      _ => (accent: _cyan, glow: false),
    };
  }

  @override
  Widget build(BuildContext context) {
    final ({Color accent, bool glow}) a = _accentForRank();
    final Color accent = a.accent;
    final bool glow = a.glow;
    final bool isPodium = denseRank <= 3;

    final double tilePadH = (14 * scaleH).clamp(12.0, 18.0);
    final double tilePadV = (12 * scaleH).clamp(10.0, 14.0);
    final double rankSize = (34 * scaleH).clamp(30.0, 40.0);
    final double fontBase = (14 * scaleT).clamp(12.0, 16.0);
    final double luxFont = (13.5 * scaleT).clamp(12.0, 16.0);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: tilePadH, vertical: tilePadV),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0D12).withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.14),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: accent.withValues(alpha: 0.08),
                  blurRadius: 58,
                  spreadRadius: 6,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          if (isPodium)
            _PodiumBadge(
              denseRank: denseRank,
              size: rankSize,
              accent: accent,
              scaleT: scaleT,
            )
          else
            _RankBadge(
              label: rankLabel,
              size: rankSize,
              accent: accent,
              glow: glow,
              scaleT: scaleT,
            ),
          SizedBox(width: (12 * scaleH).clamp(10.0, 14.0)),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: fontBase,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: Colors.white.withValues(alpha: 0.86),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: (10 * scaleH).clamp(8.0, 12.0)),
          _LuxAmount(lux: lux, accent: accent, fontSize: luxFont),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({
    required this.label,
    required this.size,
    required this.accent,
    required this.glow,
    required this.scaleT,
  });

  final String label;
  final double size;
  final Color accent;
  final bool glow;
  final double scaleT;

  @override
  Widget build(BuildContext context) {
    final double font = (label.length > 2 ? 11.0 : 14.0) * scaleT;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF000000).withValues(alpha: 0.40),
        border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: glow ? 0.22 : 0.12),
            blurRadius: glow ? 18 : 12,
            spreadRadius: glow ? 2 : 1,
          ),
        ],
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.robotoMono(
          fontSize: font.clamp(9.0, 16.0),
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: accent.withValues(alpha: 0.95),
          shadows: [
            Shadow(
              color: accent.withValues(alpha: glow ? 0.45 : 0.28),
              blurRadius: glow ? 16 : 12,
            ),
          ],
        ),
      ),
    );
  }
}

class _LuxAmount extends StatelessWidget {
  const _LuxAmount({
    required this.lux,
    required this.accent,
    required this.fontSize,
  });

  final int lux;
  final Color accent;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final double iconSize = (10 + (fontSize - 12) * 0.5).clamp(10.0, 12.0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.brightness_1,
          size: iconSize,
          color: accent.withValues(alpha: 0.9),
        ),
        const SizedBox(width: 8),
        Text(
          '$lux',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.robotoMono(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: accent.withValues(alpha: 0.95),
          ),
        ),
      ],
    );
  }
}

class _YourRankBar extends StatelessWidget {
  const _YourRankBar({
    required this.scaleH,
    required this.scaleT,
    required this.yourRankFooterLabel,
    required this.rankLabel,
    required this.yourLux,
  });

  final double scaleH;
  final double scaleT;
  final String yourRankFooterLabel;
  final String rankLabel;
  final int yourLux;

  static const Color _cyan = Color(0xFF00E5FF);
  static const Color _gold = Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    final double padV = (14 * scaleH).clamp(12.0, 18.0);
    final double padH = (18 * scaleH).clamp(16.0, 22.0);
    final double labelSize = (12 * scaleT).clamp(11.0, 14.0);
    final double valueSize = (13.5 * scaleT).clamp(12.0, 16.0);

    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF070812).withValues(alpha: 0.78),
              const Color(0xFF05060A).withValues(alpha: 0.94),
            ],
          ),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          boxShadow: [
            BoxShadow(
              color: _cyan.withValues(alpha: 0.10),
              blurRadius: 46,
              spreadRadius: 6,
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(padH, padV, padH, padV),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    yourRankFooterLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: labelSize,
                      letterSpacing: 3.2,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.62),
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Colors.black.withValues(alpha: 0.30),
                    border: Border.all(color: _cyan.withValues(alpha: 0.30)),
                    boxShadow: [
                      BoxShadow(
                        color: _cyan.withValues(alpha: 0.16),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: (10 * scaleH).clamp(8.0, 12.0),
                      vertical: (6 * scaleH).clamp(5.0, 8.0),
                    ),
                    child: Text(
                      rankLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.robotoMono(
                        fontSize: valueSize,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: _cyan.withValues(alpha: 0.94),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: (14 * scaleH).clamp(10.0, 16.0)),
                _LuxAmount(lux: yourLux, accent: _gold, fontSize: valueSize),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
