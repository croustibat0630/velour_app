import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Centralized haptics gate to keep feedback consistent.
class HapticsHandler {
  HapticsHandler._();

  static final HapticsHandler instance = HapticsHandler._();

  final ValueNotifier<bool> enabled = ValueNotifier<bool>(true);
  bool _errorPatternRunning = false;

  bool get _canRun => enabled.value;

  void selectionClick() {
    if (!_canRun) return;
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  void lightImpact() {
    if (!_canRun) return;
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  void mediumImpact() {
    if (!_canRun) return;
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  void heavyImpact() {
    if (!_canRun) return;
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  void errorVibrate() {
    if (!_canRun) return;
    if (_errorPatternRunning) return;
    _errorPatternRunning = true;
    _runErrorPattern();
  }

  Future<void> _runErrorPattern() async {
    try {
      HapticFeedback.vibrate();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (!_canRun) return;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (!_canRun) return;
      HapticFeedback.vibrate();
    } catch (_) {
    } finally {
      _errorPatternRunning = false;
    }
  }
}
