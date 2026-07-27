import 'dart:async';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:blocked/ADs/ad_manager.dart';
import 'package:blocked/audio/game_feel.dart';
import 'package:blocked/audio/game_music.dart';
import 'package:blocked/level/level.dart';
import 'package:blocked/models/models.dart';
import 'package:blocked/routing/routing.dart';
import 'package:blocked/settings/settings.dart';
import 'package:blocked/theme/theme.dart';
import 'package:blocked/theme/theme_presets.dart';
import 'package:blocked/widgets/app_exit_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load during native splash only — no second Flutter splash screen.
  final results = await Future.wait<dynamic>([
    readLevelsFromYaml(),
    getSavedColor(),
  ]);
  runApp(BlockedApp(
    chapters: results[0] as List<LevelChapter>,
    savedThemeColor: results[1] as Color?,
  ));
}

ThemeData createThemeWithBrightness(Color primary, Brightness brightness) {
  return createBlockedTheme(brightness, accent: primary);
}

class BlockedApp extends StatefulWidget {
  const BlockedApp({
    Key? key,
    required this.chapters,
    required this.savedThemeColor,
  }) : super(key: key);

  final List<LevelChapter> chapters;
  final Color? savedThemeColor;

  @override
  State<BlockedApp> createState() => _BlockedAppState();
}

class _BlockedAppState extends State<BlockedApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey();
  final NavigatorCubit navigatorCubit =
      NavigatorCubit(const AppRoutePath.home());

  @override
  void initState() {
    super.initState();
    // Defer all heavy IO until after the first home frame paints.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(GameMusic.instance.init());
      unawaited(GameFeel.instance.init());
      unawaited(GameMusic.instance.ensurePlaying());
      Future<void>.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        unawaited(
          AdManager().bootstrap(
            interstitial: true,
            banner: true,
            rewarded: true,
          ),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ThemeColorBloc(
          widget.savedThemeColor ?? ThemePresets.all.first.primary),
      child: BlocBuilder<ThemeColorBloc, ThemeColorState>(
        buildWhen: (previous, current) => previous.color != current.color,
        builder: (context, state) {
          return AdaptiveTheme(
            light: createThemeWithBrightness(state.color, Brightness.light),
            dark: createThemeWithBrightness(state.color, Brightness.dark),
            initial: AdaptiveThemeMode.dark,
            builder: (theme, darkTheme) =>
                BlocListener<ThemeColorBloc, ThemeColorState>(
              listenWhen: (previous, current) =>
                  previous.color != current.color,
              listener: (context, state) {
                AdaptiveTheme.of(context).setTheme(
                  light:
                      createThemeWithBrightness(state.color, Brightness.light),
                  dark: createThemeWithBrightness(state.color, Brightness.dark),
                );
              },
              child: OutlinedButtonTheme(
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
                  builder: (context, child) {
                    return AppExitScope(
                      navigatorKey: navigatorKey,
                      navigatorCubit: navigatorCubit,
                      child: child ?? const SizedBox.shrink(),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
