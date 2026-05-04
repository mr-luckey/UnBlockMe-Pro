import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:blocked/main.dart';
import 'package:blocked/progress/progress.dart';
import 'package:blocked/puzzle/puzzle.dart';
import 'package:blocked/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:blocked/widgets/app_bottom_nav.dart';

import '../../ADs/ad_manager.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  static const List<Color> colors = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
  ];

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final adManager = AdManager();

  @override
  void initState() {
    super.initState();
    adManager.addAds(true, true, false);
  }

  @override
  void dispose() {
    adManager.disposeAds();
    super.dispose();
  }

  final assetsAudioPlayer = AssetsAudioPlayer();
  @override
  Widget build(BuildContext context) {
    final settingsContext = context;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ValueListenableBuilder<AdaptiveThemeMode>(
              valueListenable: AdaptiveTheme.of(context).modeChangeNotifier,
              builder: (_, mode, child) {
                return ListTile(
                  leading: const Icon(Icons.brush_rounded),
                  title: const Text('Theme'),
                  subtitle: Text(mode.name),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: const Text('Theme'),
                        children: [
                          SimpleDialogOption(
                            child: const Text('System'),
                            onPressed: () {
                              AdaptiveTheme.of(context).setSystem();
                              Navigator.pop(context);
                            },
                          ),
                          SimpleDialogOption(
                            child: const Text('Light'),
                            onPressed: () {
                              AdaptiveTheme.of(context).setLight();
                              Navigator.pop(context);
                            },
                          ),
                          SimpleDialogOption(
                            child: const Text('Dark'),
                            onPressed: () {
                              AdaptiveTheme.of(context).setDark();
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const ListTile(
              title: Text('Color'),
              leading: Icon(Icons.palette_rounded),
            ),
            GridView.builder(
              padding:
                  const EdgeInsetsDirectional.fromSTEB(68.0, 16.0, 16.0, 16.0),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 256,
                childAspectRatio: 3 / 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              itemCount: SettingsPage.colors.length,
              itemBuilder: (context, index) {
                final color = SettingsPage.colors[index];

                return Builder(builder: (context) {
                  final isSelected = context.select((ThemeColorBloc bloc) =>
                      bloc.state.color.value == color.value);
                  return OutlinedButton(
                    onPressed: () {
                      /// todo ads integraation here
                      context
                          .read<ThemeColorBloc>()
                          .add(ThemeColorChanged(SettingsPage.colors[index]));
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 8.0),
                    ),
                    child: Stack(
                      alignment: AlignmentDirectional.bottomEnd,
                      children: [
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: BoardColor(
                              data: BoardColorData.fromColorScheme(
                                  createThemeWithBrightness(
                                          color, Theme.of(context).brightness)
                                      .colorScheme),
                              child: const ThemeColorPreview(),
                            ),
                          ),
                        ),
                        if (isSelected)
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2.0,
                              ),
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.check,
                                size: 32.0,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                });
              },
            ),
            const Divider(),
            StreamBuilder<PlayerProgress>(
              stream: playerProgressStream(),
              builder: (context, snapshot) {
                final progress = snapshot.data ??
                    const PlayerProgress(
                      totalStars: 0,
                      levelsSolved: 0,
                      currentStreak: 0,
                      bestStreak: 0,
                    );
                return ListTile(
                  leading: const Icon(Icons.bar_chart_rounded),
                  title: Text(
                    'Stars ${progress.totalStars} | Solved ${progress.levelsSolved}',
                  ),
                  subtitle: Text(
                    'Streak ${progress.currentStreak} (best ${progress.bestStreak})',
                  ),
                );
              },
            ),
            const Divider(),
            // ListTile(
            //   leading: Icon(isMuted ? Icons.volume_up : Icons.volume_off),
            //   title:  Text('Mute Music'),
            //   onTap: () {
            //     muteMusic();
            //
            //     /// music mute integration here
            //   }
            // ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Clear progress'),
              onTap: () async {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear progress'),
                    content: const Text('Are you sure? This cannot be undone.'),
                    actions: [
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      TextButton(
                        child: const Text('Clear'),
                        onPressed: () async {
                          await clearData();
                          ScaffoldMessenger.of(settingsContext).showSnackBar(
                            const SnackBar(
                              content: Text('Progress cleared'),
                            ),
                          );
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppBottomNav(current: AppBottomTab.settings),
        ],
      ),
    );
  }
}
