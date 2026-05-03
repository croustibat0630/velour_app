import 'dart:async';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'audio_handler.dart';
import 'haptics_handler.dart';

/// In-app locale: follow OS, or pin English / French / German.
enum AppLocalePreference { system, en, fr, de }

class AppSettings {
  AppSettings._();

  static final AppSettings instance = AppSettings._();

  static const String _keyMusicMuted = 'velour_music_muted';
  static const String _keySfxMuted = 'velour_sfx_muted';
  static const String _keyHapticsEnabled = 'velour_haptics_enabled';
  static const String _keyLanguage = 'velour_language';

  final ValueNotifier<AppLocalePreference> localePreference =
      ValueNotifier<AppLocalePreference>(AppLocalePreference.system);

  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool musicMuted = prefs.getBool(_keyMusicMuted) ?? false;
      final bool sfxMuted = prefs.getBool(_keySfxMuted) ?? false;
      final bool hapticsEnabled = prefs.getBool(_keyHapticsEnabled) ?? true;
      final String? langRaw = prefs.getString(_keyLanguage);

      // Apply (best-effort, no throw).
      unawaited(AudioHandler.instance.setMuted(musicMuted));
      AudioHandler.instance.sfxMuted.value = sfxMuted;
      HapticsHandler.instance.enabled.value = hapticsEnabled;
      if (langRaw == null || langRaw == 'system') {
        localePreference.value = AppLocalePreference.system;
      } else if (langRaw == 'en') {
        localePreference.value = AppLocalePreference.en;
      } else if (langRaw == 'fr') {
        localePreference.value = AppLocalePreference.fr;
      } else if (langRaw == 'de') {
        localePreference.value = AppLocalePreference.de;
      } else {
        localePreference.value = AppLocalePreference.fr;
      }
    } catch (_) {}
  }

  Future<void> setMusicMuted(bool muted) async {
    unawaited(AudioHandler.instance.setMuted(muted));
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyMusicMuted, muted);
    } catch (_) {}
  }

  Future<void> setSfxMuted(bool muted) async {
    AudioHandler.instance.sfxMuted.value = muted;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySfxMuted, muted);
    } catch (_) {}
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    HapticsHandler.instance.enabled.value = enabled;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyHapticsEnabled, enabled);
    } catch (_) {}
  }

  Future<void> setLocalePreference(AppLocalePreference v) async {
    localePreference.value = v;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String code = switch (v) {
        AppLocalePreference.system => 'system',
        AppLocalePreference.en => 'en',
        AppLocalePreference.fr => 'fr',
        AppLocalePreference.de => 'de',
      };
      await prefs.setString(_keyLanguage, code);
    } catch (_) {}
  }

  /// Resolved [Locale] for [MaterialApp.locale] (`null` = OS resolution).
  static Locale? materialLocaleFor(AppLocalePreference pref) {
    return switch (pref) {
      AppLocalePreference.system => null,
      AppLocalePreference.en => const Locale('en'),
      AppLocalePreference.fr => const Locale('fr'),
      AppLocalePreference.de => const Locale('de'),
    };
  }
}
