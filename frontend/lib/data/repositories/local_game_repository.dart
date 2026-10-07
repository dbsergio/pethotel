import 'dart:convert';
import 'package:http/http.dart' as http;
import '../local/local_storage.dart';
import '../../game/models/player.dart';
import 'game_repository.dart';

class LocalGameRepository implements GameRepository {
  final String _playerKey = 'player_data';
  // En dev puede ser http://localhost:8080/api/game/sync
  // En prod se usará la URL de render. Dejamos localhost por defecto para desarrollo.
  final String _syncUrl = const String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8080/api/game/sync');

  @override
  Future<Player?> loadPlayer(String playerId) async {
    final prefs = LocalStorage.prefs;
    final jsonStr = prefs.getString('${_playerKey}_$playerId');
    if (jsonStr != null) {
      try {
        final Map<String, dynamic> json = jsonDecode(jsonStr);
        return Player.fromJson(json);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> savePlayer(Player player) async {
    final prefs = LocalStorage.prefs;
    final jsonStr = jsonEncode(player.toJson());
    await prefs.setString('${_playerKey}_${player.id}', jsonStr);
    
    // Marcar como pendiente de sync
    await prefs.setBool('sync_pending', true);
  }

  @override
  Future<void> syncPending() async {
    final prefs = LocalStorage.prefs;
    final isPending = prefs.getBool('sync_pending') ?? false;
    
    if (!isPending) return;
    
    final playerId = prefs.getString('playerId');
    if (playerId == null) return;
    
    final player = await loadPlayer(playerId);
    if (player == null) return;
    
    try {
      final payload = {
        'player': {
          'id': player.id,
          'coins': player.coins,
          'nurseryLevel': player.nurseryLevel,
        },
        'pets': player.activePets.map((p) => p.toJson()).toList(),
      };
      
      final response = await http.post(
        Uri.parse(_syncUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      
      if (response.statusCode == 200) {
        await prefs.setBool('sync_pending', false);
      }
    } catch (e) {
      // Ignoramos error, se reintentará luego porque sync_pending sigue en true
    }
  }
}

