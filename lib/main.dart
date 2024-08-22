import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:blocked/ADs/ad_manager.dart';
import 'package:blocked/level/level.dart';
import 'package:blocked/models/models.dart';
import 'package:blocked/routing/routing.dart';
import 'package:blocked/settings/settings.dart';
import 'package:facebook_audience_network/facebook_audience_network.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AdManager();
  FacebookAudienceNetwork.init();
  // MobileAds.instance.initialize();
  final levels = await readLevelsFromYaml();
  final savedThemeMode = await AdaptiveTheme.getThemeMode();
  final savedThemeColor = await getSavedColor();
  runApp(BlockedApp(
    chapters: levels,
    savedThemeMode: savedThemeMode,
    savedThemeColor: savedThemeColor,
  ));
}

ThemeData createThemeWithBrightness(Color primary, Brightness brightness) {
  final colorScheme =
      ColorScheme.fromSeed(seedColor: primary, brightness: brightness);

  final themeData = brightness == Brightness.light
      ? FlexThemeData.light(
          colors: FlexSchemeColor.from(
            primary: colorScheme.primary,
            secondary: colorScheme.tertiary,
          ),
          // useSubThemes: true,
          blendLevel: 16,
          fontFamily: GoogleFonts.dmSans().fontFamily,
          subThemesData: const FlexSubThemesData(
            buttonPadding: EdgeInsets.all(16),
            textButtonRadius: 8,
            outlinedButtonRadius: 8,
            elevatedButtonRadius: 8,
          ),
          appBarStyle: FlexAppBarStyle.surface,
          surfaceMode: FlexSurfaceMode.highBackgroundLowScaffold,
        )
      : FlexThemeData.dark(
          colors: FlexSchemeColor.from(
            primary: colorScheme.primary,
            secondary: colorScheme.tertiary,
          ),
          // useSubThemes: true,
          blendLevel: 16,
          fontFamily: GoogleFonts.dmSans().fontFamily,
          subThemesData: const FlexSubThemesData(
            buttonPadding: EdgeInsets.all(16),
            textButtonRadius: 8,
            outlinedButtonRadius: 8,
            elevatedButtonRadius: 8,
          ),
          appBarStyle: FlexAppBarStyle.surface,
          surfaceMode: FlexSurfaceMode.highBackgroundLowScaffold,
        );

  return themeData;
}

class BlockedApp extends StatefulWidget {
  const BlockedApp({
    Key? key,
    required this.chapters,
    required this.savedThemeMode,
    required this.savedThemeColor,
  }) : super(key: key);

  final List<LevelChapter> chapters;
  final AdaptiveThemeMode? savedThemeMode;
  final Color? savedThemeColor;

  @override
  State<BlockedApp> createState() => _BlockedAppState();
}

class _BlockedAppState extends State<BlockedApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey();
  final NavigatorCubit navigatorCubit =
      NavigatorCubit(const AppRoutePath.home());
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ThemeColorBloc(widget.savedThemeColor ?? Colors.green),
      child: BlocBuilder<ThemeColorBloc, ThemeColorState>(
        buildWhen: (previous, current) => previous.color != current.color,
        builder: (context, state) {
          return AdaptiveTheme(
            light: createThemeWithBrightness(state.color, Brightness.light),
            dark: createThemeWithBrightness(state.color, Brightness.dark),
            initial: widget.savedThemeMode ?? AdaptiveThemeMode.system,
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
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
