import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../game/models/player.dart';
import '../local/local_storage.dart';

import '../../core/config/app_config.dart';

class RemoteGameRepository {
  final String baseUrl = AppConfig.baseUrl;

  Future<Player?> loadRemotePlayer(String playerId) async {
    try {
      final token = LocalStorage.prefs.getString('jwt_token');
      final headers = {'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final response = await http.get(
        Uri.parse('$baseUrl/api/game/save/$playerId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        return Player.fromJson(json);
      }
    } catch (e) {
      // Ignorar errores de red
    }
    return null;
  }
}
