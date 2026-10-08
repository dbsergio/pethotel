import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mypet_frontend/data/local/local_storage.dart';
import 'package:mypet_frontend/data/repositories/local_game_repository.dart';
import 'package:mypet_frontend/data/repositories/remote_game_repository.dart';
import 'package:mypet_frontend/data/services/game_sync_service.dart';
import 'package:mypet_frontend/game/models/player.dart';
import 'package:mypet_frontend/data/local/game_state.dart';
// ignore: depend_on_referenced_packages
import 'package:mypet_frontend/data/services/game_sync_service.dart' as import_game_sync;

void main() {
  group('Sincronización Rules', () {
    late LocalGameRepository localRepo;
    late RemoteGameRepository remoteRepo;
    late GameSyncService syncService;
    late GameState gameState;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'jwt_token': 'test', 'playerId': 'u1'});
      await LocalStorage.init();
      localRepo = LocalGameRepository();
      remoteRepo = RemoteGameRepository();
      syncService = GameSyncService(localRepo: localRepo, remoteRepo: remoteRepo);
      gameState = GameState(localRepo, syncService);
      gameState.player = Player(id: 'u1', revision: 1, inventory: {});
      await localRepo.savePlayer(gameState.player!);
    });

    test('Caso E: cambio local -> sync_pending = true', () async {
      await gameState.addCoins(10); // Modifica el estado y llama a save()
      
      expect(LocalStorage.prefs.getBool('sync_pending'), isTrue);
      expect(syncService.status, import_game_sync.SyncStatus.pending);
    });

    test('Caso F: HTTP 200 -> sync_pending = false', () async {
      // Setup a mock client for LocalGameRepository
      await gameState.addCoins(10);
      expect(LocalStorage.prefs.getBool('sync_pending'), isTrue);

      final client = MockClient((request) async {
        return http.Response(jsonEncode({'status': 'OK', 'save': {'revision': 2}}), 200);
      });
      localRepo.httpClient = client;
      
      await localRepo.syncPending();
      
      expect(LocalStorage.prefs.getBool('sync_pending'), isFalse);
    });

    test('Caso G: error de red/HTTP -> permanece pendiente', () async {
      await gameState.addCoins(10);
      expect(LocalStorage.prefs.getBool('sync_pending'), isTrue);

      final client = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });
      localRepo.httpClient = client;
      
      await localRepo.syncPending();
      
      expect(LocalStorage.prefs.getBool('sync_pending'), isTrue);
    });

    test('Caso H: 409 Conflict -> se mantiene la estrategia', () async {
      await gameState.addCoins(10);

      final client = MockClient((request) async {
        return http.Response(jsonEncode({'status': 'CONFLICT', 'serverSave': {}}), 409);
      });
      localRepo.httpClient = client;
      
      await localRepo.syncPending();
      
      expect(LocalStorage.prefs.getBool('sync_pending'), isTrue); // conflict leaves it pending
      expect(LocalStorage.prefs.getBool('sync_conflict'), isTrue);
    });
  });
}
