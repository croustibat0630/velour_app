import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../providers/game_state.dart';

class CareerStats {
  const CareerStats({
    required this.totalLuxEarned,
    required this.highStakeWin,
    required this.totalMatchesPlayed,
    required this.shapesPlaced,
    required this.bestLevelReached,
    required this.totalPlayTime,
    required this.casualRuns,
    required this.highStakesRuns,
    required this.royalRuns,
    this.streakDays = 0,
  });

  final int totalLuxEarned;
  final int highStakeWin;
  final int totalMatchesPlayed;
  final int shapesPlaced;
  final int bestLevelReached;
  final Duration totalPlayTime;

  /// Distribution des modes (pour UI).
  final int casualRuns;
  final int highStakesRuns;
  final int royalRuns;

  /// Jours consécutifs avec au moins une partie enregistrée (prefs).
  final int streakDays;

  int get totalRuns => casualRuns + highStakesRuns + royalRuns;
}

class StatsService {
  StatsService._();

  static final StatsService instance = StatsService._();

  static const String _kTotalLuxEarned = 'velour_stats_total_lux_earned';
  static const String _kHighStakeWin = 'velour_stats_high_stake_win';
  static const String _kTotalMatchesPlayed = 'velour_stats_total_matches_played';
  static const String _kShapesPlaced = 'velour_stats_shapes_placed';
  static const String _kBestLevelReached = 'velour_stats_best_level';
  static const String _kTotalPlayTimeMs = 'velour_stats_total_play_time_ms';
  static const String _kCasualRuns = 'velour_stats_runs_casual';
  static const String _kHighStakesRuns = 'velour_stats_runs_high_stakes';
  static const String _kRoyalRuns = 'velour_stats_runs_royal';

  /// Série de jours avec au moins une partie terminée (calendrier local).
  static const String _kStreakLastYmd = 'velour_streak_last_yyyymmdd';
  static const String _kStreakCount = 'velour_streak_current_days';

  SharedPreferences? _prefs;
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    _prefs = await SharedPreferences.getInstance();
  }

  /// Alias explicite pour l’initialisation au démarrage (splash / stress).
  Future<void> init() async => load();

  CareerStats snapshot() {
    final SharedPreferences? p = _prefs;
    if (p == null) {
      return const CareerStats(
        totalLuxEarned: 0,
        highStakeWin: 0,
        totalMatchesPlayed: 0,
        shapesPlaced: 0,
        bestLevelReached: 0,
        totalPlayTime: Duration.zero,
        casualRuns: 0,
        highStakesRuns: 0,
        royalRuns: 0,
        streakDays: 0,
      );
    }
    return CareerStats(
      totalLuxEarned: p.getInt(_kTotalLuxEarned) ?? 0,
      highStakeWin: p.getInt(_kHighStakeWin) ?? 0,
      totalMatchesPlayed: p.getInt(_kTotalMatchesPlayed) ?? 0,
      shapesPlaced: p.getInt(_kShapesPlaced) ?? 0,
      bestLevelReached: p.getInt(_kBestLevelReached) ?? 0,
      totalPlayTime: Duration(
        milliseconds: (p.getInt(_kTotalPlayTimeMs) ?? 0).clamp(0, 1 << 31),
      ),
      casualRuns: p.getInt(_kCasualRuns) ?? 0,
      highStakesRuns: p.getInt(_kHighStakesRuns) ?? 0,
      royalRuns: p.getInt(_kRoyalRuns) ?? 0,
      streakDays: (p.getInt(_kStreakCount) ?? 0).clamp(0, 9999),
    );
  }

  /// Met à jour les stats de carrière à chaque fin de partie.
  ///
  /// - [scoreLux]: score final affiché.
  /// - [luxGained]: LUX gagnés sur la run (souvent identique au score final).
  /// - [levelReached]: niveau final atteint.
  /// - [shapes]: nombre de formes placées pendant la run.
  /// - [matches]: nombre de validations (runs match-3) résolues pendant la run.
  /// - [playTime]: durée effective de la run.
  Future<void> recordGame({
    required int scoreLux,
    required int luxGained,
    required int levelReached,
    required int shapes,
    required int matches,
    required Duration playTime,
    required SessionStakeKind stake,
  }) async {
    await load();
    final SharedPreferences p = _prefs!;

    final int totalLux = (p.getInt(_kTotalLuxEarned) ?? 0) + luxGained;
    final int bestLevel = (p.getInt(_kBestLevelReached) ?? 0);
    final int nextBestLevel = levelReached > bestLevel ? levelReached : bestLevel;

    final int prevHigh = p.getInt(_kHighStakeWin) ?? 0;
    final int nextHigh = luxGained > prevHigh ? luxGained : prevHigh;

    final int nextMatches = (p.getInt(_kTotalMatchesPlayed) ?? 0) + matches;
    final int nextShapes = (p.getInt(_kShapesPlaced) ?? 0) + shapes;

    final int prevMs = p.getInt(_kTotalPlayTimeMs) ?? 0;
    final int addMs = playTime.inMilliseconds.clamp(0, 60 * 60 * 1000); // cap 1h/run
    final int nextMs = prevMs + addMs;

    int casualRuns = p.getInt(_kCasualRuns) ?? 0;
    int highStakesRuns = p.getInt(_kHighStakesRuns) ?? 0;
    int royalRuns = p.getInt(_kRoyalRuns) ?? 0;
    switch (stake) {
      case SessionStakeKind.casual:
        casualRuns++;
        break;
      case SessionStakeKind.highStakes:
        highStakesRuns++;
        break;
      case SessionStakeKind.royal:
        royalRuns++;
        break;
    }

    await Future.wait<void>([
      p.setInt(_kTotalLuxEarned, totalLux),
      p.setInt(_kHighStakeWin, nextHigh),
      p.setInt(_kTotalMatchesPlayed, nextMatches),
      p.setInt(_kShapesPlaced, nextShapes),
      p.setInt(_kBestLevelReached, nextBestLevel),
      p.setInt(_kTotalPlayTimeMs, nextMs),
      p.setInt(_kCasualRuns, casualRuns),
      p.setInt(_kHighStakesRuns, highStakesRuns),
      p.setInt(_kRoyalRuns, royalRuns),
    ]);
    await _bumpDailyStreak(p);
  }

  static int _yyyymmdd(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  static DateTime _dateFromYyyymmdd(int ymd) {
    final int y = ymd ~/ 10000;
    final int m = (ymd % 10000) ~/ 100;
    final int day = ymd % 100;
    return DateTime(y, m, day);
  }

  /// Au moins une partie le même jour : une seule incrémentation par jour calendaire.
  Future<void> _bumpDailyStreak(SharedPreferences p) async {
    final int today = _yyyymmdd(DateTime.now());
    final int last = p.getInt(_kStreakLastYmd) ?? 0;
    int streak = p.getInt(_kStreakCount) ?? 0;

    if (last == today) {
      return;
    }
    if (last == 0) {
      streak = 1;
    } else {
      final int gap = _dateFromYyyymmdd(today)
          .difference(_dateFromYyyymmdd(last))
          .inDays;
      if (gap == 1) {
        streak = (streak + 1).clamp(1, 9999);
      } else {
        streak = 1;
      }
    }
    await Future.wait<void>([
      p.setInt(_kStreakLastYmd, today),
      p.setInt(_kStreakCount, streak),
    ]);
  }
}

