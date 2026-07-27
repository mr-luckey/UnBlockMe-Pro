import 'dart:async';

import 'package:blocked/audio/game_music.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

/// Soft SFX + haptics for gameplay / UI.
///
/// Android needs one silent `play()` to open the output track. That unlock
/// runs via [prewarm] while Home is idle (volume 0), so the first button
/// tap has no delay. SFX never steal BGM focus.
class GameFeel {
  GameFeel._();
  static final GameFeel instance = GameFeel._();

  static AudioPlayer _sfxPlayer() => AudioPlayer(
        handleInterruptions: false,
        androidApplyAudioAttributes: false,
        handleAudioSessionActivation: false,
      );

  final AudioPlayer _hit = _sfxPlayer();
  final AudioPlayer _slide = _sfxPlayer();
  final AudioPlayer _tap = _sfxPlayer();
  final AudioPlayer _win = _sfxPlayer();

  static const _hitVol = 0.55;
  static const _slideVol = 0.22;
  static const _tapVol = 0.28;
  static const _winVol = 0.45;

  bool _assetsReady = false;
  bool _engineUnlocked = false;
  bool _tapUnlocked = false;
  Future<void>? _initFuture;
  Future<void>? _unlockFuture;
  Future<void>? _tapUnlockFuture;

  Future<void> init() {
    return _initFuture ??= _doInit();
  }

  /// Silent unlock while Home is visible — first tap stays instant.
  Future<void> prewarm() async {
    await init();
    if (!_assetsReady) return;
    // Prioritize the tap player used by Home / nav buttons.
    await _unlockTap();
    unawaited(_unlockEngine());
  }

  Future<void> _doInit() async {
    if (_assetsReady) return;
    try {
      await Future.wait([
        _hit.setAsset('assets/audio/sfx_hit.wav'),
        _slide.setAsset('assets/audio/sfx_slide.wav'),
        _tap.setAsset('assets/audio/sfx_tap.wav'),
        _win.setAsset('assets/audio/sfx_win.wav'),
      ]);
      await Future.wait([
        _hit.setLoopMode(LoopMode.off),
        _slide.setLoopMode(LoopMode.off),
        _tap.setLoopMode(LoopMode.off),
        _win.setLoopMode(LoopMode.off),
      ]);
      await Future.wait([
        _hit.setVolume(_hitVol),
        _slide.setVolume(_slideVol),
        _tap.setVolume(_tapVol),
        _win.setVolume(_winVol),
      ]);
      _assetsReady = true;
    } catch (e) {
      _initFuture = null;
      // ignore: avoid_print
      print('[Feel] sfx init failed: $e');
    }
  }

  bool get _muted => GameMusic.instance.muted.value;

  Future<void> _unlockTap() {
    return _tapUnlockFuture ??= _doUnlockTap();
  }

  Future<void> _doUnlockTap() async {
    if (_tapUnlocked) return;
    try {
      await _silentPulse(_tap);
      await _tap.setVolume(_tapVol);
      _tapUnlocked = true;
    } catch (e) {
      _tapUnlockFuture = null;
      // ignore: avoid_print
      print('[Feel] tap unlock failed: $e');
    }
  }

  Future<void> _unlockEngine() {
    return _unlockFuture ??= _doUnlock();
  }

  Future<void> _doUnlock() async {
    if (_engineUnlocked) return;
    try {
      await Future.wait([
        _silentPulse(_hit).then((_) => _hit.setVolume(_hitVol)),
        _silentPulse(_slide).then((_) => _slide.setVolume(_slideVol)),
        _silentPulse(_win).then((_) => _win.setVolume(_winVol)),
      ]);
      _engineUnlocked = true;
    } catch (e) {
      _unlockFuture = null;
      // ignore: avoid_print
      print('[Feel] unlock failed: $e');
    }
  }

  Future<void> _silentPulse(AudioPlayer player) async {
    await player.setVolume(0);
    await player.seek(Duration.zero);
    await player.play();
    await Future<void>.delayed(const Duration(milliseconds: 25));
    await player.stop();
    await player.seek(Duration.zero);
  }

  Future<void> _play(AudioPlayer player, double volume) async {
    if (_muted) return;

    if (!_assetsReady) {
      try {
        await init().timeout(const Duration(seconds: 3));
      } catch (_) {}
      if (!_assetsReady || _muted) return;
    }

    // Home taps only need the tap player unlocked.
    if (identical(player, _tap)) {
      if (!_tapUnlocked) await _unlockTap();
    } else if (!_engineUnlocked) {
      await _unlockTap();
      await _unlockEngine();
    }
    if (_muted) return;

    try {
      await player.setVolume(volume);
      await player.seek(Duration.zero);
      await player.play();
    } catch (_) {}
  }

  void blockHit() {
    HapticFeedback.mediumImpact();
    Future<void>.delayed(const Duration(milliseconds: 40), () {
      HapticFeedback.heavyImpact();
    });
    unawaited(_play(_hit, _hitVol));
  }

  void blockSlide() {
    HapticFeedback.lightImpact();
    unawaited(_play(_slide, _slideVol));
  }

  void tap() {
    HapticFeedback.selectionClick();
    unawaited(_play(_tap, _tapVol));
  }

  void win() {
    HapticFeedback.heavyImpact();
    Future<void>.delayed(const Duration(milliseconds: 70), () {
      HapticFeedback.mediumImpact();
    });
    unawaited(_play(_win, _winVol));
  }
}
