import 'package:flutter/material.dart';

import 'velour_activation_funnel.dart';
import 'velour_analytics.dart';

/// Mesure le temps passé avec l’app **au premier plan** (Analytics opt-in).
///
/// Émet `velour_app_foreground_end` à la mise en arrière-plan avec `duration_sec`
/// (visible dans DebugView / GA4, contrairement aux seuls events Google automatiques).
/// Sprint 2 : déclenche aussi [VelourActivationFunnel.noteSessionClosed].
final class VelourAppEngagementTracker {
  VelourAppEngagementTracker._();

  static final VelourAppEngagementTracker instance =
      VelourAppEngagementTracker._();

  DateTime? _foregroundSince;
  String _routeName = 'splash';

  /// Dernière route nommée ([MaterialApp.routes] ou `home`).
  void noteRoute(String? routeName) {
    if (routeName == null || routeName.isEmpty) return;
    _routeName = routeName;
  }

  void onAppLifecycle(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _foregroundSince = DateTime.now();
        VelourAnalytics.logAppForegroundStart(routeName: _routeName);
        break;
      case AppLifecycleState.paused:
        _flushForegroundEnd('paused');
        VelourActivationFunnel.instance.noteSessionClosed(lifecycle: 'paused');
        break;
      case AppLifecycleState.hidden:
        _flushForegroundEnd('hidden');
        VelourActivationFunnel.instance.noteSessionClosed(lifecycle: 'hidden');
        break;
      case AppLifecycleState.detached:
        _flushForegroundEnd('detached');
        VelourActivationFunnel.instance.noteSessionClosed(
          lifecycle: 'detached',
        );
        break;
      case AppLifecycleState.inactive:
        break;
    }
  }

  void _flushForegroundEnd(String lifecycle) {
    final DateTime? since = _foregroundSince;
    _foregroundSince = null;
    if (since == null) return;
    final int durationSec = DateTime.now().difference(since).inSeconds;
    if (durationSec < 1) return;
    VelourAnalytics.logAppForegroundEnd(
      durationSec: durationSec,
      lifecycle: lifecycle,
      routeName: _routeName,
    );
  }
}

/// Observe le cycle de vie OS + enregistre la route courante pour Analytics.
class VelourAppEngagementBinder extends StatefulWidget {
  const VelourAppEngagementBinder({super.key, required this.child});

  final Widget child;

  @override
  State<VelourAppEngagementBinder> createState() =>
      _VelourAppEngagementBinderState();
}

class _VelourAppEngagementBinderState extends State<VelourAppEngagementBinder>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    VelourAppEngagementTracker.instance.onAppLifecycle(
      AppLifecycleState.resumed,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    VelourAppEngagementTracker.instance.onAppLifecycle(
      AppLifecycleState.detached,
    );
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    VelourAppEngagementTracker.instance.onAppLifecycle(state);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Met à jour [VelourAppEngagementTracker.noteRoute] à chaque navigation.
final class VelourAnalyticsNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _note(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) {
      _note(previousRoute);
    }
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) {
      _note(newRoute);
    }
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  void _note(Route<dynamic> route) {
    final String? name = route.settings.name;
    VelourAppEngagementTracker.instance.noteRoute(
      name ?? route.runtimeType.toString(),
    );
  }
}
