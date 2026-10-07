import 'package:flutter_test/flutter_test.dart';
import 'package:mypet_frontend/data/local/game_state.dart';
import 'package:mypet_frontend/data/repositories/game_repository.dart';
import 'package:mypet_frontend/game/models/pet.dart';
import 'package:mypet_frontend/game/models/pet_stats.dart';
import 'package:mypet_frontend/game/models/player.dart';
import 'package:mypet_frontend/data/services/game_sync_service.dart';
import 'package:mypet_frontend/data/repositories/local_game_repository.dart';
import 'package:mypet_frontend/data/repositories/remote_game_repository.dart';

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
  group('Pet Actions Isolation Tests', () {
    late GameState gameState;
    late Pet pet;

    setUp(() {
      gameState = GameState(MockGameRepository(), MockGameSyncService());
      pet = Pet(
        id: 'test_pet',
        name: 'Toby',
        species: 'dog',
        stats: PetStats(hunger: 50.0, thirst: 50.0, energy: 50.0, happiness: 50.0, hygiene: 50.0),
      );
      gameState.player = Player(id: 'test_player')..activePets.add(pet);
      gameState.selectPetById(pet.id);
    });

    test('Comer increases ONLY hunger and happiness', () async {
      final initialHunger = pet.stats.hunger;
      final initialHappiness = pet.stats.happiness;
      final initialThirst = pet.stats.thirst;
      final initialEnergy = pet.stats.energy;
      final initialHygiene = pet.stats.hygiene;

      await gameState.completeFeedPet(pet);
      
      expect(pet.stats.hunger, initialHunger + 20);
      expect(pet.stats.happiness, initialHappiness + 3);
      expect(pet.stats.thirst, initialThirst);
      expect(pet.stats.energy, initialEnergy);
      expect(pet.stats.hygiene, initialHygiene);
    });

    test('Beber increases ONLY thirst and happiness', () async {
      final initialHunger = pet.stats.hunger;
      final initialHappiness = pet.stats.happiness;
      final initialThirst = pet.stats.thirst;
      final initialEnergy = pet.stats.energy;
      final initialHygiene = pet.stats.hygiene;

      await gameState.completeDrinkPet(pet);
      
      expect(pet.stats.thirst, initialThirst + 30);
      expect(pet.stats.happiness, initialHappiness + 2);
      expect(pet.stats.hunger, initialHunger);
      expect(pet.stats.energy, initialEnergy);
      expect(pet.stats.hygiene, initialHygiene);
    });

    test('Jugar increases happiness and decreases energy', () async {
      final initialHunger = pet.stats.hunger;
      final initialHappiness = pet.stats.happiness;
      final initialThirst = pet.stats.thirst;
      final initialEnergy = pet.stats.energy;
      final initialHygiene = pet.stats.hygiene;

      await gameState.completePlayWithPet(pet);
      
      expect(pet.stats.happiness, initialHappiness + 15);
      expect(pet.stats.energy, initialEnergy - 10);
      expect(pet.stats.hunger, initialHunger);
      expect(pet.stats.thirst, initialThirst);
      expect(pet.stats.hygiene, initialHygiene);
    });

    test('Bañar increases ONLY hygiene', () async {
      final initialHunger = pet.stats.hunger;
      final initialHappiness = pet.stats.happiness;
      final initialThirst = pet.stats.thirst;
      final initialEnergy = pet.stats.energy;
      final initialHygiene = pet.stats.hygiene;

      await gameState.completeBathePet(pet);
      
      expect(pet.stats.hygiene, initialHygiene + 30);
      expect(pet.stats.hunger, initialHunger);
      expect(pet.stats.thirst, initialThirst);
      expect(pet.stats.energy, initialEnergy);
      expect(pet.stats.happiness, initialHappiness);
    });

    test('Dormir increases ONLY energy', () async {
      final initialHunger = pet.stats.hunger;
      final initialHappiness = pet.stats.happiness;
      final initialThirst = pet.stats.thirst;
      final initialEnergy = pet.stats.energy;
      final initialHygiene = pet.stats.hygiene;

      await gameState.completeSleepPet(pet);
      
      expect(pet.stats.energy, initialEnergy + 30);
      expect(pet.stats.hunger, initialHunger);
      expect(pet.stats.thirst, initialThirst);
      expect(pet.stats.hygiene, initialHygiene);
      expect(pet.stats.happiness, initialHappiness);
    });
    
    test('Pasear increases happiness, decreases energy and hygiene', () async {
      final initialHunger = pet.stats.hunger;
      final initialHappiness = pet.stats.happiness;
      final initialThirst = pet.stats.thirst;
      final initialEnergy = pet.stats.energy;
      final initialHygiene = pet.stats.hygiene;

      await gameState.completeWalkPet(pet);
      
      expect(pet.stats.happiness, initialHappiness + 20);
      expect(pet.stats.energy, initialEnergy - 15);
      expect(pet.stats.hygiene, initialHygiene - 5);
      expect(pet.stats.hunger, initialHunger);
      expect(pet.stats.thirst, initialThirst);
    });
  });
}
