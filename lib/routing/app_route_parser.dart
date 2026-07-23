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
    final uri = routeInformation.uri;
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
        final secondSegment =
            pathSegments.length > 1 ? pathSegments[1] : null;
        if (secondSegment == 'generated') {
          final thirdSegment =
              pathSegments.length > 2 ? pathSegments[2] : null;
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
    return RouteInformation(uri: Uri.parse(configuration.location));
  }
}
