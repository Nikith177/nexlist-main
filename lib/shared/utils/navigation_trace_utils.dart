import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void _printNavigationTarget(String location) {
  if (location == '/home') {
    print('NAVIGATION: going to HOME');
  } else if (location == '/login') {
    print('NAVIGATION: going to LOGIN');
  }
}

extension NavigationTraceExtensions on BuildContext {
  void tracedGo(String location, {Object? extra}) {
    _printNavigationTarget(location);
    print('NAVIGATION: context.go -> $location');
    go(location, extra: extra);
  }

  Future<T?> tracedPush<T extends Object?>(String location, {Object? extra}) {
    _printNavigationTarget(location);
    print('NAVIGATION: context.push -> $location');
    return push<T>(location, extra: extra);
  }
}

void tracedGoBranch(
  StatefulNavigationShell navigationShell,
  int index, {
  required bool initialLocation,
}) {
  print(
    'NAVIGATION: navigationShell.goBranch -> index=$index, initialLocation=$initialLocation',
  );
  navigationShell.goBranch(index, initialLocation: initialLocation);
}
