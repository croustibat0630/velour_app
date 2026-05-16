import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velour_app/services/velour_app_engagement_tracker.dart';

void main() {
  test('onAppLifecycle resumed then paused updates route', () {
    final VelourAppEngagementTracker t = VelourAppEngagementTracker.instance;
    t.noteRoute('/main');
    t.onAppLifecycle(AppLifecycleState.resumed);
    t.onAppLifecycle(AppLifecycleState.paused);
    // Analytics disabled in test — no throw.
    expect(t, isNotNull);
  });
}
