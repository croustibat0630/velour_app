import 'package:flutter/foundation.dart';

/// Global notifier used to freeze micro-animations during Navigator transitions.
///
/// Goal: avoid text blurring on Web when a widget is being scaled/repainted
/// during a route push/pop.
class RouteTransitionNotifier {
  RouteTransitionNotifier._();

  static final ValueNotifier<int> _active = ValueNotifier<int>(0);

  static ValueListenable<int> get activeTransitions => _active;

  static bool get isTransitioning => _active.value > 0;

  static void begin() {
    _active.value = _active.value + 1;
  }

  static void end() {
    _active.value = (_active.value - 1).clamp(0, 999999);
  }
}
