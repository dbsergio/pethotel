import 'package:flutter_test/flutter_test.dart';
import 'package:mypet_frontend/data/services/game_sync_service.dart';
import 'package:mypet_frontend/data/repositories/local_game_repository.dart';
import 'package:mypet_frontend/data/repositories/remote_game_repository.dart';
import 'package:mypet_frontend/data/local/game_state.dart';
import 'package:mypet_frontend/data/repositories/game_repository.dart';
import 'package:mypet_frontend/game/models/player.dart';
import 'package:mypet_frontend/game/models/pet.dart';
import 'package:mypet_frontend/game/models/pet_stats.dart';

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
  group('Shop and Consumption Tests', () {
    late GameState gameState;
    late Player player;

    setUp(() async {
      gameState = GameState(MockGameRepository(), MockGameSyncService());
      player = Player(id: 'test_player', coins: 100, inventory: {}, capacity: 4);
      player.activePets.add(Pet(id: 'pet_1', name: 'Toby', species: 'dog', stats: PetStats()..hunger = 50.0..hygiene = 50.0));
      gameState.player = player;
    });

    test('Successful purchase of a consumable item deducts coins and increases inventory', () async {
      bool result = await gameState.buyItem('food_basic'); // Costs 15
      expect(result, isTrue);
      expect(player.coins, 85);
      expect(gameState.getInventoryQuantity('food_basic'), 1);
    });

    test('Purchase fails if not enough coins (no partial changes)', () async {
      player.coins = 10;
      bool result = await gameState.buyItem('food_basic'); // Costs 15
      expect(result, isFalse);
      expect(player.coins, 10);
      expect(gameState.getInventoryQuantity('food_basic'), 0);
    });

    test('Purchase fails if item does not exist (no partial changes)', () async {
      bool result = await gameState.buyItem('invalid_item_id');
      expect(result, isFalse);
      expect(player.coins, 100);
    });

    test('Successful consumption of an item applies effect, does not exceed max, and removes from inventory', () async {
      // First give the player the item
      await gameState.addInventoryItem('food_basic', 1);
      
      bool result = await gameState.consumeItem('food_basic', 'pet_1');
      expect(result, isTrue);
      expect(gameState.getInventoryQuantity('food_basic'), 0);
      
      // Hunger was 50, effect is +100, max is 100
      expect(player.activePets.first.stats.hunger, 100.0);
    });

    test('Consumption fails if no units in inventory (no partial changes)', () async {
      bool result = await gameState.consumeItem('food_basic', 'pet_1');
      expect(result, isFalse);
      
      // Hunger should still be 50
      expect(player.activePets.first.stats.hunger, 50.0);
    });

    test('Consumption fails if pet does not exist (no partial changes)', () async {
      await gameState.addInventoryItem('food_basic', 1);
      
      bool result = await gameState.consumeItem('food_basic', 'invalid_pet');
      expect(result, isFalse);
      expect(gameState.getInventoryQuantity('food_basic'), 1);
    });

    test('Capacity upgrade increases capacity correctly', () async {
      player.coins = 500;
      bool result = await gameState.buyItem('upgrade_capacity_1'); // Costs 500, sets capacity to 5
      expect(result, isTrue);
      expect(player.coins, 0);
      expect(player.capacity, 5);
      expect(gameState.getInventoryQuantity('upgrade_capacity_1'), 1);
    });

    test('Cannot buy the same capacity upgrade twice (no partial changes)', () async {
      player.coins = 1000;
      await gameState.buyItem('upgrade_capacity_1');
      expect(player.capacity, 5);
      
      bool result = await gameState.buyItem('upgrade_capacity_1');
      expect(result, isFalse);
      expect(player.capacity, 5); // Remains 5
      expect(player.coins, 500); // Only deducted once
      expect(gameState.getInventoryQuantity('upgrade_capacity_1'), 1); // Quantity remains 1
    });
  });
}
