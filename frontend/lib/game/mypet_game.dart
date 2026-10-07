import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../../data/local/game_state.dart';
import 'models/pet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Playable area (pixels, relative to canvas)
// ─────────────────────────────────────────────────────────────────────────────
const double _kWallBottom = 0.30; // floor starts at 30 % of canvas height
const double _kHudMargin  = 60;   // don't go behind the HUD bottom padding

// Named targets (normalised 0-1 of the canvas)
const _kFoodBowl  = Offset(0.30, 0.80);
const _kWaterBowl = Offset(0.38, 0.80);
const _kBed       = Offset(0.20, 0.45);
const _kToy       = Offset(0.70, 0.55);
const _kBath      = Offset(0.80, 0.72);
const _kCarpet    = Offset(0.50, 0.65);

// ─────────────────────────────────────────────────────────────────────────────
// MyPetGame
// ─────────────────────────────────────────────────────────────────────────────
class MyPetGame extends FlameGame with TapCallbacks {
  final GameState gameState;
  double _statTimer = 0;

  // Map from pet.id → component so we can update without destroying
  final Map<String, PetGraphicComponent> _petComponents = {};

  MyPetGame(this.gameState);

  @override
  Color backgroundColor() => Colors.orange[100]!;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(NurseryBackgroundComponent());
    _syncPets();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Sync component map when pets join / leave
    _syncPets();

    // Passive stat decay every 5 s
    _statTimer += dt;
    if (_statTimer >= 5.0) {
      _statTimer = 0;
      bool changed = false;
      for (final pet in gameState.player?.activePets ?? []) {
        pet.stats.hunger    -= 0.5;
        pet.stats.thirst    -= 0.6;
        pet.stats.energy    -= 0.3;
        pet.stats.happiness -= 0.2;
        pet.stats.hygiene   -= 0.4;
        pet.stats.clamp();
        changed = true;
      }
      if (changed) gameState.requestNotify();
    }
  }

  void _syncPets() {
    final activePets = gameState.player?.activePets ?? [];
    final activeIds  = activePets.map((p) => p.id).toSet();

    // Remove stale components
    final staleIds = _petComponents.keys.where((id) => !activeIds.contains(id)).toList();
    for (final id in staleIds) {
      _petComponents[id]?.removeFromParent();
      _petComponents.remove(id);
    }

    // Add new pets (keep existing components alive!)
    for (int i = 0; i < activePets.length; i++) {
      final pet = activePets[i];
      if (!_petComponents.containsKey(pet.id)) {
        double spacing   = 160.0;
        double totalW    = (activePets.length - 1) * spacing;
        double startX    = size.x / 2 - totalW / 2;
        final spawnPos   = Vector2(startX + i * spacing, size.y * 0.55);

        final comp = PetGraphicComponent(
          pet: pet,
          gameState: gameState,
          spawnPosition: spawnPos,
        );
        _petComponents[pet.id] = comp;
        add(comp);
      }
    }
  }

  /// Convert normalised (0-1) to canvas pixels
  Vector2 scenePoint(double nx, double ny) => Vector2(size.x * nx, size.y * ny);

  Rect get playableRect => Rect.fromLTRB(
    60,
    size.y * _kWallBottom + 40,
    size.x - 60,
    size.y - _kHudMargin,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Background
// ─────────────────────────────────────────────────────────────────────────────
class NurseryBackgroundComponent extends PositionComponent with HasGameReference<MyPetGame> {
  @override
  Future<void> onLoad() async {
    super.onLoad();
    size = game.size;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  void render(Canvas canvas) {
    final w = size.x, h = size.y;

    // ── Wall ──────────────────────────────────────────────────────────────
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.30),
        Paint()..color = const Color(0xFFFBE9E7));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.28, w, h * 0.025),
        Paint()..color = const Color(0xFFFFCCBC));

    // ── Floor ─────────────────────────────────────────────────────────────
    canvas.drawRect(Rect.fromLTWH(0, h * 0.30, w, h * 0.70),
        Paint()..color = const Color(0xFFD7CCC8));
    final plank = Paint()
      ..color     = const Color(0xFFBCAAA4)
      ..strokeWidth = 2
      ..style     = PaintingStyle.stroke;
    for (int x = 0; x < w; x += 40) {
      canvas.drawLine(Offset(x.toDouble(), h * 0.30), Offset(x.toDouble(), h), plank);
    }

    // ── Door ──────────────────────────────────────────────────────────────
    canvas.drawRect(Rect.fromLTWH(w * 0.80, h * 0.04, 80, h * 0.26),
        Paint()..color = const Color(0xFF8D6E63));
    canvas.drawCircle(Offset(w * 0.80 + 15, h * 0.17), 5,
        Paint()..color = Colors.yellow[700]!);

    // ── Carpet ────────────────────────────────────────────────────────────
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.50, h * 0.65), width: 320, height: 160),
      Paint()..color = const Color(0xFFA5D6A7),
    );

    // ── Bed ───────────────────────────────────────────────────────────────
    final bedC = Offset(w * _kBed.dx, h * _kBed.dy);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: bedC, width: 130, height: 85),
          const Radius.circular(20)),
      Paint()..color = const Color(0xFF90CAF9),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: bedC, width: 100, height: 55),
          const Radius.circular(10)),
      Paint()..color = Colors.white,
    );

    // ── Food Bowl ─────────────────────────────────────────────────────────
    final foodC = Offset(w * _kFoodBowl.dx, h * _kFoodBowl.dy);
    canvas.drawOval(Rect.fromCenter(center: foodC, width: 50, height: 25),
        Paint()..color = Colors.red[300]!);
    canvas.drawOval(Rect.fromCenter(center: foodC.translate(0, -3), width: 36, height: 13),
        Paint()..color = Colors.brown[600]!);

    // ── Water Bowl ────────────────────────────────────────────────────────
    final waterC = Offset(w * _kWaterBowl.dx, h * _kWaterBowl.dy);
    canvas.drawOval(Rect.fromCenter(center: waterC, width: 50, height: 25),
        Paint()..color = Colors.blue[300]!);
    canvas.drawOval(Rect.fromCenter(center: waterC.translate(0, -3), width: 36, height: 13),
        Paint()..color = Colors.lightBlue[100]!);

    // ── Toy ───────────────────────────────────────────────────────────────
    final toyC = Offset(w * _kToy.dx, h * _kToy.dy);
    canvas.drawCircle(toyC, 18, Paint()..color = Colors.pinkAccent);
    canvas.drawCircle(toyC, 7,  Paint()..color = Colors.yellow);

    // ── Bath ──────────────────────────────────────────────────────────────
    final bathC = Offset(w * _kBath.dx, h * _kBath.dy);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: bathC, width: 110, height: 65),
          const Radius.circular(10)),
      Paint()..color = Colors.lightBlue[50]!,
    );
    canvas.drawOval(Rect.fromCenter(center: bathC, width: 90, height: 45),
        Paint()..color = Colors.lightBlue[200]!);
    // bubbles
    for (int b = 0; b < 4; b++) {
      canvas.drawCircle(Offset(bathC.dx - 30 + b * 20, bathC.dy - 25), 5,
          Paint()..color = Colors.white.withAlpha(180));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PetGraphicComponent — autonomous movement + action sequencing
// ─────────────────────────────────────────────────────────────────────────────
enum _MovePhase { idle, movingToTarget, atTarget, action, returning }

class PetGraphicComponent extends PositionComponent
    with HasGameReference<MyPetGame>, TapCallbacks {
  final Pet pet;
  final GameState gameState;

  late PositionComponent bodyGroup;
  late TextComponent     nameText;
  late TextComponent     feedbackText;

  double _time        = 0;
  double _phaseTimer  = 0;
  double _logTimer    = 0;

  _MovePhase _phase   = _MovePhase.idle;
  Vector2?   _target;          // current move target (pixels)
  double     _speed   = 90;    // pixels/sec
  bool       _facingRight = true;
  double     _actionDuration = 3.5;

  // Wander RNG seeded per-pet so they differ
  late final Random _rng;

  PetGraphicComponent({
    required this.pet,
    required this.gameState,
    required Vector2 spawnPosition,
  }) : super(
          position: spawnPosition.clone(),
          size:     Vector2(110, 110),
          anchor:   Anchor.center,
        ) {
    _rng = Random(pet.id.hashCode);
  }

  // ──────────────────────────────────────────────────── lifecycle
  @override
  Future<void> onLoad() async {
    bodyGroup = PositionComponent(
      position: Vector2(size.x / 2, size.y / 2),
      anchor:   Anchor.center,
    );
    add(bodyGroup);
    _buildBody();

    nameText = TextComponent(
      text:           pet.name,
      position:       Vector2(size.x / 2, -22),
      anchor:         Anchor.center,
      textRenderer:   TextPaint(style: const TextStyle(
          color: Color(0xFF5D4037), fontSize: 15, fontWeight: FontWeight.bold)),
    );
    add(nameText);

    feedbackText = TextComponent(
      text:         '',
      position:     Vector2(size.x / 2, -48),
      anchor:       Anchor.center,
      textRenderer: TextPaint(style: const TextStyle(
          color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold)),
    );
    add(feedbackText);

    // Start in idle, will begin wandering after first idle pause
    _phase      = _MovePhase.idle;
    _phaseTimer = _idlePause();
  }

  // ──────────────────────────────────────────────────── update
  @override
  void update(double dt) {
    super.update(dt);
    _time       += dt;
    _phaseTimer -= dt;
    _logTimer   -= dt;

    // Debug position log every 1 s
    if (_logTimer <= 0) {
      _logTimer = 1.0;
      debugPrint('[${pet.name}] pos=(${position.x.toStringAsFixed(0)}, ${position.y.toStringAsFixed(0)}) phase=$_phase action=${pet.currentAction.name}');
    }

    // ── Player-triggered intent ───────────────────────────────────────────
    if (pet.currentAction.name.startsWith('going_to_')) {
      if (_phase != _MovePhase.movingToTarget || !_isPlayerIntent) {
        _beginPlayerAction(pet.currentAction);
      }
    }

    // ── State machine ─────────────────────────────────────────────────────
    switch (_phase) {
      case _MovePhase.idle:
        if (_phaseTimer <= 0 && !pet.currentAction.name.startsWith('going_to_')) {
          _startWander();
        }
        break;

      case _MovePhase.movingToTarget:
        _stepTowardTarget(dt);
        break;

      case _MovePhase.atTarget:
        if (_phaseTimer <= 0) {
          _finishAction();
        }
        break;

      case _MovePhase.action:
        if (_phaseTimer <= 0) {
          _endActionReturnIdle();
        }
        break;

      case _MovePhase.returning:
        _stepTowardTarget(dt);
        break;
    }

    // ── Visual animation ──────────────────────────────────────────────────
    _animate(dt);
  }

  // ──────────────────────────────────────────────────── movement helpers
  bool get _isPlayerIntent => pet.currentAction.name.startsWith('going_to_');

  void _startWander() {
    final r = game.playableRect;
    final tx = r.left + _rng.nextDouble() * r.width;
    final ty = r.top  + _rng.nextDouble() * r.height;
    _target = Vector2(tx, ty);
    _speed  = 60 + _rng.nextDouble() * 50; // 60-110 px/s
    _phase  = _MovePhase.movingToTarget;
    _isPlayerIntentFlag = false;
  }

  bool _isPlayerIntentFlag = false;

  void _beginPlayerAction(PetAction intent) {
    final g = game;
    Vector2 dest;
    switch (intent) {
      case PetAction.going_to_eat:
        dest = g.scenePoint(_kFoodBowl.dx,  _kFoodBowl.dy);  break;
      case PetAction.going_to_drink:
        dest = g.scenePoint(_kWaterBowl.dx, _kWaterBowl.dy); break;
      case PetAction.going_to_sleep:
        dest = g.scenePoint(_kBed.dx,       _kBed.dy);        break;
      case PetAction.going_to_play:
        dest = g.scenePoint(_kToy.dx,       _kToy.dy);        break;
      case PetAction.going_to_bath:
        dest = g.scenePoint(_kBath.dx,      _kBath.dy);       break;
      case PetAction.going_to_walk:
        dest = g.scenePoint(_kCarpet.dx,    _kCarpet.dy);     break;
      default:
        return;
    }
    _target              = dest;
    _speed               = 120; // faster when commanded
    _phase               = _MovePhase.movingToTarget;
    _isPlayerIntentFlag  = true;
    _phaseTimer          = 0;
  }

  void _stepTowardTarget(double dt) {
    if (_target == null) { _phase = _MovePhase.idle; return; }

    final delta = _target! - position;
    if (delta.length <= 6) {
      // Arrived
      position.setFrom(_target!);
      if (_isPlayerIntentFlag) {
        _onArrivedAtPlayerTarget();
      } else {
        // Wander arrived → idle pause
        _phase      = _MovePhase.idle;
        _phaseTimer = _idlePause();
        pet.currentAction = PetAction.idle;
      }
    } else {
      final dir = delta.normalized();
      position.addScaled(dir, _speed * dt);
      _facingRight = dir.x >= 0;
    }
  }

  void _onArrivedAtPlayerTarget() {
    _phase         = _MovePhase.atTarget;
    _phaseTimer    = 0.15; // tiny settle pause
    _isPlayerIntentFlag = false;
  }

  void _finishAction() {
    // Apply stat effect + transition to action animation
    switch (pet.currentAction) {
      case PetAction.going_to_eat:
        gameState.completeFeedPet(pet);
        _actionDuration = 3.0;
        break;
      case PetAction.going_to_drink:
        gameState.completeDrinkPet(pet);
        _actionDuration = 2.5;
        break;
      case PetAction.going_to_play:
        gameState.completePlayWithPet(pet);
        _actionDuration = 4.0;
        break;
      case PetAction.going_to_sleep:
        gameState.completeSleepPet(pet);
        _actionDuration = 5.0;
        break;
      case PetAction.going_to_bath:
        gameState.completeBathePet(pet);
        _actionDuration = 3.5;
        break;
      case PetAction.going_to_walk:
        gameState.completeWalkPet(pet);
        _actionDuration = 3.0;
        break;
      default:
        gameState.endAction(pet);
        _phase = _MovePhase.idle;
        _phaseTimer = _idlePause();
        return;
    }
    _phase      = _MovePhase.action;
    _phaseTimer = _actionDuration;
  }

  void _endActionReturnIdle() {
    gameState.endAction(pet);
    _phase      = _MovePhase.idle;
    _phaseTimer = _idlePause();
  }

  double _idlePause() => 2.0 + _rng.nextDouble() * 3.0; // 2-5 s

  // ──────────────────────────────────────────────────── visuals
  void _buildBody() {
    switch (pet.species) {
      case 'cat':    _buildCat();    break;
      case 'hamster':_buildHamster();break;
      case 'rabbit': _buildRabbit(); break;
      case 'dog':
      default:       _buildDog();    break;
    }
    // Eyes (shared)
    bodyGroup.add(CircleComponent(radius: 4, paint: Paint()..color = Colors.black,
        position: Vector2(-13, -10), anchor: Anchor.center));
    bodyGroup.add(CircleComponent(radius: 4, paint: Paint()..color = Colors.black,
        position: Vector2(13,  -10), anchor: Anchor.center));
    // Nose
    bodyGroup.add(CircleComponent(radius: 3, paint: Paint()..color = Colors.black,
        position: Vector2(0, 2), anchor: Anchor.center));
  }

  void _buildDog() {
    final c = Colors.brown[400]!;
    final e = Colors.brown[800]!;
    bodyGroup.add(CircleComponent(radius: 42, paint: Paint()..color = c, anchor: Anchor.center));
    bodyGroup.add(CircleComponent(radius: 14, paint: Paint()..color = e,
        position: Vector2(-32, -8), anchor: Anchor.center)..scale = Vector2(1, 2.2));
    bodyGroup.add(CircleComponent(radius: 14, paint: Paint()..color = e,
        position: Vector2(32, -8), anchor: Anchor.center)..scale = Vector2(1, 2.2));
  }

  void _buildCat() {
    final c = Colors.grey[700]!;
    bodyGroup.add(CircleComponent(radius: 38, paint: Paint()..color = c, anchor: Anchor.center));
    bodyGroup.add(RectangleComponent(size: Vector2(18, 18), paint: Paint()..color = c,
        position: Vector2(-22, -34), anchor: Anchor.center, angle: 0.5));
    bodyGroup.add(RectangleComponent(size: Vector2(18, 18), paint: Paint()..color = c,
        position: Vector2(22, -34), anchor: Anchor.center, angle: -0.5));
  }

  void _buildHamster() {
    final c = Colors.orange[300]!;
    bodyGroup.add(CircleComponent(radius: 33, paint: Paint()..color = c, anchor: Anchor.center));
    bodyGroup.add(CircleComponent(radius: 18, paint: Paint()..color = Colors.white,
        position: Vector2(0, 12), anchor: Anchor.center)..scale = Vector2(1.2, 0.8));
    bodyGroup.add(CircleComponent(radius: 9, paint: Paint()..color = c,
        position: Vector2(-23, -22), anchor: Anchor.center));
    bodyGroup.add(CircleComponent(radius: 9, paint: Paint()..color = c,
        position: Vector2(23, -22), anchor: Anchor.center));
  }

  void _buildRabbit() {
    final c = Colors.white;
    final e = Colors.pink[100]!;
    bodyGroup.add(CircleComponent(radius: 38, paint: Paint()..color = c, anchor: Anchor.center));
    bodyGroup.add(CircleComponent(radius: 11, paint: Paint()..color = c,
        position: Vector2(-18, -38), anchor: Anchor.center)..scale = Vector2(1, 3.2));
    bodyGroup.add(CircleComponent(radius: 11, paint: Paint()..color = c,
        position: Vector2(18, -38), anchor: Anchor.center)..scale = Vector2(1, 3.2));
    bodyGroup.add(CircleComponent(radius: 6, paint: Paint()..color = e,
        position: Vector2(-18, -38), anchor: Anchor.center)..scale = Vector2(1, 2.6));
    bodyGroup.add(CircleComponent(radius: 6, paint: Paint()..color = e,
        position: Vector2(18, -38), anchor: Anchor.center)..scale = Vector2(1, 2.6));
  }

  void _animate(double dt) {
    double yOff  = 0;
    double rot   = 0;
    double scaleY = 1.0;

    final isWalking = _phase == _MovePhase.movingToTarget || _phase == _MovePhase.returning;
    final action    = pet.currentAction;

    if (isWalking) {
      // Walk bounce
      yOff = (_time % 0.35 > 0.175) ? -6 : 0;
      rot  = (_time % 0.35 > 0.175) ? 0.06 : -0.06;
    } else {
      switch (action) {
        case PetAction.eating:
          yOff = (_time % 0.40 > 0.20) ? 12 : 0; // peck
          break;
        case PetAction.drinking:
          yOff = (_time % 0.55 > 0.28) ? 9 : 0;
          break;
        case PetAction.playing:
          yOff = (_time % 0.55 > 0.28) ? -18 : 0;
          rot  = (_time % 0.55 > 0.28) ? 0.22 : -0.22;
          break;
        case PetAction.bathing:
          rot  = (_time % 0.35 > 0.175) ? 0.12 : -0.12;
          break;
        case PetAction.sleeping:
          scaleY = (_time % 2.0 > 1.0) ? 1.06 : 0.94;
          yOff   = 15;
          break;
        case PetAction.petting:
          scaleY = 1.12;
          rot    = (_time % 0.90 > 0.45) ? 0.06 : -0.06;
          break;
        case PetAction.walking:
          yOff = (_time % 0.35 > 0.175) ? -10 : 0;
          rot  = (_time % 0.35 > 0.175) ?  0.10 : -0.10;
          break;
        default: // idle
          yOff = (_time % 2.0 > 1.0) ? -3 : 0;
      }
    }

    // Apply
    bodyGroup.position.y = (size.y / 2) + yOff;
    bodyGroup.angle      = rot;
    bodyGroup.scale.y    = scaleY;

    // Face direction (preserve scale)
    final scaleX = _facingRight ? 1.0 : -1.0;
    bodyGroup.scale.x = scaleX * scaleY;

    // Name highlight when selected
    final isSelected = gameState.selectedPet?.id == pet.id;
    nameText.textRenderer = TextPaint(
      style: TextStyle(
        color:      isSelected ? const Color(0xFFD32F2F) : const Color(0xFF5D4037),
        fontSize:   isSelected ? 18 : 14,
        fontWeight: FontWeight.bold,
      ),
    );

    // Feedback text float up
    if (pet.currentActionMessage != null && pet.currentActionMessage!.isNotEmpty) {
      feedbackText.text = pet.currentActionMessage!;
      feedbackText.position.y = (feedbackText.position.y - dt * 18).clamp(-80, -48);
    } else {
      feedbackText.text       = '';
      feedbackText.position.y = -48;
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    gameState.selectPet(pet);
  }
}
