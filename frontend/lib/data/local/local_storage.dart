import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class LocalStorage {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String getPlayerId() {
    String? id = _prefs.getString('playerId');
    if (id == null) {
      id = const Uuid().v4();
      _prefs.setString('playerId', id);
    }
    return id;
  }
  
  static SharedPreferences get prefs => _prefs;
}
