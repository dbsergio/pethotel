import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';
import '../../game/models/pet.dart';
import '../components/pet_graphic_component.dart';
import '../mypet_game.dart';

class ActionBehavior extends Component with ParentIsA<PetGraphicComponent>, HasGameReference<MyPetGame> {
  String? _lastActionId;

  // Track watchdog for current action
  double _actionTimer = 0;
  bool _isActing = false;

  @override
  void update(double dt) {
    if (_isActing) {
      _actionTimer += dt;
      if (_actionTimer > 20.0) {
        debugPrint('[${parent.pet.name}] WATCHDOG RECOVERY: Action took too long (>20s)');
        _resetAction();
      }
    }

    final pet = parent.pet;
    if (pet.currentActionId != null && pet.currentActionId != _lastActionId) {
      _lastActionId = pet.currentActionId;
      if (pet.currentAction != PetAction.idle) {
        _startAction(pet.currentAction);
      }
    } else if (pet.currentAction == PetAction.idle && _isActing) {
      // Exited externally
      _resetAction();
    }
  }

  void _startAction(PetAction action) {
    _isActing = true;
    _actionTimer = 0;
    
    parent.movement.cancel();
    parent.wander.pause();
    
    Vector2? dest;
    double duration = 3.0;

    switch (action) {
      case PetAction.going_to_eat:
        dest = game.scenePoint(MyPetGame.kFoodBowl.dx, MyPetGame.kFoodBowl.dy);
        duration = 3.0;
        break;
      case PetAction.going_to_drink:
        dest = game.scenePoint(MyPetGame.kWaterBowl.dx, MyPetGame.kWaterBowl.dy);
        duration = 2.5;
        break;
      case PetAction.going_to_sleep:
        dest = game.scenePoint(MyPetGame.kBed.dx, MyPetGame.kBed.dy);
        duration = 5.0;
        break;
      case PetAction.going_to_play:
        dest = game.scenePoint(MyPetGame.kToy.dx, MyPetGame.kToy.dy);
        duration = 4.0;
        break;
      case PetAction.going_to_bath:
        dest = game.scenePoint(MyPetGame.kBath.dx, MyPetGame.kBath.dy);
        duration = 3.5;
        break;
      case PetAction.going_to_walk:
        dest = game.scenePoint(MyPetGame.kCarpet.dx, MyPetGame.kCarpet.dy);
        duration = 4.0;
        break;
      case PetAction.petting:
        dest = null; // direct
        duration = 2.0;
        break;
      case PetAction.walking_in:
        dest = game.scenePoint(0.5, 0.6); // Center of room
        duration = 2.0;
        break;
      case PetAction.walking_out:
        // Assume door is roughly at 85% width, 30% height base
        dest = game.scenePoint(0.85, 0.30);
        duration = 3.0;
        break;
      default:
        _resetAction();
        return;
    }

    debugPrint('[${parent.pet.name}] Action STARTED: ${action.name} (ID: $_lastActionId)');

    if (dest != null) {
      parent.movement.moveTo(dest, speed: 130, onComplete: () {
         _performActionAnimation(action, duration);
      });
    } else {
      _performActionAnimation(action, duration);
    }
  }
  
  void _performActionAnimation(PetAction action, double duration) {
     debugPrint('[${parent.pet.name}] Action ARRIVED, animating ${action.name} for ${duration}s');
     
     // Visual bounce logic
     parent.bounceEffect();

     add(TimerComponent(
       period: duration, 
       removeOnFinish: true, 
       onTick: () {
          _completeAction(action);
       }
     ));
  }

  void _completeAction(PetAction action) {
    debugPrint('[${parent.pet.name}] Action COMPLETED: ${action.name}');
    
    // Call GameState logic
    switch (action) {
      case PetAction.going_to_eat: parent.gameState.completeFeedPet(parent.pet); break;
      case PetAction.going_to_drink: parent.gameState.completeDrinkPet(parent.pet); break;
      case PetAction.going_to_play: parent.gameState.completePlayWithPet(parent.pet); break;
      case PetAction.going_to_sleep: parent.gameState.completeSleepPet(parent.pet); break;
      case PetAction.going_to_bath: parent.gameState.completeBathePet(parent.pet); break;
      case PetAction.going_to_walk: parent.gameState.completeWalkPet(parent.pet); break;
      case PetAction.walking_out: 
        parent.gameState.finalizeWalkOut(parent.pet); 
        return; // Pet is destroyed, do not call endAction
      default: break; // Petting and walking_in handled in state or no-op
    }

    // Feedback
    if (parent.pet.currentActionMessage != null) {
      parent.showFeedback(parent.pet.currentActionMessage!);
    }

    // Finish
    parent.gameState.endAction(parent.pet);
    _resetAction();
  }

  void _resetAction() {
    _isActing = false;
    _actionTimer = 0;
    parent.wander.resume();
  }
}
