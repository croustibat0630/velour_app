import 'package:flutter/material.dart';

/// Global RouteObserver to detect "return to screen" (didPopNext).
final RouteObserver<PageRoute<dynamic>> velourRouteObserver =
    RouteObserver<PageRoute<dynamic>>();

