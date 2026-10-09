import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Monitor's Gong (ADR 0017, "Ton"): a small interface so widget tests
/// can substitute a fake instead of touching real browser audio. Playback
/// is backed by `assets/sounds/gong.wav` (see `apps/web/tool/make_gong.py`).
abstract class AlarmSound {
  /// Unlocks audio playback for the current browser tab (autoplay policy):
  /// plays the asset once at volume 0. Called from the monitor's "Zum
  /// Aktivieren tippen" overlay tap, which is a genuine user gesture.
  Future<void> unlock();

  /// Plays the gong, once or [loop]ing until [stop] is called.
  Future<void> play({bool loop = false});

  /// Stops any ongoing playback.
  Future<void> stop();
}

/// [AlarmSound] backed by `package:audioplayers`.
class AudioPlayersAlarmSound implements AlarmSound {
  AudioPlayersAlarmSound() : _player = AudioPlayer();

  final AudioPlayer _player;

  static final _source = AssetSource('sounds/gong.wav');

  @override
  Future<void> unlock() async {
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setVolume(0);
    await _player.play(_source);
    await _player.stop();
    await _player.setVolume(1);
  }

  @override
  Future<void> play({bool loop = false}) async {
    await _player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
    await _player.setVolume(1);
    await _player.play(_source);
  }

  @override
  Future<void> stop() async {
    await _player.stop();
  }
}

/// The [AlarmSound] used by the monitor. Overridden in widget tests with a
/// fake implementation.
final alarmSoundProvider = Provider<AlarmSound>((ref) {
  final sound = AudioPlayersAlarmSound();
  ref.onDispose(() {
    unawaited(sound._player.dispose());
  });
  return sound;
});
