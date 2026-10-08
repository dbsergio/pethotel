import 'dart:convert';
import 'package:http/http.dart' as http;
import '../local/local_storage.dart';
import '../../game/models/player.dart';
import 'game_repository.dart';

import '../../core/config/app_config.dart';

class LocalGameRepository implements GameRepository {
  final String _playerKey = 'player_data';
  final String _syncUrl = '${AppConfig.baseUrl}/api/game/save';

  http.Client httpClient = http.Client();

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
    
    // Adopt newer revision from background syncs if it exists
    final currentJsonStr = prefs.getString('${_playerKey}_${player.id}');
    if (currentJsonStr != null) {
      try {
        final Map<String, dynamic> currentLocalJson = jsonDecode(currentJsonStr);
        final int prefsRev = currentLocalJson['revision'] as int? ?? player.revision;
        if (prefsRev > player.revision) {
          player.revision = prefsRev;
        }
      } catch (_) {}
    }

    final jsonStr = jsonEncode(player.toJson());
    await prefs.setString('${_playerKey}_${player.id}', jsonStr);
    
    // Marcar como pendiente de sync
    await prefs.setBool('sync_pending', true);
  }

  Future<void> syncPending() async {
    final prefs = LocalStorage.prefs;
    final isPending = prefs.getBool('sync_pending') ?? false;
    
    if (!isPending) return;
    
    final playerId = prefs.getString('playerId');
    if (playerId == null) return;
    
    final player = await loadPlayer(playerId);
    if (player == null) return;
    
    try {
      print('--- SYNC DEBUG START ---');
      print('playerId: $playerId');
      print('client player.revision: ${player.revision}');
      
      final token = prefs.getString('jwt_token');
      final headers = {'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final jsonStrToSend = jsonEncode(player.toJson());
      final response = await httpClient.post(
        Uri.parse(_syncUrl),
        headers: headers,
        body: jsonStrToSend,
      );
      
      print('Response statusCode: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 'OK') {
          // Sync successful. The server incremented the revision.
          final serverSave = json['save'];
          final newRevision = serverSave['revision'] as int;
          
          bool localChangedDuringSync = false;
          final currentLocalJsonStr = prefs.getString('${_playerKey}_$playerId');
          if (currentLocalJsonStr != null) {
            final Map<String, dynamic> currentLocalJson = jsonDecode(currentLocalJsonStr);
            
            // Check if local state changed during the HTTP request (ignoring revision)
            final Map<String, dynamic> sentJsonMap = jsonDecode(jsonStrToSend);
            sentJsonMap.remove('revision');
            final Map<String, dynamic> currentLocalMapCheck = Map.from(currentLocalJson);
            currentLocalMapCheck.remove('revision');
            if (jsonEncode(sentJsonMap) != jsonEncode(currentLocalMapCheck)) {
              localChangedDuringSync = true;
            }

            currentLocalJson['revision'] = newRevision;
            await prefs.setString('${_playerKey}_$playerId', jsonEncode(currentLocalJson));
          }
          
          if (!localChangedDuringSync) {
            await prefs.setBool('sync_pending', false);
          }
          await prefs.setBool('sync_conflict', false);
        } else if (json['status'] == 'CONFLICT') {
          await prefs.setBool('sync_conflict', true);
          await prefs.setString('conflict_data', response.body);
        }
      } else if (response.statusCode == 409) {
        print('CONFLICT DETECTED! Body: ${response.body}');
        await prefs.setBool('sync_conflict', true);
        await prefs.setString('conflict_data', response.body);
      }
      print('--- SYNC DEBUG END ---');
    } catch (e) {
      // Ignorar error de red, se reintentará luego
    }
  }
}

