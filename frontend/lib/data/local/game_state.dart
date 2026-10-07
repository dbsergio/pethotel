import 'package:uuid/uuid.dart';
import '../../game/models/player.dart';
import '../../game/models/pet.dart';
import '../../game/models/boarding_stay.dart';
import '../../game/models/customer.dart';
import '../repositories/game_repository.dart';
import '../services/game_sync_service.dart';
import 'package:flutter/foundation.dart';

class GameState extends ChangeNotifier {
  Player? player;
  final GameRepository repository;
  final GameSyncService syncService;

  GameState(this.repository, this.syncService);

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
      // Attempt sync via sync service
      syncService.markPending();
    }
  }

  String? selectedPetId;

  Pet? get selectedPet {
    if (player == null || selectedPetId == null) return null;
    return player!.activePets.cast<Pet?>().firstWhere(
      (p) => p?.id == selectedPetId,
      orElse: () => null,
    );
  }

  void selectPetById(String petId) {
    if (selectedPetId != petId) {
      selectedPetId = petId;
      debugPrint('[STATE] selectedPetId = $selectedPetId');
      notifyListeners();
    }
  }

  Future<void> selectPet(Pet pet) async {
    selectPetById(pet.id);
  }

  Future<void> adoptPet(Pet pet, {Customer? customer, String? request}) async {
    if (player != null) {
      if (player!.activePets.length >= player!.capacity) return;
      
      // If no customer provided, create a dummy one for the old 'adopt' flow
      final c = customer ?? Customer(name: 'Adoptante');
      final req = request ?? 'Cuídalo mucho.';
      
      final stay = BoardingStay(
        customer: c,
        petId: pet.id,
        request: req,
        expectedDurationSeconds: 120, // 2 minutes for testing
      );
      
      player!.activePets.add(pet);
      player!.activeStays.add(stay);
      selectedPetId = pet.id;
      
      // Start walk-in animation
      pet.currentAction = PetAction.walking_in;
      pet.currentActionId = const Uuid().v4();
      
      await save();
      notifyListeners();
    }
  }
  
  void checkStays() {
    if (player == null) return;
    bool changed = false;
    for (var stay in player!.activeStays) {
      if (stay.status == StayStatus.active && stay.isReady) {
        stay.status = StayStatus.readyForPickup;
        changed = true;
      }
    }
    if (changed) {
      save();
      notifyListeners();
    }
  }

  BoardingStay? getStayForPet(String petId) {
    if (player == null) return null;
    return player!.activeStays.cast<BoardingStay?>().firstWhere(
      (s) => s?.petId == petId,
      orElse: () => null,
    );
  }

  Future<void> deliverPet(BoardingStay stay) async {
    if (player == null) return;
    
    final pet = player!.activePets.firstWhere((p) => p.id == stay.petId);
    
    // Calculate satisfaction
    int score = 0;
    if (pet.stats.hunger > 70) score += 20;
    if (pet.stats.thirst > 70) score += 20;
    if (pet.stats.hygiene > 70) score += 20;
    if (pet.stats.energy > 70) score += 20;
    if (pet.stats.happiness > 70) score += 20;
    
    int stars = 1;
    if (score >= 90) stars = 5;
    else if (score >= 75) stars = 4;
    else if (score >= 50) stars = 3;
    else if (score >= 30) stars = 2;
    
    int baseCoins = 20;
    int bonus = (stars - 3) * 5; 
    int reward = (baseCoins + bonus).clamp(5, 50);
    
    stay.satisfaction = stars;
    stay.rewardCoins = reward;
    stay.status = StayStatus.completed;
    
    player!.coins += reward;
    
    // Trigger walk out animation
    pet.currentAction = PetAction.walking_out;
    pet.currentActionId = const Uuid().v4();
    
    player!.activeStays.remove(stay);
    player!.completedStays.add(stay);
    
    if (selectedPetId == stay.petId) {
      selectedPetId = null;
    }
    
    await save();
    notifyListeners();
  }

  Future<void> finalizeWalkOut(Pet pet) async {
    if (player == null) return;
    player!.activePets.removeWhere((p) => p.id == pet.id);
    await save();
    notifyListeners();
  }
  bool _canAct(Pet pet) {
    if (pet.currentAction == PetAction.idle || pet.currentAction == PetAction.walking) {
      return true;
    }
    debugPrint('_canAct(${pet.name}) = false\nreason: busy with action\nstate: ${pet.currentAction.name}\n');
    return false;
  }

  void _requestAction(Pet pet, PetAction intent) {
    if (_canAct(pet)) {
      pet.currentAction = intent;
      pet.currentActionId = const Uuid().v4();
      debugPrint('[${pet.name}] Action request: ${intent.name}, Action #${pet.currentActionId}');
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
    final pet = selectedPet;
    if (pet != null && _canAct(pet)) {
      pet.currentAction = PetAction.petting;
      pet.currentActionId = const Uuid().v4();
      pet.stats.happiness += 10;
      pet.stats.clamp();
      pet.currentActionMessage = '+10 Amor';
      await save();
      notifyListeners();
      
      // Petting finishes quickly
      Future.delayed(const Duration(seconds: 2), () {
        if (pet.currentAction == PetAction.petting) {
          endAction(pet);
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
    pet.currentActionId = null;
    notifyListeners();
  }

  void resetActionState(Pet pet) {
    debugPrint('[${pet.name}] WATCHDOG RECOVERY - Resetting state');
    endAction(pet);
  }

  void cancelCurrentAction(Pet pet) {
    if (pet.currentAction != PetAction.idle) {
      debugPrint('[${pet.name}] Action cancelled explicitly');
      resetActionState(pet);
    }
  }
}

