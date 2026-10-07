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
  group('Pet Selection Tests', () {
    test('Selección directa por petId', () {
      final gameState = GameState(MockGameRepository(), MockGameSyncService());
      
      final toby = Pet(id: 'toby_1', name: 'Toby', species: 'dog', stats: PetStats());
      final luna = Pet(id: 'luna_2', name: 'Luna', species: 'cat', stats: PetStats());
      
      gameState.player = Player(id: 'player_1')..activePets.addAll([toby, luna]);

      expect(toby.id, isNot(luna.id));

      gameState.selectPetById(toby.id);
      expect(gameState.selectedPetId, toby.id);

      gameState.selectPetById(luna.id);
      expect(gameState.selectedPetId, luna.id);
    });

    test('Acción iniciada sobre Toby conserva Toby.id aunque la selección cambie a Luna', () async {
      final gameState = GameState(MockGameRepository(), MockGameSyncService());
      
      final toby = Pet(id: 'toby_1', name: 'Toby', species: 'dog', stats: PetStats());
      final luna = Pet(id: 'luna_2', name: 'Luna', species: 'cat', stats: PetStats());
      
      gameState.player = Player(id: 'player_1')..activePets.addAll([toby, luna]);

      // Seleccionar a Toby
      gameState.selectPetById(toby.id);
      
      // Iniciar acción sobre Toby (usando la selección actual de GameState)
      await gameState.feedPet();
      
      expect(toby.currentAction, PetAction.going_to_eat);
      
      // Cambiar la selección global a Luna
      gameState.selectPetById(luna.id);
      
      // La selección global ha cambiado
      expect(gameState.selectedPetId, luna.id);
      
      // Pero Toby sigue estando en la acción de "going_to_eat"
      expect(toby.currentAction, PetAction.going_to_eat);
      expect(luna.currentAction, PetAction.idle);
      
      // Completamos la acción explícitamente para Toby (emulando lo que hace ActionBehavior)
      await gameState.completeFeedPet(toby);
      
      // Verificamos que Toby cambió a comer y Luna sigue ociosa
      expect(toby.currentAction, PetAction.eating);
      expect(luna.currentAction, PetAction.idle);
    });
  });
}
