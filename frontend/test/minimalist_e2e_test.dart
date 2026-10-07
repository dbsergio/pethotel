import 'package:flutter_test/flutter_test.dart';
import 'package:mypet_frontend/data/services/game_sync_service.dart';
import 'package:mypet_frontend/data/repositories/local_game_repository.dart';
import 'package:mypet_frontend/data/repositories/remote_game_repository.dart';
import 'package:mypet_frontend/data/local/game_state.dart';
import 'package:mypet_frontend/data/repositories/game_repository.dart';
import 'package:mypet_frontend/game/models/player.dart';
import 'package:mypet_frontend/game/models/pet.dart';
import 'package:mypet_frontend/game/models/pet_stats.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockGameRepository implements GameRepository {
  @override
  Future<Player?> loadPlayer(String playerId) async => null;
  @override
  Future<void> savePlayer(Player player) async {}
}

class MockGameSyncService extends GameSyncService {
  MockGameSyncService() : super(localRepo: LocalGameRepository(), remoteRepo: RemoteGameRepository());
  @override
  void markPending() {}
  @override
  Future<void> syncNow() async {}
}

void main() {
  test('Test Minimalista (E2E Logic Flow): Comer', () async {
    // 1. Setup
    SharedPreferences.setMockInitialValues({});
    final gameState = GameState(MockGameRepository(), MockGameSyncService());
    
    // Add pet and select it
    gameState.player = Player(id: 'test_player')..activePets.addAll([
      Pet(id: 't1', name: 'Toby', species: 'dog', stats: PetStats()..hunger = 50.0)
    ]);
    final pet = gameState.player!.activePets.first;
    gameState.selectPet(pet);

    // Initial stats
    final initialHunger = pet.stats.hunger;
    final initialEnergy = pet.stats.energy;

    // 2. Trigger Action (Simulating UI button press)
    await gameState.feedPet();

    expect(pet.currentAction, PetAction.going_to_eat);
    expect(pet.currentActionId, isNotNull);

    // 3. Simulating completion of ActionBehavior timer
    // In the real game, ActionBehavior waits X seconds then calls completeFeedPet
    await gameState.completeFeedPet(pet);
    gameState.endAction(pet);

    // 4. Verify stats consequences
    expect(pet.stats.hunger, greaterThan(initialHunger), reason: 'Hunger should increase');
    // Eating usually takes a bit of energy or has other effects
    // We just check that the action properly cleared and changed stats.
    
    expect(pet.currentAction, PetAction.idle, reason: 'Pet should return to idle');
    expect(pet.currentActionId, isNull, reason: 'Action should be cleared');
  });
}
