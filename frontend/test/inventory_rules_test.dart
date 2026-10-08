import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mypet_frontend/data/local/local_storage.dart';
import 'package:mypet_frontend/data/repositories/local_game_repository.dart';
import 'package:mypet_frontend/data/repositories/remote_game_repository.dart';
import 'package:mypet_frontend/data/services/game_sync_service.dart';
import 'package:mypet_frontend/game/models/player.dart';
import 'package:mypet_frontend/data/local/game_state.dart';

class MockRemoteRepo extends RemoteGameRepository {
  Player? mockPlayer;
  
  @override
  Future<Player?> loadRemotePlayer(String playerId) async {
    return mockPlayer;
  }
}

void main() {
  group('Inventario Inicial', () {
    late GameState gameState;
    late LocalGameRepository localRepo;
    late MockRemoteRepo remoteRepo;
    late GameSyncService syncService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'jwt_token': 'test_token'});
      await LocalStorage.init();
      localRepo = LocalGameRepository();
      remoteRepo = MockRemoteRepo();
      syncService = GameSyncService(localRepo: localRepo, remoteRepo: remoteRepo);
      gameState = GameState(localRepo, syncService);
    });

    test('Caso A: partida nueva -> recibe food_basic: 2, soap_basic: 1', () async {
      remoteRepo.mockPlayer = null;
      await gameState.loadPlayer('new_user');
      
      expect(gameState.player, isNotNull);
      expect(gameState.player!.inventory['food_basic'], 2);
      expect(gameState.player!.inventory['soap_basic'], 1);
    });

    test('Caso B: partida existente con inventario vacío -> recibe los objetos iniciales', () async {
      remoteRepo.mockPlayer = Player(id: 'user_b', inventory: {});
      await gameState.loadPlayer('user_b');
      
      expect(gameState.player, isNotNull);
      expect(gameState.player!.inventory['food_basic'], 2);
      expect(gameState.player!.inventory['soap_basic'], 1);
    });

    test('Caso C: partida existente con food_basic: 2 -> NO duplica objetos', () async {
      remoteRepo.mockPlayer = Player(id: 'user_c', inventory: {'food_basic': 2, 'soap_basic': 1});
      await gameState.loadPlayer('user_c');
      
      expect(gameState.player, isNotNull);
      expect(gameState.player!.inventory['food_basic'], 2); // No debe sumar 4
      expect(gameState.player!.inventory['soap_basic'], 1); // No debe sumar 2
    });

    test('Caso D: partida existente con cantidades distintas -> NO las sobrescribe', () async {
      remoteRepo.mockPlayer = Player(id: 'user_d', inventory: {'food_basic': 10, 'soap_basic': 0, 'toy': 1});
      await gameState.loadPlayer('user_d');
      
      expect(gameState.player, isNotNull);
      expect(gameState.player!.inventory['food_basic'], 10);
      expect(gameState.player!.inventory['soap_basic'], 0);
      expect(gameState.player!.inventory['toy'], 1);
    });
  });
}
