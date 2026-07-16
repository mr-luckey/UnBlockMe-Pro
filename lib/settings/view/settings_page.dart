import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:blocked/progress/progress.dart';
import 'package:blocked/puzzle/puzzle.dart';
import 'package:blocked/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:blocked/widgets/app_bottom_nav.dart';

import '../../ADs/ad_manager.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

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
            const ListTile(
              leading: Icon(Icons.dark_mode_rounded),
              title: Text('Theme'),
              subtitle: Text('Dark (fixed)'),
            ),
            const ListTile(
              leading: Icon(Icons.palette_rounded),
              title: Text('Color'),
              subtitle: Text('Carved Oak (fixed)'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 16.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: AspectRatio(
                    aspectRatio: 3 / 2,
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: BoardColor(
                        data: BoardColorData.fromColorScheme(
                            Theme.of(context).colorScheme),
                        child: const ThemeColorPreview(),
                      ),
                    ),
                  ),
                ),
              ),
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
