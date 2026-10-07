import '../../game/models/player.dart';
import '../../game/models/pet.dart';
import '../repositories/game_repository.dart';
import 'package:flutter/foundation.dart';

class GameState extends ChangeNotifier {
  Player? player;
  final GameRepository repository;

  GameState(this.repository);

  /// Public wrapper so Flame components (non-ChangeNotifier) can trigger UI refresh
  void requestNotify() => notifyListeners();

  Future<void> loadPlayer(String playerId) async {
    player = await repository.loadPlayer(playerId);
    if (player == null) {
      player = Player(id: playerId);
      await repository.savePlayer(player!);
    }
    notifyListeners();
  }

  Future<void> save() async {
    if (player != null) {
      await repository.savePlayer(player!);
      // Attempt sync
      repository.syncPending();
    }
  }

  Pet? selectedPet;

  Future<void> selectPet(Pet pet) async {
    selectedPet = pet;
    notifyListeners();
  }

  Future<void> adoptPet(Pet pet) async {
    if (player != null) {
      if (player!.activePets.length >= player!.capacity) return;
      player!.activePets.add(pet);
      selectedPet = pet;
      await save();
      notifyListeners();
    }
  }
  bool _canAct(Pet pet) {
    return pet.currentAction == PetAction.idle || pet.currentAction == PetAction.walking;
  }

  void _requestAction(Pet pet, PetAction intent) {
    if (_canAct(pet)) {
      pet.currentAction = intent;
      notifyListeners();
    }
  }

  Future<void> feedPet() async {
    if (selectedPet != null) _requestAction(selectedPet!, PetAction.going_to_eat);
  }
  Future<void> completeFeedPet(Pet pet) async {
    pet.stats.hunger += 20;
    pet.stats.happiness += 3;
    pet.stats.clamp();
    pet.currentActionMessage = '+20 Hambre';
    pet.currentAction = PetAction.eating; // Update to actual eating
    await save();
    notifyListeners();
  }

  Future<void> drinkPet() async {
    if (selectedPet != null) _requestAction(selectedPet!, PetAction.going_to_drink);
  }
  Future<void> completeDrinkPet(Pet pet) async {
    pet.stats.thirst += 30;
    pet.stats.happiness += 2;
    pet.stats.clamp();
    pet.currentActionMessage = '+30 Sed';
    pet.currentAction = PetAction.drinking;
    await save();
    notifyListeners();
  }

  Future<void> playWithPet() async {
    if (selectedPet != null) _requestAction(selectedPet!, PetAction.going_to_play);
  }
  Future<void> completePlayWithPet(Pet pet) async {
    pet.stats.happiness += 15;
    pet.stats.energy -= 10;
    pet.stats.clamp();
    pet.currentActionMessage = '+15 Feliz';
    pet.currentAction = PetAction.playing;
    await save();
    notifyListeners();
  }

  Future<void> bathePet() async {
    if (selectedPet != null) _requestAction(selectedPet!, PetAction.going_to_bath);
  }
  Future<void> completeBathePet(Pet pet) async {
    pet.stats.hygiene += 30;
    pet.stats.clamp();
    pet.currentActionMessage = '+30 Limpieza';
    pet.currentAction = PetAction.bathing;
    await save();
    notifyListeners();
  }

  Future<void> sleepPet() async {
    if (selectedPet != null) _requestAction(selectedPet!, PetAction.going_to_sleep);
  }
  Future<void> completeSleepPet(Pet pet) async {
    pet.stats.energy += 30;
    pet.stats.clamp();
    pet.currentActionMessage = '+30 Energía';
    pet.currentAction = PetAction.sleeping;
    await save();
    notifyListeners();
  }

  Future<void> petPet() async {
    if (selectedPet != null && _canAct(selectedPet!)) {
      selectedPet!.currentAction = PetAction.petting;
      selectedPet!.stats.happiness += 10;
      selectedPet!.stats.clamp();
      selectedPet!.currentActionMessage = '+10 Amor';
      await save();
      notifyListeners();
      
      // Petting finishes quickly
      Future.delayed(const Duration(seconds: 2), () {
        if (selectedPet != null && selectedPet!.currentAction == PetAction.petting) {
          selectedPet!.currentAction = PetAction.idle;
          selectedPet!.currentActionMessage = null;
          notifyListeners();
        }
      });
    }
  }

  Future<void> walkPet() async {
    if (selectedPet != null) _requestAction(selectedPet!, PetAction.going_to_walk);
  }
  Future<void> completeWalkPet(Pet pet) async {
    pet.stats.happiness += 20;
    pet.stats.energy -= 15;
    pet.stats.hygiene -= 5;
    pet.stats.clamp();
    pet.currentActionMessage = '+20 Feliz, -15 Energía';
    pet.currentAction = PetAction.walking;
    await save();
    notifyListeners();
  }

  void endAction(Pet pet) {
    pet.currentAction = PetAction.idle;
    pet.currentActionMessage = null;
    notifyListeners();
  }
}

