import 'package:audio_session/audio_session.dart';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Soft looping calm background music for the whole app.
class GameMusic with WidgetsBindingObserver {
  GameMusic._();
  static final GameMusic instance = GameMusic._();

  static const _asset = 'assets/audio/bgm_forest.wav';
  static const _prefsKey = 'music.muted';
  static const _softVolume = 1.0;

  final AudioPlayer _player = AudioPlayer();
  final ValueNotifier<bool> muted = ValueNotifier<bool>(false);

  bool _pausedByLifecycle = false;
  Future<void>? _initFuture;

  Future<void> init() {
    return _initFuture ??= _doInit();
  }

  Future<void> _doInit() async {
    WidgetsBinding.instance.addObserver(this);

    final prefs = await SharedPreferences.getInstance();
    muted.value = prefs.getBool(_prefsKey) ?? false;

    try {
      final session = await AudioSession.instance;
      await session.configure(
        const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.ambient,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.mixWithOthers,
          avAudioSessionMode: AVAudioSessionMode.defaultMode,
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.music,
            usage: AndroidAudioUsage.game,
          ),
          // Keep BGM running when short SFX play on top.
          androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
          androidWillPauseWhenDucked: false,
        ),
      );

      await _player.setAudioSource(AudioSource.asset(_asset));
      await _player.setLoopMode(LoopMode.one);
      await _player.setVolume(muted.value ? 0 : _softVolume);

      if (!muted.value) {
        await _player.play();
      }
      debugPrint('[Music] calm BGM playing (muted=${muted.value})');
    } catch (e, st) {
      _initFuture = null;
      debugPrint('[Music] init failed: $e\n$st');
    }
  }

  /// Safe to call again — rebinds the current BGM asset (cache-bust on change).
  Future<void> ensurePlaying() async {
    await init();
    if (muted.value || _pausedByLifecycle) return;
    try {
      await _player.setAudioSource(AudioSource.asset(_asset));
      await _player.setLoopMode(LoopMode.one);
      await _player.setVolume(_softVolume);
      await _player.play();
    } catch (_) {
      _initFuture = null;
      await init();
    }
  }

  Future<void> toggleMute() async {
    await setMuted(!muted.value);
  }

  Future<void> setMuted(bool value) async {
    muted.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
    await _player.setVolume(value ? 0 : _softVolume);
    if (value) {
      await _player.pause();
    } else if (!_pausedByLifecycle) {
      await _player.play();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _pausedByLifecycle = false;
        if (!muted.value) {
          _player.play();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _pausedByLifecycle = true;
        _player.pause();
        break;
    }
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    muted.dispose();
    await _player.dispose();
    _initFuture = null;
  }
}
