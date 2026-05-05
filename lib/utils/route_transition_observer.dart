import 'package:flutter/material.dart';

import 'route_transition_notifier.dart';
import 'velour_audit_log.dart';

/// Observes route transitions and toggles [RouteTransitionNotifier].
class RouteTransitionObserver extends NavigatorObserver {
  static const bool _logInternalRoutes = bool.fromEnvironment(
    'VELOUR_AUDIT_NAV_INTERNAL',
    defaultValue: false,
  );

  bool _shouldLog(Route<dynamic>? route) {
    if (route == null) return false;
    if (_logInternalRoutes) return true;
    final String rt = route.runtimeType.toString();
    // These are noisy and not very actionable in audit logs.
    if (rt.contains('_DropdownRoute') || rt.contains('DialogRoute')) {
      return false;
    }
    return true;
  }

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
    if (!_shouldLog(route)) {
      _track(route);
      return;
    }
    VelourAuditLog.event(
      'nav.push',
      data: <String, Object?>{
        'route': route.settings.name ?? route.runtimeType.toString(),
        'prev': previousRoute?.settings.name ?? previousRoute?.runtimeType.toString(),
      },
    );
    _track(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (!_shouldLog(route)) {
      _track(route);
      return;
    }
    VelourAuditLog.event(
      'nav.pop',
      data: <String, Object?>{
        'route': route.settings.name ?? route.runtimeType.toString(),
        'prev': previousRoute?.settings.name ?? previousRoute?.runtimeType.toString(),
      },
    );
    // Pop animates the route being popped.
    _track(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (!_shouldLog(newRoute)) {
      _track(newRoute);
      return;
    }
    VelourAuditLog.event(
      'nav.replace',
      data: <String, Object?>{
        'new': newRoute?.settings.name ?? newRoute?.runtimeType.toString(),
        'old': oldRoute?.settings.name ?? oldRoute?.runtimeType.toString(),
      },
    );
    _track(newRoute);
  }
}
