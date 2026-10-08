import 'package:uuid/uuid.dart';
import '../../game/models/player.dart';
import '../../game/models/pet.dart';
import '../../game/models/boarding_stay.dart';
import '../../game/models/customer.dart';
import '../repositories/game_repository.dart';
import '../services/game_sync_service.dart';
import '../../game/models/shop_item.dart';
import 'package:flutter/foundation.dart';
import '../../core/config/app_config.dart';
import '../../game/minigames/minigame_result.dart';
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
      player = Player(
        id: playerId,
        inventory: {
          'food_basic': 2,
          'soap_basic': 1,
        },
      );
      await repository.savePlayer(player!);
    }
    notifyListeners();
  }

  // --- ECONOMY & INVENTORY METHODS ---
  bool hasCoins(int amount) {
    if (player == null || amount < 0) return false;
    return player!.coins >= amount;
  }

  Future<void> addCoins(int amount) async {
    if (player == null || amount < 0) return;
    player!.coins += amount;
    await save();
    notifyListeners();
  }

  Future<bool> deductCoins(int amount) async {
    if (!hasCoins(amount)) return false;
    player!.coins -= amount;
    await save();
    notifyListeners();
    return true;
  }

  int getInventoryQuantity(String itemId) {
    if (player == null) return 0;
    return player!.inventory[itemId] ?? 0;
  }

  bool hasInventoryItem(String itemId, int quantity) {
    if (player == null || quantity <= 0) return false;
    return getInventoryQuantity(itemId) >= quantity;
  }

  Future<void> addInventoryItem(String itemId, int quantity) async {
    if (player == null || quantity <= 0) return;
    int current = player!.inventory[itemId] ?? 0;
    player!.inventory[itemId] = current + quantity;
    await save();
    notifyListeners();
  }

  Future<bool> removeInventoryItem(String itemId, int quantity) async {
    if (!hasInventoryItem(itemId, quantity)) return false;
    int current = player!.inventory[itemId] ?? 0;
    int newQuantity = current - quantity;
    if (newQuantity == 0) {
      player!.inventory.remove(itemId);
    } else {
      player!.inventory[itemId] = newQuantity;
    }
    await save();
    notifyListeners();
    return true;
  }

  Future<bool> buyItem(String itemId) async {
    final item = StoreCatalog.items[itemId];
    if (item == null) return false;
    
    if (!hasCoins(item.price)) return false;

    if (item.type == ItemType.permanent) {
      if (hasInventoryItem(itemId, 1)) return false; // Already bought
      
      // Apply permanent effect
      if (itemId == 'upgrade_capacity_1' && player!.capacity < 5) {
        player!.capacity = 5;
      } else if (itemId == 'upgrade_capacity_2' && player!.capacity < 6) {
        player!.capacity = 6;
      } else {
        return false; // Cannot upgrade if already maxed out or not matching conditions
      }
    }

    // Deduct coins
    player!.coins -= item.price;
    
    // Add to inventory
    int current = player!.inventory[itemId] ?? 0;
    player!.inventory[itemId] = current + 1;
    
    await save();
    notifyListeners();
    return true;
  }

  Future<bool> consumeItem(String itemId, String petId) async {
    final item = StoreCatalog.items[itemId];
    if (item == null || item.type != ItemType.consumable) return false;
    if (!hasInventoryItem(itemId, 1)) return false;

    final pet = player!.activePets.cast<Pet?>().firstWhere(
      (p) => p?.id == petId,
      orElse: () => null,
    );
    if (pet == null) return false;

    // Remove from inventory
    int current = player!.inventory[itemId] ?? 0;
    int newQuantity = current - 1;
    if (newQuantity <= 0) {
      player!.inventory.remove(itemId);
    } else {
      player!.inventory[itemId] = newQuantity;
    }

    // Apply effect
    switch (item.effectType) {
      case EffectType.hunger:
        pet.stats.hunger += item.effectValue;
        break;
      case EffectType.hygiene:
        pet.stats.hygiene += item.effectValue;
        break;
      case EffectType.happiness:
        pet.stats.happiness += item.effectValue;
        break;
      case EffectType.energy:
        pet.stats.energy += item.effectValue;
        break;
      case EffectType.thirst:
        pet.stats.thirst += item.effectValue;
        break;
      case EffectType.none:
        break;
    }
    pet.stats.clamp(); // Ensure values do not exceed 100

    await save();
    notifyListeners();
    return true;
  }
  // -----------------------------------


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
        expectedDurationSeconds: AppConfig.boardingStayDurationSeconds,
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
    return false;
  }

  void _requestAction(Pet pet, PetAction intent) {
    if (!_canAct(pet)) {
      cancelCurrentAction(pet);
    }
    pet.currentAction = intent;
    pet.currentActionId = const Uuid().v4();
    debugPrint('[${pet.name}] Action request: ${intent.name}, Action #${pet.currentActionId}');
    notifyListeners();
  }

  Future<void> feedPet({CareMinigameResult? result}) async {
    if (selectedPet != null) {
      selectedPet!.minigameResult = result;
      _requestAction(selectedPet!, PetAction.going_to_eat);
    }
  }
  Future<void> completeFeedPet(Pet pet) async {
    final res = pet.minigameResult;
    pet.stats.hunger += res?.statChanges['hunger'] ?? 20;
    pet.stats.happiness += res?.statChanges['happiness'] ?? 3;
    pet.stats.clamp();
    pet.currentActionMessage = '+${(res?.statChanges['hunger'] ?? 20).toInt()} Hambre';
    pet.currentAction = PetAction.eating;
    pet.minigameResult = null;
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

  Future<void> playWithPet({CareMinigameResult? result}) async {
    if (selectedPet != null) {
      selectedPet!.minigameResult = result;
      _requestAction(selectedPet!, PetAction.going_to_play);
    }
  }
  Future<void> completePlayWithPet(Pet pet) async {
    final res = pet.minigameResult;
    pet.stats.happiness += res?.statChanges['happiness'] ?? 15;
    pet.stats.energy += res?.statChanges['energy'] ?? -10; // usually negative
    pet.stats.clamp();
    pet.currentActionMessage = '+${(res?.statChanges['happiness'] ?? 15).toInt()} Feliz';
    pet.currentAction = PetAction.playing;
    pet.minigameResult = null;
    await save();
    notifyListeners();
  }

  Future<void> bathePet({CareMinigameResult? result}) async {
    if (selectedPet != null) {
      selectedPet!.minigameResult = result;
      _requestAction(selectedPet!, PetAction.going_to_bath);
    }
  }
  Future<void> completeBathePet(Pet pet) async {
    final res = pet.minigameResult;
    pet.stats.hygiene += res?.statChanges['hygiene'] ?? 30;
    pet.stats.clamp();
    pet.currentActionMessage = '+${(res?.statChanges['hygiene'] ?? 30).toInt()} Limpieza';
    pet.currentAction = PetAction.bathing;
    pet.minigameResult = null;
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

  Future<void> petPet({CareMinigameResult? result}) async {
    final pet = selectedPet;
    if (pet != null && _canAct(pet)) {
      pet.currentAction = PetAction.petting;
      pet.currentActionId = const Uuid().v4();
      
      final res = result;
      pet.stats.happiness += res?.statChanges['happiness'] ?? 10;
      pet.stats.clamp();
      pet.currentActionMessage = '+${(res?.statChanges['happiness'] ?? 10).toInt()} Amor';
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

