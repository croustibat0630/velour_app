import 'package:flutter/material.dart';

import 'route_transition_notifier.dart';

/// Observes route transitions and toggles [RouteTransitionNotifier].
class RouteTransitionObserver extends NavigatorObserver {
  void _track(Route<dynamic>? route) {
    if (route is! PageRoute<dynamic>) return;
    final Animation<double>? a = route.animation;
    if (a == null) return;

    bool done = false;

    void maybeEnd(AnimationStatus status) {
      if (done) return;
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        done = true;
        a.removeStatusListener(maybeEnd);
        RouteTransitionNotifier.end();
      }
    }

    RouteTransitionNotifier.begin();
    a.addStatusListener(maybeEnd);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _track(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    // Pop animates the route being popped.
    _track(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _track(newRoute);
  }
}

