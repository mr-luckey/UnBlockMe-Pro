import 'package:blocked/routing/routing.dart';
import 'package:collection/collection.dart';
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
    } else {
      final firstSegment = pathSegments.first;
      if (firstSegment == 'levels') {
        if (pathSegments.length == 1) {
          return const LevelRoutePath.chapterSelection();
        } else if (pathSegments.length == 2) {
          return LevelRoutePath.levelSelection(chapterName: pathSegments[1]);
        } else if (pathSegments.length == 3) {
          return LevelRoutePath.level(
              chapterName: pathSegments[1], levelName: pathSegments[2]);
        }
      } else if (firstSegment == 'editor') {
        final secondSegment = pathSegments.skip(1).firstOrNull;
        if (secondSegment == 'generated') {
          // Try to fetch map string
          final thirdSegment = pathSegments.skip(2).firstOrNull;
          if (thirdSegment != null) {
            return EditorRoutePath.generatedLevel(
                decodeMapString(thirdSegment));
          }
        }

        String mapString;
        try {
          mapString = decodeMapString(secondSegment ?? '');
        } on Object {
          mapString = '';
        }
        return EditorRoutePath.editor(mapString);
      }
    }
    return const AppRoutePath.home();
  }

  @override
  RouteInformation? restoreRouteInformation(AppRoutePath configuration) {
    return RouteInformation(location: configuration.location);
  }
}
