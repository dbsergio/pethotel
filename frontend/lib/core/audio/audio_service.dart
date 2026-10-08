import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService extends ChangeNotifier {
  static const String _sfxKey = 'sfx_enabled';
  static const String _musicKey = 'music_enabled';
  
  bool _sfxEnabled = true;
  bool _musicEnabled = true;
  bool _isBgmPlaying = false;

  bool get sfxEnabled => _sfxEnabled;
  bool get musicEnabled => _musicEnabled;

  AudioService() {
    _loadPreferences();
    _preloadAssets();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sfxEnabled = prefs.getBool(_sfxKey) ?? true;
      _musicEnabled = prefs.getBool(_musicKey) ?? true;
      notifyListeners();
    } catch(e) {
      debugPrint('Error loading audio prefs: $e');
    }
  }

  Future<void> _preloadAssets() async {
    try {
      await FlameAudio.audioCache.loadAll([
        'ui_tap.ogg', 'ui_select.ogg', 'ui_open.ogg', 'ui_close.ogg', 'ui_error.ogg',
        'eat.mp3', 'drink.mp3', 'bath_bubbles.mp3', 'water_splash.mp3',
        'play.mp3', 'pet.mp3', 'coin_reward.mp3', 'success.mp3', 'purchase.mp3',
        'dog_happy.mp3', 'cat_meow.mp3', 'bgm_nursery.mp3'
      ]);
    } catch (e) {
      debugPrint('Audio preload error: $e');
    }
  }

  Future<void> toggleSfx() async {
    _sfxEnabled = !_sfxEnabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_sfxKey, _sfxEnabled);
    } catch(e) {
      // Ignored
    }
    if (_sfxEnabled) playUiTap();
    notifyListeners();
  }

  Future<void> toggleMusic() async {
    _musicEnabled = !_musicEnabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_musicKey, _musicEnabled);
    } catch(e) {
      // Ignored
    }
    
    if (!_musicEnabled) {
      stopBgm();
    } else {
      playBgm();
    }
    notifyListeners();
  }

  void playSfx(String filename, {double volume = 0.5}) {
    if (!_sfxEnabled) return;
    try {
      FlameAudio.play(filename, volume: volume);
    } catch (e) {
      debugPrint('Error playing SFX $filename: $e');
    }
  }

  void playBgm([String filename = 'bgm_nursery.mp3']) {
    if (!_musicEnabled || _isBgmPlaying) return;
    try {
      // Evitar que FlameAudio inicialice en Flutter Web si el navegador lo bloquea (autoplay policies)
      // Aunque FlameAudio ya gestiona bien el play diferido, controlamos la variable
      FlameAudio.bgm.play(filename, volume: 0.2); // BGM bajo
      _isBgmPlaying = true;
    } catch (e) {
      debugPrint('Error playing BGM $filename: $e');
      _isBgmPlaying = false;
    }
  }

  void stopBgm() {
    try {
      FlameAudio.bgm.stop();
      _isBgmPlaying = false;
    } catch (e) {
      debugPrint('Error stopping BGM: $e');
    }
  }

  // UI (bajo/medio: 0.3)
  void playUiTap() => playSfx('ui_tap.ogg', volume: 0.3);
  void playUiSelect() => playSfx('ui_select.ogg', volume: 0.3);
  void playUiOpen() => playSfx('ui_open.ogg', volume: 0.3);
  void playUiClose() => playSfx('ui_close.ogg', volume: 0.3);
  void playUiError() => playSfx('ui_error.ogg', volume: 0.3);
  
  // Acciones (medio: 0.5)
  void playActionEat() => playSfx('eat.mp3', volume: 0.5);
  void playActionDrink() => playSfx('drink.mp3', volume: 0.5);
  void playActionBath() {
    playSfx('water_splash.mp3', volume: 0.4);
    playSfx('bath_bubbles.mp3', volume: 0.5);
  }
  void playActionPlay() => playSfx('play.mp3', volume: 0.5);
  void playActionPetting() => playSfx('pet.mp3', volume: 0.5);
  
  // Recompensas (ligeramente superior: 0.6)
  void playRewardCoins() => playSfx('coin_reward.mp3', volume: 0.6);
  void playSuccess() => playSfx('success.mp3', volume: 0.6);
  void playShopPurchase() => playSfx('purchase.mp3', volume: 0.6);

  // Mascotas (bajo: 0.2)
  void playDogHappy() => playSfx('dog_happy.mp3', volume: 0.2);
  void playCatMeow() => playSfx('cat_meow.mp3', volume: 0.2);
}
