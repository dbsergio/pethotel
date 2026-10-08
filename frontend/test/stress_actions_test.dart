import 'package:flutter_test/flutter_test.dart';
import 'package:mypet_frontend/data/services/game_sync_service.dart';
import 'package:mypet_frontend/data/repositories/local_game_repository.dart';
import 'package:mypet_frontend/data/repositories/remote_game_repository.dart';
import 'package:mypet_frontend/data/local/game_state.dart';
import 'package:mypet_frontend/data/repositories/game_repository.dart';
import 'package:mypet_frontend/game/models/pet.dart';
import 'package:mypet_frontend/game/models/pet_stats.dart';
import 'package:mypet_frontend/game/models/player.dart';

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
  group('Pet Actions Stress Tests (State Machine Bug Fixes)', () {
    late GameState gameState;
    late Pet toby;
    late Pet luna;

    setUp(() {
      gameState = GameState(MockGameRepository(), MockGameSyncService());
      toby = Pet(
        id: 'toby',
        name: 'Toby',
        species: 'dog',
        stats: PetStats(),
      );
      luna = Pet(
        id: 'luna',
        name: 'Luna',
        species: 'cat',
        stats: PetStats(),
      );
      gameState.player = Player(id: 'test_player')..activePets.addAll([toby, luna]);
    });

    test('10 ciclos masivos de todas las acciones', () async {
      gameState.selectPetById(toby.id);

      for (int i = 0; i < 10; i++) {
        // Comer
        await gameState.feedPet();
        expect(toby.currentAction, PetAction.going_to_eat);
        await gameState.completeFeedPet(toby);
        gameState.endAction(toby);

        // Beber
        await gameState.drinkPet();
        expect(toby.currentAction, PetAction.going_to_drink);
        await gameState.completeDrinkPet(toby);
        gameState.endAction(toby);

        // Jugar
        await gameState.playWithPet();
        expect(toby.currentAction, PetAction.going_to_play);
        await gameState.completePlayWithPet(toby);
        gameState.endAction(toby);

        // Bañar
        await gameState.bathePet();
        expect(toby.currentAction, PetAction.going_to_bath);
        await gameState.completeBathePet(toby);
        gameState.endAction(toby);

        // Dormir
        await gameState.sleepPet();
        expect(toby.currentAction, PetAction.going_to_sleep);
        await gameState.completeSleepPet(toby);
        gameState.endAction(toby);

        // Pasear
        await gameState.walkPet();
        expect(toby.currentAction, PetAction.going_to_walk);
        await gameState.completeWalkPet(toby);
        gameState.endAction(toby);

        // Mimos
        await gameState.petPet();
        expect(toby.currentAction, PetAction.petting);
        gameState.endAction(toby);
      }
      
      expect(toby.currentAction, PetAction.idle);
    });

    test('Prueba repetida de una misma acción', () async {
      gameState.selectPetById(toby.id);

      for (int i = 0; i < 20; i++) {
        await gameState.feedPet();
        await gameState.completeFeedPet(toby);
        gameState.endAction(toby);
      }
      for (int i = 0; i < 20; i++) {
        await gameState.playWithPet();
        await gameState.completePlayWithPet(toby);
        gameState.endAction(toby);
      }
      for (int i = 0; i < 20; i++) {
        await gameState.walkPet();
        await gameState.completeWalkPet(toby);
        gameState.endAction(toby);
      }
      
      expect(toby.currentAction, PetAction.idle);
    });

    test('Prueba con dos mascotas simultáneamente', () async {
      // Simulate parallel actions by doing partial state transitions
      gameState.selectPetById(toby.id);
      await gameState.feedPet();
      
      gameState.selectPetById(luna.id);
      await gameState.drinkPet();

      expect(toby.currentAction, PetAction.going_to_eat);
      expect(luna.currentAction, PetAction.going_to_drink);

      await gameState.completeFeedPet(toby);
      await gameState.completeDrinkPet(luna);

      gameState.endAction(toby);
      gameState.endAction(luna);

      expect(toby.currentAction, PetAction.idle);
      expect(luna.currentAction, PetAction.idle);
    });

    test('Prueba de cambio de selección durante Mimos', () async {
      gameState.selectPetById(toby.id);
      // Start petting Toby
      final future = gameState.petPet();
      expect(toby.currentAction, PetAction.petting);
      
      // Immediately switch to Luna
      gameState.selectPetById(luna.id);
      await gameState.playWithPet();
      
      expect(luna.currentAction, PetAction.going_to_play);
      expect(toby.currentAction, PetAction.petting);
      
      // Wait for petting to finish
      await future;
      await Future.delayed(const Duration(seconds: 3));
      
      // Toby should have properly resolved to idle
      expect(toby.currentAction, PetAction.idle);
      
      // Luna should still be playing
      expect(luna.currentAction, PetAction.going_to_play);
    });

    test('Cancelación de acción en curso al solicitar nueva acción', () async {
      gameState.selectPetById(toby.id);
      
      // 1. Iniciar acción A (Comer)
      await gameState.feedPet();
      expect(toby.currentAction, PetAction.going_to_eat);
      
      // 2. Iniciar acción B (Bañar) inmediatamente (simulando que aún no llegó al bowl)
      await gameState.bathePet();
      
      // El state debería ser PetAction.going_to_bath porque la anterior fue cancelada por _requestAction
      expect(toby.currentAction, PetAction.going_to_bath);
      
      // 3. Completar acción B
      await gameState.completeBathePet(toby);
      gameState.endAction(toby);
      
      expect(toby.currentAction, PetAction.idle);
    });
  });
}
