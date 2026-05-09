import 'package:flutter/material.dart';

import 'velour_session_trace.dart';

/// Journalise chaque transition de route quand [VelourSessionTrace.enabled].
class SessionTraceNavigatorObserver extends NavigatorObserver {
  String _label(Route<dynamic>? r) {
    if (r == null) return 'null';
    final Object? n = r.settings.name;
    if (n is String && n.isNotEmpty) return n;
    return r.runtimeType.toString();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    VelourSessionTrace.log(
      'nav.didPush',
      data: <String, Object?>{
        'route': _label(route),
        'prev': _label(previousRoute),
      },
    );
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    VelourSessionTrace.log(
      'nav.didPop',
      data: <String, Object?>{
        'popped': _label(route),
        'nowTop': _label(previousRoute),
      },
    );
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    VelourSessionTrace.log(
      'nav.didReplace',
      data: <String, Object?>{
        'newRoute': _label(newRoute),
        'oldRoute': _label(oldRoute),
      },
    );
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    VelourSessionTrace.log(
      'nav.didRemove',
      data: <String, Object?>{
        'removed': _label(route),
        'prev': _label(previousRoute),
      },
    );
  }
}
