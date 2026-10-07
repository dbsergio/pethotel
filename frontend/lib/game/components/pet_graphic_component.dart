import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../models/pet.dart';
import '../../data/local/game_state.dart';
import '../behaviors/movement_behavior.dart';
import '../behaviors/wander_behavior.dart';
import '../behaviors/action_behavior.dart';
import '../mypet_game.dart';

class PetGraphicComponent extends PositionComponent with HasGameReference<MyPetGame>, TapCallbacks {
  final Pet pet;
  final GameState gameState;

  late final MovementBehavior movement;
  late final WanderBehavior wander;
  late final ActionBehavior actionLogic;

  late PositionComponent bodyGroup;
  late CircleComponent selectionHalo;
  late TextComponent nameText;
  late TextComponent feedbackText;
  bool facingRight = true;

  PetGraphicComponent({
    required this.pet,
    required this.gameState,
    required Vector2 spawnPosition,
  }) : super(
          position: spawnPosition,
          size: Vector2(110, 110),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    debugMode = true;
    movement = MovementBehavior();
    wander = WanderBehavior();
    actionLogic = ActionBehavior();

    add(movement);
    add(wander);
    add(actionLogic);

    _buildBody();
  }

  void _buildBody() {
    selectionHalo = CircleComponent(
      radius: 40,
      position: Vector2(size.x / 2, size.y / 2 + 10),
      paint: Paint()..color = Colors.yellow.withOpacity(0.0),
      anchor: Anchor.center,
    );
    add(selectionHalo);

    bodyGroup = PositionComponent(
      position: Vector2(size.x / 2, size.y / 2),
      anchor: Anchor.center,
    );
    add(bodyGroup);

    // Placeholder body
    final bodyShape = CircleComponent(
      radius: 35,
      paint: Paint()..color = const Color(0xFF8D6E63),
      anchor: Anchor.center,
    );
    bodyGroup.add(bodyShape);

    final earL = CircleComponent(
      radius: 12,
      position: Vector2(15, 15),
      paint: Paint()..color = const Color(0xFF5D4037),
      anchor: Anchor.center,
    );
    final earR = CircleComponent(
      radius: 12,
      position: Vector2(55, 15),
      paint: Paint()..color = const Color(0xFF5D4037),
      anchor: Anchor.center,
    );
    bodyGroup.addAll([earL, earR]);

    nameText = TextComponent(
      text: pet.name,
      position: Vector2(size.x / 2, -22),
      anchor: Anchor.center,
      textRenderer: TextPaint(style: const TextStyle(
          color: Color(0xFF5D4037), fontSize: 15, fontWeight: FontWeight.bold)),
    );
    add(nameText);

    feedbackText = TextComponent(
      text: '',
      position: Vector2(size.x / 2, -48),
      anchor: Anchor.center,
      textRenderer: TextPaint(style: const TextStyle(
          color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold)),
    );
    add(feedbackText);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!facingRight && bodyGroup.scale.x > 0) {
      bodyGroup.scale.x = -1;
    } else if (facingRight && bodyGroup.scale.x < 0) {
      bodyGroup.scale.x = 1;
    }
    
    // Update selection visual
    if (gameState.selectedPetId == pet.id) {
      selectionHalo.paint.color = Colors.yellow.withOpacity(0.5);
    } else {
      selectionHalo.paint.color = Colors.transparent;
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    debugPrint('[INPUT] onTapDown on PetGraphicComponent: ${pet.name} (${pet.id}) at ${event.localPosition}');
    
    // THE FIX: Select on down instead of up to prevent movement from cancelling the tap.
    showFeedback('SELECCIONADO: ${pet.name}\nID: ${pet.id}');
    gameState.selectPetById(pet.id);
    
    super.onTapDown(event);
  }

  @override
  void onTapUp(TapUpEvent event) {
    debugPrint('[INPUT] onTapUp on PetGraphicComponent: ${pet.name} (${pet.id})');
    super.onTapUp(event);
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    debugPrint('[INPUT] onTapCancel on PetGraphicComponent: ${pet.name} (${pet.id})');
    super.onTapCancel(event);
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    // For a 110x110 component with Anchor.center,
    // point is relative to the top-left of the bounding box.
    final contains = point.x >= 0 && point.y >= 0 && point.x < size.x && point.y < size.y;
    if (contains) {
      debugPrint('[INPUT] containsLocalPoint TRUE for ${pet.name} at $point');
    }
    return contains;
  }

  void bounceEffect() {
    bodyGroup.add(
      SequenceEffect([
        MoveEffect.by(Vector2(0, -10), EffectController(duration: 0.2, alternate: true, repeatCount: 4)),
      ])
    );
  }

  void showFeedback(String text) {
    feedbackText.text = text;
    feedbackText.setOpacity(1.0);
    feedbackText.position = Vector2(size.x / 2, -48);
    
    feedbackText.add(
      SequenceEffect([
        MoveEffect.by(Vector2(0, -10), EffectController(duration: 0.5)),
        OpacityEffect.fadeOut(EffectController(duration: 1.0)),
      ], onComplete: () {
        feedbackText.text = '';
      }),
    );
  }
}
