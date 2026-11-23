import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import 'storage_service.dart';

/// Sound effects and vibration, following the player's Settings.
///
/// Why two ways to vibrate: on Android, Flutter's HapticFeedback depends on the phone's
/// own "vibrate on touch" setting and is often silent, so we use the vibration package there.
/// On iPhone, HapticFeedback gives the nicer, native "tap" feeling.
class GameFeedback {
  static final _players = <String, AudioPlayer>{}; // one player per sound, made once and reused

  static StorageService get _settings => StorageService.instance;

  static Future<void> _play(String file, {double volume = 1}) async {
    if (!_settings.sound) return;
    try {
      final player = _players.putIfAbsent(file, AudioPlayer.new);
      await player.stop(); // restart if the same sound is still playing
      await player.play(AssetSource('sounds/$file'), volume: volume, mode: PlayerMode.lowLatency);
    } catch (_) {
      // A sound that cannot play must never stop the game.
    }
  }

  static Future<void> _buzz(int milliseconds, {int strength = 128}) async {
    if (!_settings.vibration || kIsWeb) return;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await Vibration.vibrate(duration: milliseconds, amplitude: strength);
      } else {
        await HapticFeedback.mediumImpact();
      }
    } catch (_) {
      // Some devices have no vibration motor.
    }
  }

  /// Piece lifted from the tray.
  static void pick() => _play('pick.wav', volume: 0.6);

  /// Piece clicked into its place.
  static void snap() {
    _play('snap.wav');
    _buzz(35, strength: 180);
  }

  /// Piece dropped in the wrong place.
  static void miss() => _buzz(15, strength: 60);

  static void hint() {
    _play('hint.wav');
    _buzz(25);
  }

  /// Puzzle finished.
  static void win() {
    _play('win.wav');
    _buzz(150, strength: 255);
  }
}
