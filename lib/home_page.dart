import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:blocked/background/background.dart';
import 'package:blocked/level/level.dart';
import 'package:blocked/progress/progress.dart';
import 'package:blocked/routing/routing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:blocked/widgets/app_bottom_nav.dart';
import 'ADs/ad_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final assetsAudioPlayer = AssetsAudioPlayer();
  final adManager = AdManager();
  bool isMuted = false;

  @override
  void initState() {
    super.initState();
    adManager.addAds(true, true, false);

    assetsAudioPlayer.open(
      Audio('assets/audio/bmusic.mp3'),
      autoStart: true,
      volume: 1.0,
      loopMode: LoopMode.playlist,
    );
    WidgetsBinding.instance.addObserver(this);
  }

  Future<int> _totalLevelCount() async {
    final chapters = await readLevelsFromYaml();
    return chapters.fold<int>(0, (sum, chapter) => sum + chapter.levels.length);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    assetsAudioPlayer.dispose();
    adManager.disposeAds();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !isMuted) {
      assetsAudioPlayer.play();
    } else {
      assetsAudioPlayer.pause();
    }
  }

  void toggleMute() {
    setState(() {
      isMuted = !isMuted;
    });

    if (isMuted) {
      assetsAudioPlayer.setVolume(0.0);
    } else {
      assetsAudioPlayer.setVolume(1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppBottomNav(current: AppBottomTab.home),
        ],
      ),
      body: Stack(
        children: [
          const RotatingPuzzleBackground(),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 36, 20, 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Hero(
                      tag: 'app_title',
                      child: Text('BLOCKED', style: textTheme.displayMedium),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'SLIDE PUZZLE GAME',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 18),
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
                        return Row(
                          children: [
                            Expanded(
                              child: _InfoTile(
                                icon: Icons.local_fire_department_rounded,
                                label: 'Streak',
                                value: '${progress.currentStreak}',
                                tint: const Color(0xFF3A130F),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _InfoTile(
                                icon: Icons.emoji_events_rounded,
                                label: 'Solved',
                                value: '${progress.levelsSolved}',
                                tint: const Color(0xFF1C2208),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _InfoTile(
                                icon: Icons.star_rounded,
                                label: 'Stars',
                                value: '${progress.totalStars}',
                                tint: const Color(0xFF071D2C),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
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
                        return FutureBuilder<int>(
                          future: _totalLevelCount(),
                          builder: (context, totalSnapshot) {
                            final totalLevels = totalSnapshot.data ?? 1;
                            final ratio = totalLevels == 0
                                ? 0.0
                                : progress.levelsSolved / totalLevels;
                            return _OverallProgressCard(
                              solved: progress.levelsSolved,
                              totalLevels: totalLevels,
                              totalStars: progress.totalStars,
                              ratio: ratio.clamp(0.0, 1.0),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<List<String>>(
                      future: getFirstUncompletedLevel(),
                      builder: (context, snapshot) {
                        final next =
                            snapshot.data ?? const ['Basic 1', 'B_1-1'];
                        return _ContinueCard(
                          chapterName: next[0],
                          levelName: next[1],
                          onPlay: () {
                            context
                                .read<NavigatorCubit>()
                                .navigateToLevel(next[0], next[1]);
                          },
                        );
                      },
                    ),
                    // Hidden by request:
                    // Level / Editor / Settings / Stats quick cards.
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: toggleMute,
        shape: const CircleBorder(),
        child: Icon(
          isMuted ? Icons.volume_off : Icons.volume_up,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: tint,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.tertiary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({
    required this.chapterName,
    required this.levelName,
    required this.onPlay,
  });

  final String chapterName;
  final String levelName;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF220126), Color(0xFF2C022A)],
        ),
        border: Border.all(color: Theme.of(context).colorScheme.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CONTINUE PLAYING',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  letterSpacing: 3,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(levelName, style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 4),
          Text(
            '$chapterName - Move the main block to exit',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text('☆☆☆', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          SizedBox(
            width: 280,
            child: ElevatedButton.icon(
              icon: const Icon(MdiIcons.play),
              label: const Text('Play Level'),
              onPressed: onPlay,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverallProgressCard extends StatelessWidget {
  const _OverallProgressCard({
    required this.solved,
    required this.totalLevels,
    required this.totalStars,
    required this.ratio,
  });

  final int solved;
  final int totalLevels;
  final int totalStars;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9B5DFF), Color(0xFFFF2D78)],
                    ),
                  ),
                  child: const Icon(Icons.sports_esports,
                      color: Colors.black87, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Puzzle Master',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontSize: 15),
                      ),
                      Text(
                        'Solved $solved of $totalLevels levels',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Theme.of(context).colorScheme.secondary),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    '$totalStars ⭐',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text('Overall Progress',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.normal,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}






// import 'package:assets_audio_player/assets_audio_player.dart';
// // import 'package:audioplayers/audioplayers.dart';
// import 'package:blocked/background/background.dart';
// import 'package:blocked/progress/progress.dart';
// import 'package:blocked/routing/routing.dart';
// import 'package:flutter/material.dart';
// // import 'package:flex_color_scheme/flex_color_scheme.dart';
// // import 'package:google_fonts/google_fonts.dart';
// // import 'package:adaptive_theme/adaptive_theme.dart';
// // import 'package:blocked/models/models.dart';
// // import 'package:blocked/level/level.dart';
// // import 'package:blocked/settings/settings.dart';
// // import 'package:blocked/ADs/google%20ads%20integration.dart';
// // import 'package:blocked/routing/routing.dart';
// // import 'package:blocked/settings/settings.dart';
// // import 'package:flex_color_scheme/flex_color_scheme.dart';
// // import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
//
// import 'ADs/google ads integration.dart';
//
// // import 'ADs/google ads integration.dart';
//
//
// class HomePage extends StatefulWidget {
//   const HomePage({Key? key}) : super(key: key);
//
//   @override
//   State<HomePage> createState() => _HomePageState();
// }
//
//
// @override
//
// class _HomePageState extends State<HomePage> with WidgetsBindingObserver{
//   final assetsAudioPlayer = AssetsAudioPlayer();
//
//   @override
//   void initState() {
//     super.initState();
//
//     assetsAudioPlayer.open(
//       Audio('assets/audio/bmusic.mp3'),
//       autoStart: true,
//         volume: 1.0,
//         loopMode: LoopMode.playlist,
//     );
//     WidgetsBinding.instance.addObserver(this);
//   }
//
//
//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     assetsAudioPlayer.dispose();
//     super.dispose();
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) {
//       assetsAudioPlayer.play();
//     } else {
//       assetsAudioPlayer.pause();
//     }
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       bottomNavigationBar: MyHomePage(),
//       body: Stack(
//         children: [
//           const RotatingPuzzleBackground(),
//           Center(
//             child: SingleChildScrollView(
//               child: Center(
//                 child: ConstrainedBox(
//                   constraints: const BoxConstraints(maxWidth: 300),
//                   child: Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Hero(
//                           tag: 'app_title',
//                           child: Center(
//                             child: Text('Blocked',
//                                 style: Theme.of(context).textTheme.displayMedium),
//                           ),
//                         ),
//                         const SizedBox(height: 32),
//                         StreamBuilder<bool>(
//                           stream: hasProgressStream(),
//                           builder: (context, snapshot) {
//                             final hasProgress = snapshot.data ?? false;
//                             return ElevatedButton.icon(
//                               icon: const Icon(MdiIcons.play),
//                               label: Text(hasProgress ? 'Continue' : 'Start'),
//                               onPressed: () async {
//                                 ///ads here
//                                 // Navigator.push(context, MaterialPageRoute(builder: (context)=>MyHomePage()));
//                                 final level = await getFirstUncompletedLevel();
//                                 context
//                                     .read<NavigatorCubit>()
//                                     .navigateToLevel(level[0], level[1]);
//                               },
//                             );
//                           },
//                         ),
//                         const SizedBox(height: 8),
//                         OutlinedButton.icon(
//                           icon: const Icon(MdiIcons.viewGridOutline),
//                           label: const Text('Levels'),
//                           onPressed: () {
//                             context
//                                 .read<NavigatorCubit>()
//                                 .navigateToChapterSelection();
//                           },
//                         ),
//                         const SizedBox(height: 8),
//                         OutlinedButton.icon(
//                           icon: const Icon(MdiIcons.vectorSquareEdit),
//                           label: const Text('Editor'),
//                           onPressed: () {
//                             context.read<NavigatorCubit>().navigateToEditor();
//                           },
//                         ),
//                         const SizedBox(height: 8),
//                         OutlinedButton.icon(
//                           icon: const Icon(Icons.settings),
//                           label: const Text('Settings'),
//                           onPressed: () {
//                             context.read<NavigatorCubit>().navigateToSettings();
//                           },
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }