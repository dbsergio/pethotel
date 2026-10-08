import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService extends ChangeNotifier {
  static const String _sfxKey = 'sfx_enabled';
  static const String _musicKey = 'music_enabled';
  
  bool _sfxEnabled = true;
  bool _musicEnabled = true;

  // IMPORTANT: Set to true when actual audio assets are placed in assets/audio/
  // and configured in pubspec.yaml. Until then, the AudioService intercepts calls
  // to avoid crashes.
  static const bool _hasRealAssets = false;

  bool get sfxEnabled => _sfxEnabled;
  bool get musicEnabled => _musicEnabled;

  AudioService() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _sfxEnabled = prefs.getBool(_sfxKey) ?? true;
    _musicEnabled = prefs.getBool(_musicKey) ?? true;
    notifyListeners();
  }

  Future<void> toggleSfx() async {
    _sfxEnabled = !_sfxEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sfxKey, _sfxEnabled);
    if (_sfxEnabled) playUiTap();
    notifyListeners();
  }

  Future<void> toggleMusic() async {
    _musicEnabled = !_musicEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_musicKey, _musicEnabled);
    
    if (!_musicEnabled) {
      stopBgm();
    } else {
      playBgm();
    }
    notifyListeners();
  }

  void playSfx(String filename) {
    if (!_sfxEnabled || !_hasRealAssets) return;
    try {
      FlameAudio.play(filename);
    } catch (e) {
      debugPrint('Error playing SFX $filename: $e');
    }
  }

  void playBgm([String filename = 'bgm_nursery.mp3']) {
    if (!_musicEnabled || !_hasRealAssets) return;
    try {
      FlameAudio.bgm.play(filename);
    } catch (e) {
      debugPrint('Error playing BGM $filename: $e');
    }
  }

  void stopBgm() {
    if (!_hasRealAssets) return;
    try {
      FlameAudio.bgm.stop();
    } catch (e) {
      debugPrint('Error stopping BGM: $e');
    }
  }

  // Pre-defined sound vocabulary
  void playUiTap() => playSfx('ui_tap.mp3');
  void playUiOpen() => playSfx('ui_open.mp3');
  void playUiClose() => playSfx('ui_close.mp3');
  void playUiError() => playSfx('ui_error.mp3');
  
  void playActionEat() => playSfx('action_eat.mp3');
  void playActionDrink() => playSfx('action_drink.mp3');
  void playActionBath() => playSfx('action_bath.mp3');
  void playActionPlay() => playSfx('action_play.mp3');
  void playActionPetting() => playSfx('action_petting.mp3');
  void playActionSleep() => playSfx('action_sleep.mp3');
  
  void playRewardCoins() => playSfx('reward_coins.mp3');
  void playRewardStay() => playSfx('reward_stay.mp3');
  void playShopPurchase() => playSfx('shop_purchase.mp3');
}
