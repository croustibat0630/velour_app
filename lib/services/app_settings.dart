import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'audio_handler.dart';
import 'haptics_handler.dart';

enum AppLanguage { fr, en }

class AppSettings {
  AppSettings._();

  static final AppSettings instance = AppSettings._();

  static const String _keyMusicMuted = 'velour_music_muted';
  static const String _keySfxMuted = 'velour_sfx_muted';
  static const String _keyHapticsEnabled = 'velour_haptics_enabled';
  static const String _keyLanguage = 'velour_language';

  final ValueNotifier<AppLanguage> language = ValueNotifier<AppLanguage>(
    AppLanguage.fr,
  );

  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool musicMuted = prefs.getBool(_keyMusicMuted) ?? false;
      final bool sfxMuted = prefs.getBool(_keySfxMuted) ?? false;
      final bool hapticsEnabled = prefs.getBool(_keyHapticsEnabled) ?? true;
      final String lang = prefs.getString(_keyLanguage) ?? 'fr';

      // Apply (best-effort, no throw).
      unawaited(AudioHandler.instance.setMuted(musicMuted));
      AudioHandler.instance.sfxMuted.value = sfxMuted;
      HapticsHandler.instance.enabled.value = hapticsEnabled;
      language.value = (lang == 'en') ? AppLanguage.en : AppLanguage.fr;
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

  Future<void> setLanguage(AppLanguage v) async {
    language.value = v;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLanguage, v == AppLanguage.en ? 'en' : 'fr');
    } catch (_) {}
  }
}

