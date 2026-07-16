import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:blocked/background/background.dart';
import 'package:blocked/level/level.dart';
import 'package:blocked/progress/progress.dart';
import 'package:blocked/routing/routing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

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
          // Soft radial wash behind the header so the vivid title/badge has
          // some depth instead of sitting flat on the plain surface color.
          Positioned(
            top: -60,
            left: -40,
            right: -40,
            child: IgnorePointer(
              child: Container(
                height: 260,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      colors.primary.withOpacity(0.16),
                      colors.primary.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- Header: icon badge + title + tagline, mute
                      // button moved up here (out of a floating, easy-to-miss
                      // corner FAB) so the whole top reads as one unit.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            colors.primary,
                                            colors.tertiary
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                colors.primary.withOpacity(0.4),
                                            blurRadius: 16,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: Icon(Icons.extension_rounded,
                                          color: colors.onPrimary, size: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Hero(
                                        tag: 'app_title',
                                        child: Material(
                                          type: MaterialType.transparency,
                                          child: Text(
                                            'BLOCKED',
                                            style: textTheme.displayMedium,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colors.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: colors.primary.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    'SLIDE PUZZLE GAME',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colors.primary,
                                      letterSpacing: 2,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _CircleIconButton(
                            icon: isMuted
                                ? Icons.volume_off_rounded
                                : Icons.volume_up_rounded,
                            onTap: toggleMute,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // --- Stat tiles: real accent colors (not washed-out
                      // Material container tones) so they read as game UI,
                      // not a settings screen.
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
                                  accent: colors.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _InfoTile(
                                  icon: Icons.emoji_events_rounded,
                                  label: 'Solved',
                                  value: '${progress.levelsSolved}',
                                  accent: colors.secondary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _InfoTile(
                                  icon: Icons.star_rounded,
                                  label: 'Stars',
                                  value: '${progress.totalStars}',
                                  accent: colors.tertiary,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // --- Overall progress: gradient-filled bar instead of
                      // the flat default LinearProgressIndicator.
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

                      // --- Continue Playing: the hero CTA. Real stars for
                      // that level instead of a hardcoded "☆☆☆" placeholder.
                      FutureBuilder<List<String>>(
                        future: getFirstUncompletedLevel(),
                        builder: (context, snapshot) {
                          final next =
                              snapshot.data ?? const ['Basic 1', 'B_1-1'];
                          return FutureBuilder<int>(
                            future: getLevelStars(next[1]),
                            builder: (context, starSnapshot) {
                              return _ContinueCard(
                                chapterName: next[0],
                                levelName: next[1],
                                stars: starSnapshot.data ?? 0,
                                onPlay: () {
                                  context
                                      .read<NavigatorCubit>()
                                      .navigateToLevel(next[0], next[1]);
                                },
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.surface,
        border: Border.all(color: colors.outline.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Icon(icon, color: colors.onSurface, size: 20),
          ),
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
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withOpacity(0.18), accent.withOpacity(0.05)],
        ),
        border: Border.all(color: accent.withOpacity(0.32)),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.14),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(0.18),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outline.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [colors.secondary, colors.tertiary],
                  ),
                ),
                child: Icon(Icons.sports_esports,
                    color: colors.onSecondary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Puzzle Master', style: theme.textTheme.titleMedium),
                    Text(
                      'Solved $solved of $totalLevels levels',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.tertiary.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: colors.tertiary.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: colors.tertiary, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$totalStars',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colors.tertiary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Overall Progress',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                '${(ratio * 100).round()}%',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                Container(
                  height: 12,
                  color: colors.outline.withOpacity(0.15),
                ),
                FractionallySizedBox(
                  widthFactor: ratio,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colors.primary, colors.tertiary],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({
    required this.chapterName,
    required this.levelName,
    required this.stars,
    required this.onPlay,
  });

  final String chapterName;
  final String levelName;
  final int stars;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.tertiary],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(0.42),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative watermark — reinforces "puzzle game" without adding
          // another image asset.
          Positioned(
            right: -24,
            bottom: -24,
            child: Icon(
              Icons.extension_rounded,
              size: 150,
              color: colors.onPrimary.withOpacity(0.12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.onPrimary.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'CONTINUE PLAYING',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onPrimary,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  levelName,
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$chapterName · Move the marked block to the exit',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onPrimary.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(
                    3,
                    (index) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.star_rounded,
                        size: 20,
                        color: index < stars
                            ? colors.onPrimary
                            : colors.onPrimary.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.onPrimary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: onPlay,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_arrow_rounded,
                                color: colors.primary, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'Play Level',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
