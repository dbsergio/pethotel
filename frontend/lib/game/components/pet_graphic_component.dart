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

// ─────────────────────────────────────────────────────────────────────────────
// Priority constants. Higher = tested first in Flame hit-test.
// Background = 0. Objects = 5. Pets = 10.
// ─────────────────────────────────────────────────────────────────────────────
const int kPetPriority = 10;

class PetGraphicComponent extends PositionComponent
    with HasGameReference<MyPetGame>, TapCallbacks {
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

  PetAction _lastVisualAction = PetAction.idle;
  Effect? _currentVisualEffect;

  PetGraphicComponent({
    required this.pet,
    required this.gameState,
    required Vector2 spawnPosition,
  }) : super(
          position: spawnPosition,
          size: Vector2(110, 110),
          anchor: Anchor.center,
          // Higher priority → Flame tests this component BEFORE the background.
          priority: kPetPriority,
        );

  @override
  Future<void> onLoad() async {
    // debugMode = true; // Uncomment to see hitbox bounding box
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
      radius: 42,
      position: Vector2(size.x / 2, size.y / 2 + 10),
      paint: Paint()..color = Colors.yellow.withValues(alpha: 0.0),
      anchor: Anchor.center,
    );
    add(selectionHalo);

    bodyGroup = PositionComponent(
      position: Vector2(size.x / 2, size.y / 2),
      anchor: Anchor.center,
    );
    add(bodyGroup);

    // Body color by species
    final bodyColor = switch (pet.species) {
      'cat'     => const Color(0xFF9E9E9E),
      'rabbit'  => const Color(0xFFCE93D8),
      'hamster' => const Color(0xFFFFCC80),
      _         => const Color(0xFF8D6E63), // dog default
    };

    final bodyShape = CircleComponent(
      radius: 35,
      paint: Paint()..color = bodyColor,
      anchor: Anchor.center,
    );
    bodyGroup.add(bodyShape);

    final earL = CircleComponent(
      radius: 12,
      position: Vector2(15, 15),
      paint: Paint()..color = bodyColor.withValues(alpha: 0.7),
      anchor: Anchor.center,
    );
    final earR = CircleComponent(
      radius: 12,
      position: Vector2(55, 15),
      paint: Paint()..color = bodyColor.withValues(alpha: 0.7),
      anchor: Anchor.center,
    );
    bodyGroup.addAll([earL, earR]);

    nameText = TextComponent(
      text: pet.name,
      position: Vector2(size.x / 2, -22),
      anchor: Anchor.center,
      textRenderer: TextPaint(
          style: const TextStyle(
              color: Color(0xFF5D4037),
              fontSize: 15,
              fontWeight: FontWeight.bold)),
    );
    add(nameText);

    feedbackText = TextComponent(
      text: '',
      position: Vector2(size.x / 2, -48),
      anchor: Anchor.center,
      textRenderer: TextPaint(
          style: const TextStyle(
              color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold)),
    );
    add(feedbackText);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Update selection halo
    if (gameState.selectedPetId == pet.id) {
      selectionHalo.paint.color = Colors.yellow.withValues(alpha: 0.55);
    } else {
      selectionHalo.paint.color = Colors.transparent;
    }

    // Visual State Machine
    bodyGroup.scale.x = facingRight ? 1 : -1;
    final expectedAction = movement.isMoving ? PetAction.walking : pet.currentAction;
    if (_lastVisualAction != expectedAction) {
      _applyVisualState(expectedAction);
      _lastVisualAction = expectedAction;
    }
  }

  void _applyVisualState(PetAction action) {
    if (_currentVisualEffect != null) {
      bodyGroup.remove(_currentVisualEffect!);
      _currentVisualEffect = null;
    }

    // Reset properties in case previous effect left them offset
    bodyGroup.scale.y = 1.0;
    bodyGroup.position = Vector2(size.x / 2, size.y / 2);

    switch (action) {
      case PetAction.idle:
        // Subtle breathing (vertical scale bounce)
        _currentVisualEffect = ScaleEffect.by(
          Vector2(1.0, 0.96),
          EffectController(duration: 1.2, alternate: true, infinite: true),
        );
        bodyGroup.add(_currentVisualEffect!);
        break;
      
      case PetAction.walking:
      case PetAction.going_to_play:
      case PetAction.going_to_bath:
      case PetAction.walking_in:
      case PetAction.walking_out:
        // Bobbing while walking
        _currentVisualEffect = MoveEffect.by(
          Vector2(0, -8),
          EffectController(duration: 0.2, alternate: true, infinite: true),
        );
        bodyGroup.add(_currentVisualEffect!);
        break;
      
      case PetAction.eating:
      case PetAction.drinking:
      case PetAction.going_to_eat:
      case PetAction.going_to_drink:
        // Tilting head down (simulated by vertical squish and lower position)
        bodyGroup.position.y += 10;
        _currentVisualEffect = ScaleEffect.by(
          Vector2(1.05, 0.9),
          EffectController(duration: 0.3, alternate: true, infinite: true),
        );
        bodyGroup.add(_currentVisualEffect!);
        break;
      
      case PetAction.sleeping:
      case PetAction.going_to_sleep:
        // Lying down
        bodyGroup.position.y += 25;
        bodyGroup.scale.y = 0.6;
        _currentVisualEffect = ScaleEffect.by(
          Vector2(1.0, 1.05),
          EffectController(duration: 2.0, alternate: true, infinite: true),
        );
        bodyGroup.add(_currentVisualEffect!);
        break;
        
      case PetAction.petting:
        // Happy bounce
        _currentVisualEffect = MoveEffect.by(
          Vector2(0, -15),
          EffectController(duration: 0.15, alternate: true, infinite: true),
        );
        bodyGroup.add(_currentVisualEffect!);
        break;
        
      default:
        break;
    }
  }

  // ── Input ──────────────────────────────────────────────────────────────────
  // We select on DOWN (not UP) so that movement during the gesture never
  // cancels the selection.  onTapCancel is logged only — selection stays.
  @override
  void onTapDown(TapDownEvent event) {
    debugPrint('[INPUT] onTapDown  pet=${pet.name} id=${pet.id} local=${event.localPosition}');
    gameState.selectPetById(pet.id);
    showFeedback('✓ ${pet.name}');
    super.onTapDown(event);
  }

  @override
  void onTapUp(TapUpEvent event) {
    debugPrint('[INPUT] onTapUp    pet=${pet.name}');
    super.onTapUp(event);
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    // Selection already happened at onTapDown — do NOT undo it.
    debugPrint('[INPUT] onTapCancel pet=${pet.name} (selection kept)');
    super.onTapCancel(event);
  }

  // ── Feedback ───────────────────────────────────────────────────────────────
  void bounceEffect() {
    bodyGroup.add(SequenceEffect([
      MoveEffect.by(Vector2(0, -10),
          EffectController(duration: 0.2, alternate: true, repeatCount: 4)),
    ]));
  }

  void showFeedback(String text) {
    feedbackText.text = text;
    feedbackText.setOpacity(1.0);
    feedbackText.position = Vector2(size.x / 2, -48);

    feedbackText.add(SequenceEffect([
      MoveEffect.by(Vector2(0, -10), EffectController(duration: 0.5)),
      OpacityEffect.fadeOut(EffectController(duration: 1.0)),
    ], onComplete: () {
      feedbackText.text = '';
    }));
  }
}
