import 'package:flutter/material.dart';
import 'package:velour_app/l10n/app_localizations.dart';

import '../services/stats_service.dart';
import '../utils/responsive.dart';
import '../widgets/ui/dark_matte_overlay.dart';
import '../widgets/ui/universal_back_button.dart';

class StatsView extends StatefulWidget {
  const StatsView({super.key});

  @override
  State<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<StatsView> {
  static const Color _gold = Color(0xFFFFD700);

  late CareerStats _stats;

  @override
  void initState() {
    super.initState();
    _stats = StatsService.instance.snapshot();
    // Refresh once in case prefs were loaded async.
    StatsService.instance.load().then((_) {
      if (!mounted) return;
      setState(() => _stats = StatsService.instance.snapshot());
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final double sH = Responsive.heightScale(context);
    final double sT = Responsive.textScale(context);

    final double accuracy = (_stats.shapesPlaced <= 0)
        ? 0
        : (_stats.totalMatchesPlayed / _stats.shapesPlaced).clamp(0.0, 1.0);

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
          SafeArea(
            child: Stack(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        18,
                        (14 * sH).clamp(12.0, 20.0),
                        18,
                        (18 * sH).clamp(14.0, 22.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.statsTitle,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  letterSpacing: 3,
                                  fontWeight: FontWeight.w600,
                                  color: _gold.withValues(alpha: 0.96),
                                  fontSize: (16 * sT).clamp(14.0, 19.0),
                                ),
                          ),
                          SizedBox(height: (18 * sH).clamp(14.0, 22.0)),
                          if (_stats.streakDays > 0) ...[
                            Text(
                              l10n.statsStreakSession(_stats.streakDays),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    letterSpacing: 1.65,
                                    fontWeight: FontWeight.w700,
                                    color: _gold.withValues(alpha: 0.84),
                                    fontSize: (11 * sT).clamp(10.0, 13.0),
                                  ),
                            ),
                            SizedBox(height: (12 * sH).clamp(10.0, 16.0)),
                          ],
                          LayoutBuilder(
                            builder: (context, c) {
                              final bool wide = c.maxWidth >= 520;
                              final double heroRowH = wide
                                  ? (((c.maxWidth - 12) / 2) / 1.22).clamp(
                                      102.0,
                                      136.0,
                                    )
                                  : 0;
                              final double heroStackH = !wide
                                  ? (c.maxWidth / 1.12).clamp(92.0, 118.0)
                                  : 0;
                              final Widget luxHero = _StatCard(
                                title: l10n.statsLuxEarned,
                                value: '${_stats.totalLuxEarned}',
                                accent: _gold,
                                icon: Icons.brightness_1,
                                hero: true,
                              );
                              final Widget bestHero = _StatCard(
                                title: l10n.statsBestGain,
                                value: '${_stats.highStakeWin}',
                                accent: _gold,
                                icon: Icons.auto_awesome_rounded,
                                hero: true,
                              );
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (wide)
                                    SizedBox(
                                      height: heroRowH,
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Expanded(child: luxHero),
                                          const SizedBox(width: 12),
                                          Expanded(child: bestHero),
                                        ],
                                      ),
                                    )
                                  else ...[
                                    SizedBox(
                                      height: heroStackH,
                                      child: luxHero,
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      height: heroStackH,
                                      child: bestHero,
                                    ),
                                  ],
                                  SizedBox(height: (14 * sH).clamp(12.0, 18.0)),
                                  GridView.count(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    childAspectRatio: wide ? 1.22 : 1.05,
                                    children: [
                                      _StatCard(
                                        title: l10n.statsMaxLevel,
                                        value: '${_stats.bestLevelReached}',
                                        accent: _gold,
                                        icon: Icons.trending_up_rounded,
                                        subdued: true,
                                      ),
                                      _StatCard(
                                        title: l10n.statsShapesPlaced,
                                        value: '${_stats.shapesPlaced}',
                                        accent: _gold,
                                        icon: Icons.category_rounded,
                                        subdued: true,
                                      ),
                                      _StatCard(
                                        title: l10n.statsMatches,
                                        value: '${_stats.totalMatchesPlayed}',
                                        accent: _gold,
                                        icon: Icons.done_all_rounded,
                                        subdued: true,
                                      ),
                                      _StatCard(
                                        title: l10n.statsTotalTime,
                                        value: _formatDuration(
                                          _stats.totalPlayTime,
                                        ),
                                        accent: _gold,
                                        icon: Icons.schedule_rounded,
                                        subdued: true,
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                          SizedBox(height: (14 * sH).clamp(10.0, 18.0)),
                          _Panel(
                            title: l10n.statsPrecisionTitle,
                            accent: _gold,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 70,
                                  height: 70,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      CircularProgressIndicator(
                                        value: accuracy,
                                        strokeWidth: 4,
                                        color: _gold.withValues(alpha: 0.92),
                                        backgroundColor: Colors.white
                                            .withValues(alpha: 0.08),
                                      ),
                                      Center(
                                        child: Text(
                                          '${(accuracy * 100).round()}%',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 1.2,
                                                color: Colors.white.withValues(
                                                  alpha: 0.80,
                                                ),
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    l10n.statsPrecisionHelp,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          height: 1.35,
                                          color: Colors.white.withValues(
                                            alpha: 0.50,
                                          ),
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 12 * sH),
                          _Panel(
                            title: l10n.statsModesTitle,
                            accent: _gold,
                            child: Column(
                              children: [
                                _ModeBar(
                                  label: l10n.statsModeCasual,
                                  value: _ratio(
                                    _stats.casualRuns,
                                    _stats.totalRuns,
                                  ),
                                  count: _stats.casualRuns,
                                  accent: Colors.white.withValues(alpha: 0.72),
                                ),
                                const SizedBox(height: 10),
                                _ModeBar(
                                  label: l10n.statsModeHighStakes,
                                  value: _ratio(
                                    _stats.highStakesRuns,
                                    _stats.totalRuns,
                                  ),
                                  count: _stats.highStakesRuns,
                                  accent: _gold.withValues(alpha: 0.92),
                                ),
                                const SizedBox(height: 10),
                                _ModeBar(
                                  label: l10n.statsModeRoyal,
                                  value: _ratio(
                                    _stats.royalRuns,
                                    _stats.totalRuns,
                                  ),
                                  count: _stats.royalRuns,
                                  accent: const Color(
                                    0xFFE49BFF,
                                  ).withValues(alpha: 0.90),
                                ),
                              ],
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
    );
  }

  double _ratio(int part, int total) {
    if (total <= 0) return 0;
    return (part / total).clamp(0.0, 1.0);
  }

  String _formatDuration(Duration d) {
    final int totalSeconds = d.inSeconds;
    final int h = totalSeconds ~/ 3600;
    final int m = (totalSeconds % 3600) ~/ 60;
    final int s = totalSeconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.accent,
    required this.child,
  });

  final String title;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double sH = Responsive.heightScale(context);
    final double sT = Responsive.textScale(context);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0C12).withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: EdgeInsets.all((14 * sH).clamp(12.0, 18.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                letterSpacing: 4.2,
                fontWeight: FontWeight.w700,
                fontSize: (11 * sT).clamp(10.0, 13.0),
                color: accent.withValues(alpha: 0.82),
              ),
            ),
            SizedBox(height: (10 * sH).clamp(8.0, 14.0)),
            child,
          ],
        ),
      ),
    );
  }
}

class _ModeBar extends StatelessWidget {
  const _ModeBar({
    required this.label,
    required this.value,
    required this.count,
    required this.accent,
  });

  final String label;
  final double value;
  final int count;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final double sT = Responsive.textScale(context);
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              letterSpacing: 2.2,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.60),
              fontSize: (11.5 * sT).clamp(10.0, 13.0),
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 34,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.accent,
    required this.icon,
    this.hero = false,
    this.subdued = false,
  });

  final String title;
  final String value;
  final Color accent;
  final IconData icon;
  final bool hero;
  final bool subdued;

  @override
  Widget build(BuildContext context) {
    final double sH = Responsive.heightScale(context);
    final double sT = Responsive.textScale(context);
    final double pad = ((hero ? 16 : 14) * sH).clamp(12.0, hero ? 20.0 : 18.0);
    final double borderA = subdued ? 0.06 : 0.08;
    final double valueShadowA = subdued ? 0.08 : 0.18;
    final double valueBlur = subdued ? 6 : 10;
    final double iconSize = hero ? 19.0 : 16.0;
    final double valueSize = ((hero ? 24 : 22) * sT).clamp(
      hero ? 20.0 : 18.0,
      hero ? 30.0 : 28.0,
    );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0C12).withValues(alpha: subdued ? 0.78 : 0.86),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: borderA)),
        boxShadow: subdued
            ? const <BoxShadow>[]
            : <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: hero ? 14 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    icon,
                    size: iconSize,
                    color: accent.withValues(alpha: subdued ? 0.68 : 0.80),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      letterSpacing: hero ? 1.85 : 1.65,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      fontSize: (10.5 * sT).clamp(10.0, 13.0),
                      color: Colors.white.withValues(
                        alpha: subdued ? 0.52 : 0.60,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                letterSpacing: hero ? 0.85 : 0.75,
                fontWeight: FontWeight.w800,
                fontSize: valueSize,
                color: Colors.white.withValues(alpha: subdued ? 0.78 : 0.88),
                shadows: [
                  Shadow(
                    color: accent.withValues(alpha: valueShadowA),
                    blurRadius: valueBlur,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
