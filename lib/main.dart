import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:blocked/ADs/ad_manager.dart';
import 'package:blocked/level/level.dart';
import 'package:blocked/models/models.dart';
import 'package:blocked/routing/routing.dart';
import 'package:blocked/theme/theme.dart';
// import 'package:facebook_audience_network/facebook_audience_network.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AdManager();
  // FacebookAudienceNetwork.init();
  await MobileAds.instance.initialize();
  final levels = await readLevelsFromYaml();
  runApp(BlockedApp(chapters: levels));
}

class BlockedApp extends StatefulWidget {
  const BlockedApp({
    Key? key,
    required this.chapters,
  }) : super(key: key);

  final List<LevelChapter> chapters;

  @override
  State<BlockedApp> createState() => _BlockedAppState();
}

class _BlockedAppState extends State<BlockedApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey();
  final NavigatorCubit navigatorCubit =
      NavigatorCubit(const AppRoutePath.home());

  @override
  Widget build(BuildContext context) {
    final theme = createBlockedTheme(Brightness.light);
    final darkTheme = createBlockedTheme(Brightness.dark);
    return AdaptiveTheme(
      light: theme,
      dark: darkTheme,
      initial: AdaptiveThemeMode.dark,
      builder: (theme, darkTheme) => OutlinedButtonTheme(
        data: OutlinedButtonThemeData(
          style: theme.outlinedButtonTheme.style?.merge(
            OutlinedButton.styleFrom(
              backgroundColor: theme.colorScheme.surface,
            ),
          ),
        ),
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Blocked',
          theme: theme,
          darkTheme: darkTheme,
          routeInformationParser: AppRouteParser(),
          routerDelegate: AppRouterDelegate(
            chapters: widget.chapters,
            navigatorKey: navigatorKey,
            navigatorCubit: navigatorCubit,
          ),
        ),
      ),
    );
  }
}
