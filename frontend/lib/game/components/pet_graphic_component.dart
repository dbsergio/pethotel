import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/pet.dart';
import '../../data/local/game_state.dart';
import '../behaviors/movement_behavior.dart';
import '../behaviors/wander_behavior.dart';
import '../behaviors/action_behavior.dart';
import '../mypet_game.dart';
import 'vector_shapes.dart';

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
  late PositionComponent animalCore;
  late PositionComponent head;
  late PositionComponent body;
  late PositionComponent tail;
  late List<PositionComponent> legs;

  late CircleComponent selectionHalo;
  late TextComponent nameText;
  late TextComponent feedbackText;
  bool facingRight = true;

  PetAction _lastVisualAction = PetAction.idle;
  final List<Effect> _activeEffects = [];

  PetGraphicComponent({
    required this.pet,
    required this.gameState,
    required Vector2 spawnPosition,
  }) : super(
          position: spawnPosition,
          size: Vector2(110, 110),
          anchor: Anchor.center,
          priority: kPetPriority,
        );

  @override
  Future<void> onLoad() async {
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

    animalCore = PositionComponent(
      position: Vector2(0, 0),
      anchor: Anchor.center,
    );
    bodyGroup.add(animalCore);

    final Color primaryColor;
    final Color secondaryColor;
    switch (pet.species) {
      case 'cat':
        primaryColor = const Color(0xFFF4A460); // Sandy brown
        secondaryColor = const Color(0xFFD2691E); // Chocolate
        break;
      case 'rabbit':
        primaryColor = const Color(0xFFFFFFFF);
        secondaryColor = const Color(0xFFFFB6C1); // Pink
        break;
      case 'hamster':
        primaryColor = const Color(0xFFFFD700); // Gold
        secondaryColor = const Color(0xFFDAA520); // Goldenrod
        break;
      default: // dog
        primaryColor = const Color(0xFF8B4513); // Saddle brown
        secondaryColor = const Color(0xFFA0522D); // Sienna
        break;
    }

    final paintPrimary = Paint()..color = primaryColor;
    final paintSecondary = Paint()..color = secondaryColor;
    final paintBlack = Paint()..color = const Color(0xFF333333);

    // Legs
    legs = [];
    for (int i = 0; i < 4; i++) {
      final isFront = i < 2;
      final isRight = i % 2 == 0;
      final leg = RoundedRectangleComponent(
        size: Vector2(8, 22),
        paint: isRight ? paintPrimary : paintSecondary,
        radius: 4,
        position: Vector2(isFront ? 12 : -12, 10),
        anchor: Anchor.topCenter,
      );
      legs.add(leg);
      animalCore.add(leg);
    }

    // Tail
    tail = RoundedRectangleComponent(
      size: Vector2(25, 8),
      paint: paintPrimary,
      radius: 4,
      position: Vector2(-25, -5),
      anchor: Anchor.centerRight,
    );
    animalCore.add(tail);

    // Body
    body = EllipseComponent(
      size: Vector2(55, 35),
      paint: paintPrimary,
      position: Vector2(0, 0),
      anchor: Anchor.center,
    );
    animalCore.add(body);

    // Head
    head = EllipseComponent(
      size: Vector2(35, 30),
      paint: paintPrimary,
      position: Vector2(22, -15),
      anchor: Anchor.center,
    );
    animalCore.add(head);

    // Ears
    if (pet.species == 'rabbit') {
      head.add(EllipseComponent(size: Vector2(8, 25), paint: paintSecondary, position: Vector2(10, -15), anchor: Anchor.bottomCenter));
      head.add(EllipseComponent(size: Vector2(8, 25), paint: paintPrimary, position: Vector2(25, -15), anchor: Anchor.bottomCenter));
    } else if (pet.species == 'cat') {
      head.add(TriangleComponent(size: Vector2(12, 12), paint: paintSecondary, position: Vector2(8, -8), anchor: Anchor.bottomCenter));
      head.add(TriangleComponent(size: Vector2(12, 12), paint: paintPrimary, position: Vector2(27, -8), anchor: Anchor.bottomCenter));
    } else { // dog & hamster
      head.add(EllipseComponent(size: Vector2(10, 15), paint: paintSecondary, position: Vector2(8, -2), anchor: Anchor.topCenter));
      head.add(EllipseComponent(size: Vector2(10, 15), paint: paintPrimary, position: Vector2(27, -2), anchor: Anchor.topCenter));
    }

    // Eyes
    head.add(EllipseComponent(size: Vector2(4, 5), paint: paintBlack, position: Vector2(22, 8), anchor: Anchor.center));
    head.add(EllipseComponent(size: Vector2(4, 5), paint: paintBlack, position: Vector2(30, 8), anchor: Anchor.center));
    
    // Nose
    head.add(EllipseComponent(size: Vector2(5, 3), paint: paintBlack, position: Vector2(26, 16), anchor: Anchor.center));

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

  double _particleTimer = 0;

  @override
  void update(double dt) {
    super.update(dt);
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

    // Particle Spawner
    _particleTimer += dt;
    if (_particleTimer >= 0.4) {
      _particleTimer = 0;
      if (pet.currentAction == PetAction.petting) {
        _spawnParticle('heart');
      } else if (pet.currentAction == PetAction.eating) {
        _spawnParticle('crumb');
      } else if (pet.currentAction == PetAction.drinking) {
        _spawnParticle('drop');
      } else if (pet.currentAction == PetAction.bathing) {
        _spawnParticle('bubble');
      } else if (pet.currentAction == PetAction.playing) {
        _spawnParticle('star');
      }
    }
  }

  void _clearEffects() {
    for (final e in _activeEffects) {
      e.removeFromParent();
    }
    _activeEffects.clear();

    // Reset base properties
    animalCore.scale = Vector2.all(1.0);
    animalCore.position = Vector2.zero();
    animalCore.angle = 0.0;
    head.angle = 0.0;
    tail.angle = 0.0;
    for (final leg in legs) {
      leg.angle = 0.0;
    }
  }

  void _addEffect(PositionComponent target, Effect effect) {
    target.add(effect);
    _activeEffects.add(effect);
  }

  void _applyVisualState(PetAction action) {
    _clearEffects();

    switch (action) {
      case PetAction.idle:
        // Subtle breathing
        _addEffect(animalCore, ScaleEffect.by(
          Vector2(1.0, 0.95),
          EffectController(duration: 1.2, alternate: true, infinite: true),
        ));
        // Slow tail wag
        _addEffect(tail, RotateEffect.to(
          0.2,
          EffectController(duration: 1.5, alternate: true, infinite: true),
        ));
        break;
      
      case PetAction.walking:
      case PetAction.going_to_play:
      case PetAction.going_to_bath:
      case PetAction.walking_in:
      case PetAction.walking_out:
        // Bobbing body
        _addEffect(animalCore, MoveEffect.by(
          Vector2(0, -6),
          EffectController(duration: 0.15, alternate: true, infinite: true),
        ));
        // Moving legs
        for (int i = 0; i < legs.length; i++) {
          final leg = legs[i];
          final dir = (i % 2 == 0) ? 1 : -1;
          _addEffect(leg, RotateEffect.to(
            0.4 * dir,
            EffectController(duration: 0.15, alternate: true, infinite: true),
          ));
        }
        // Fast tail wag
        _addEffect(tail, RotateEffect.to(
          0.3,
          EffectController(duration: 0.15, alternate: true, infinite: true),
        ));
        break;
      
      case PetAction.eating:
      case PetAction.drinking:
      case PetAction.going_to_eat:
      case PetAction.going_to_drink:
        // Tilting head down
        _addEffect(head, RotateEffect.to(
          0.5,
          EffectController(duration: 0.3, alternate: true, infinite: true),
        ));
        _addEffect(animalCore, MoveEffect.by(
          Vector2(0, 5),
          EffectController(duration: 0.3, alternate: true, infinite: true),
        ));
        break;
      
      case PetAction.sleeping:
      case PetAction.going_to_sleep:
        // Lying down
        _addEffect(animalCore, MoveEffect.to(
          Vector2(0, 15),
          EffectController(duration: 0.5),
        ));
        _addEffect(animalCore, ScaleEffect.to(
          Vector2(1.0, 0.7),
          EffectController(duration: 0.5),
        ));
        // Deep breathing
        _addEffect(animalCore, ScaleEffect.by(
          Vector2(1.05, 1.05),
          EffectController(duration: 2.0, alternate: true, infinite: true, startDelay: 0.5),
        ));
        break;
        
      case PetAction.petting:
        // Happy bounce
        _addEffect(animalCore, MoveEffect.by(
          Vector2(0, -15),
          EffectController(duration: 0.15, alternate: true, infinite: true),
        ));
        _addEffect(tail, RotateEffect.to(
          0.5,
          EffectController(duration: 0.1, alternate: true, infinite: true),
        ));
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
    if (gameState.selectedPetId == pet.id) {
      gameState.selectPetById(null);
    } else {
      gameState.selectPetById(pet.id);
      showFeedback('✓ ${pet.name}');
    }
    event.handled = true;
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

  void _spawnParticle(String type) {
    final rng = math.Random();
    PositionComponent? particle;
    Vector2 spawnPos = Vector2(size.x / 2 + (rng.nextDouble() * 20 - 10), 10 + (rng.nextDouble() * 10 - 5));

    if (type == 'heart') {
      particle = TextComponent(
        text: '❤️',
        textRenderer: TextPaint(style: const TextStyle(fontSize: 16)),
      );
      spawnPos.y -= 20; // spawn higher
    } else if (type == 'crumb') {
      particle = RoundedRectangleComponent(
        size: Vector2(6, 6),
        paint: Paint()..color = const Color(0xFF8D6E63),
        radius: 1,
      );
      spawnPos.y += 20; // spawn lower near mouth
    } else if (type == 'drop') {
      particle = EllipseComponent(
        size: Vector2(4, 6),
        paint: Paint()..color = const Color(0xFF4FC3F7),
      );
      spawnPos.y += 20;
    } else if (type == 'bubble') {
      particle = EllipseComponent(
        size: Vector2(8, 8),
        paint: Paint()..color = const Color(0xFFB3E5FC).withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 2,
      );
      spawnPos.y += 10;
    } else if (type == 'star') {
      particle = TextComponent(
        text: '✨',
        textRenderer: TextPaint(style: const TextStyle(fontSize: 14)),
      );
    }

    if (particle != null) {
      particle.position = spawnPos;
      particle.anchor = Anchor.center;
      add(particle);

      // Animation: float up and fade
      final floatDist = type == 'crumb' || type == 'drop' ? 5.0 : -30.0;
      particle.add(MoveEffect.by(Vector2(rng.nextDouble() * 10 - 5, floatDist), EffectController(duration: 0.8)));
      particle.add(OpacityEffect.fadeOut(EffectController(duration: 0.8), onComplete: () => particle?.removeFromParent()));
    }
  }
}
