import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:blocked/background/background.dart';
import 'package:blocked/progress/progress.dart';
import 'package:blocked/routing/routing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
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
    adManager.addAds(true, true, true);

    assetsAudioPlayer.open(
      Audio('assets/audio/bmusic.mp3'),
      autoStart: true,
      volume: 1.0,
      loopMode: LoopMode.playlist,
    );
    WidgetsBinding.instance?.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
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
    return Scaffold(
      bottomNavigationBar: Container(
        alignment: Alignment.center,
        child: AdWidget(ad: adManager.getBannerAd()!),
        width: adManager.getBannerAd()?.size.width.toDouble(),
        height: adManager.getBannerAd()?.size.height.toDouble(),
      ),

      ///integration here
      body: Stack(
        children: [
          const RotatingPuzzleBackground(),
          Center(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Hero(
                          tag: 'app_title',
                          child: Center(
                            child: Text(
                              'Blocked',
                              style: Theme.of(context).textTheme.displayMedium,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        StreamBuilder<bool>(
                          stream: hasProgressStream(),
                          builder: (context, snapshot) {
                            final hasProgress = snapshot.data ?? false;
                            return ElevatedButton.icon(
                              icon: const Icon(MdiIcons.play),
                              label: Text(hasProgress ? 'Continue' : 'Start'),
                              onPressed: () async {
                                final level = await getFirstUncompletedLevel();
                                context
                                    .read<NavigatorCubit>()
                                    .navigateToLevel(level[0], level[1]);
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          icon: const Icon(MdiIcons.viewGridOutline),
                          label: const Text('Levels'),
                          onPressed: () {
                            context
                                .read<NavigatorCubit>()
                                .navigateToChapterSelection();
                          },
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          icon: const Icon(MdiIcons.vectorSquareEdit),
                          label: const Text('Editor'),
                          onPressed: () {
                            context.read<NavigatorCubit>().navigateToEditor();
                          },
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.settings),
                          label: const Text('Settings'),
                          onPressed: () {
                            context.read<NavigatorCubit>().navigateToSettings();
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: toggleMute,
        backgroundColor:
            Colors.green.shade800, // Replace with your desired background color
        foregroundColor:
            Colors.white, // Replace with your desired foreground (icon) color
        elevation: 2.0, // Customize the elevation if needed
        shape: CircleBorder(),
        child: Icon(
          isMuted ? Icons.volume_off : Icons.volume_up,
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