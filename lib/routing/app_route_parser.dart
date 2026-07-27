import 'package:blocked/routing/routing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppRouteParser extends RouteInformationParser<AppRoutePath> {
  @override
  Future<AppRoutePath> parseRouteInformation(
      RouteInformation routeInformation) {
    return SynchronousFuture(_parseRouteInformationSync(routeInformation));
  }

  AppRoutePath _parseRouteInformationSync(RouteInformation routeInformation) {
    if (routeInformation.location == null) {
      return const AppRoutePath.home();
    }
    final uri = Uri.parse(routeInformation.location!);
    final pathSegments =
        uri.pathSegments.where((segment) => segment.isNotEmpty).toList();

    if (pathSegments.isEmpty) {
      return const AppRoutePath.home();
    }

    final firstSegment = pathSegments.first;
    if (firstSegment == 'levels') {
      if (pathSegments.length == 1) {
        return const LevelRoutePath.chapterSelection();
      } else if (pathSegments.length == 2) {
        // Old chapter URLs → map
        return const LevelRoutePath.chapterSelection();
      } else if (pathSegments.length == 3) {
        return LevelRoutePath.level(
            chapterName: pathSegments[1], levelName: pathSegments[2]);
      }
    } else if (firstSegment == 'settings') {
      return const AppRoutePath.settings();
    }

    return const AppRoutePath.home();
  }

  @override
  RouteInformation? restoreRouteInformation(AppRoutePath configuration) {
    return RouteInformation(location: configuration.location);
  }
}
