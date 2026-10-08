import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../models/pet.dart';
import '../../data/local/game_state.dart';
import '../mypet_game.dart';
import 'minigame_result.dart';
import '../components/pet_graphic_component.dart';

class PlayMinigameToy extends PositionComponent with DragCallbacks, HasGameReference<MyPetGame> {
  final Pet pet;
  final GameState gameState;
  final VoidCallback onComplete;

  int _chaseCount = 0;
  final int _maxChases = 4;
  bool _isBeingDragged = false;
  late TextComponent _visual;
  
  // To avoid spamming, we only count a "chase" when the pet reaches the toy
  bool _waitingForPet = true;

  PlayMinigameToy({
    required this.pet,
    required this.gameState,
    required this.onComplete,
    required Vector2 position,
  }) : super(position: position, size: Vector2(80, 80));

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;
    _visual = TextComponent(
      text: '🎾',
      textRenderer: TextPaint(style: const TextStyle(fontSize: 30)),
    );
    _visual.anchor = Anchor.center;
    _visual.position = size / 2;
    add(_visual);

    _startChase();
  }

  void _startChase() {
    _waitingForPet = true;
    _directPetTo(position);
  }

  void _directPetTo(Vector2 dest) {
    // Find the graphic component for this pet and tell it to move
    for (final child in game.children) {
      if (child is PetGraphicComponent && child.pet.id == pet.id) {
        child.movement.moveTo(dest, speed: 200, onComplete: () {
          if (_waitingForPet && !_isBeingDragged) {
            _onPetReachedToy(child);
          }
        });
        break;
      }
    }
  }

  void _onPetReachedToy(PetGraphicComponent petComponent) {
    _waitingForPet = false;
    _chaseCount++;
    
    petComponent.bounceEffect();
    
    if (_chaseCount >= _maxChases) {
      _finishGame();
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _isBeingDragged = true;
    event.continuePropagation = false;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    position += event.localDelta;

    // Clamp to playable area to respect boundaries
    final playable = game.playableRect;
    if (position.x < playable.left) position.x = playable.left;
    if (position.x > playable.right) position.x = playable.right;
    if (position.y < playable.top) position.y = playable.top;
    if (position.y > playable.bottom) position.y = playable.bottom;

    // Tell pet to update its destination dynamically
    if (_waitingForPet) {
      _directPetTo(position);
    }
    event.continuePropagation = false;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _isBeingDragged = false;
    // Restart chase logic once dropped
    _startChase();
    event.continuePropagation = false;
  }

  void _finishGame() {
    // 4 chases: +20 happiness, -15 energy
    final result = CareMinigameResult(
      success: true,
      quality: 1.0,
      statChanges: {
        'happiness': 20.0,
        'energy': -15.0,
      },
    );
    
    pet.minigameResult = result;
    gameState.completePlayWithPet(pet);
    
    onComplete();
    removeFromParent();
  }
}
