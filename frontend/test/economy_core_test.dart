import 'package:flutter_test/flutter_test.dart';
import 'package:mypet_frontend/data/services/game_sync_service.dart';
import 'package:mypet_frontend/data/repositories/local_game_repository.dart';
import 'package:mypet_frontend/data/repositories/remote_game_repository.dart';
import 'package:mypet_frontend/data/local/game_state.dart';
import 'package:mypet_frontend/data/repositories/game_repository.dart';
import 'package:mypet_frontend/game/models/player.dart';

class MockGameRepository implements GameRepository {
  Player? _player;
  @override
  Future<Player?> loadPlayer(String playerId) async => _player;
  @override
  Future<void> savePlayer(Player player) async {
    _player = player;
  }
}

class MockGameSyncService extends GameSyncService {
  MockGameSyncService() : super(localRepo: LocalGameRepository(), remoteRepo: RemoteGameRepository());
  @override
  void markPending() {}
  @override
  Future<void> syncNow() async {}
}

void main() {
  group('Economy and Inventory Core Tests', () {
    late GameState gameState;

    setUp(() async {
      gameState = GameState(MockGameRepository(), MockGameSyncService());
      gameState.player = Player(id: 'test_player', coins: 100, inventory: {});
    });

    test('addCoins increases coins and prevents negative amounts', () async {
      await gameState.addCoins(50);
      expect(gameState.player!.coins, 150);

      await gameState.addCoins(-10); // Should be ignored
      expect(gameState.player!.coins, 150);
    });

    test('deductCoins decreases coins only if sufficient balance exists', () async {
      bool result1 = await gameState.deductCoins(40);
      expect(result1, isTrue);
      expect(gameState.player!.coins, 60);

      bool result2 = await gameState.deductCoins(100);
      expect(result2, isFalse);
      expect(gameState.player!.coins, 60);

      bool result3 = await gameState.deductCoins(-10); // Should be ignored (hasCoins checks < 0)
      expect(result3, isFalse);
      expect(gameState.player!.coins, 60);
    });

    test('addInventoryItem and getInventoryQuantity work correctly', () async {
      await gameState.addInventoryItem('food_basic', 2);
      expect(gameState.getInventoryQuantity('food_basic'), 2);

      await gameState.addInventoryItem('food_basic', 3);
      expect(gameState.getInventoryQuantity('food_basic'), 5);

      await gameState.addInventoryItem('soap_basic', -1); // Should be ignored
      expect(gameState.getInventoryQuantity('soap_basic'), 0);
    });

    test('removeInventoryItem works and cleans up zero-quantity keys', () async {
      await gameState.addInventoryItem('soap_basic', 3);
      
      bool result1 = await gameState.removeInventoryItem('soap_basic', 2);
      expect(result1, isTrue);
      expect(gameState.getInventoryQuantity('soap_basic'), 1);

      bool result2 = await gameState.removeInventoryItem('soap_basic', 5);
      expect(result2, isFalse);
      expect(gameState.getInventoryQuantity('soap_basic'), 1);

      bool result3 = await gameState.removeInventoryItem('soap_basic', 1);
      expect(result3, isTrue);
      expect(gameState.getInventoryQuantity('soap_basic'), 0);
      expect(gameState.player!.inventory.containsKey('soap_basic'), isFalse, reason: 'Key should be removed when quantity is 0');
    });
  });
}
