import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../data/local/game_state.dart';
import 'components/pet_graphic_component.dart';
import 'components/nursery_objects.dart';
import 'components/customer_graphic_component.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'models/pet.dart';
import 'models/boarding_stay.dart';
import 'models/customer.dart' as import_customer;

// ─────────────────────────────────────────────────────────────────────────────
// Playable area (pixels, relative to canvas)
// ─────────────────────────────────────────────────────────────────────────────
const double _kWallBottom = 0.30; // floor starts at 30 % of canvas height
const double _kHudMargin  = 60;   // don't go behind the HUD bottom padding

// ─────────────────────────────────────────────────────────────────────────────
// MyPetGame
// ─────────────────────────────────────────────────────────────────────────────
class MyPetGame extends FlameGame with TapCallbacks {
  static const Offset kFoodBowl  = Offset(0.30, 0.80);
  static const Offset kWaterBowl = Offset(0.38, 0.80);
  static const Offset kBed       = Offset(0.20, 0.45);
  static const Offset kToy       = Offset(0.70, 0.55);
  static const Offset kBath      = Offset(0.80, 0.72);
  static const Offset kCarpet    = Offset(0.50, 0.65);

  final GameState gameState;
  double _statTimer = 0;

  // Map from pet.id → component so we can update without destroying
  final Map<String, PetGraphicComponent> _petComponents = {};

  CustomerGraphicComponent? _incomingCustomer;
  PetGraphicComponent? _incomingPet;

  final Set<String> _spawnedRetrievers = {};
  final Map<String, CustomerGraphicComponent> _retrievingCustomers = {};

  MyPetGame(this.gameState);

  @override
  Color backgroundColor() => Colors.orange[100]!;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Priority 0 → hit-tested LAST, so pets (priority 10) win
    add(NurseryBackgroundComponent()..priority = 0);
    // Objects at priority 5 — interactive but below pets
    add(CarpetComponent(position: scenePoint(kCarpet.dx, kCarpet.dy))..priority = 5);
    add(BedComponent(position: scenePoint(kBed.dx, kBed.dy))..priority = 5);
    add(FoodBowlComponent(position: scenePoint(kFoodBowl.dx, kFoodBowl.dy))..priority = 5);
    add(WaterBowlComponent(position: scenePoint(kWaterBowl.dx, kWaterBowl.dy))..priority = 5);
    add(ToyComponent(position: scenePoint(kToy.dx, kToy.dy))..priority = 5);
    add(BathComponent(position: scenePoint(kBath.dx, kBath.dy))..priority = 5);
    _syncPets();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Sync component map when pets join / leave
    _syncPets();

    // Passive stat decay and stay checks every 5 s
    _statTimer += dt;
    if (_statTimer >= 5.0) {
      _statTimer = 0;
      gameState.checkStays();
      
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

      // Check for ready pickups to spawn customers
      for (final stay in gameState.player?.activeStays ?? []) {
        if (stay.status == StayStatus.readyForPickup && !_spawnedRetrievers.contains(stay.id)) {
          _spawnedRetrievers.add(stay.id);
          
          final startPos = scenePoint(0.85, 0.30); // Door
          final cust = CustomerGraphicComponent(
            customerName: stay.customer.name,
            position: startPos,
          );
          cust.priority = 15;
          add(cust);
          
          // Spread them out slightly around reception
          final offsetIndex = _retrievingCustomers.length;
          final receptionPos = scenePoint(0.4 + (offsetIndex * 0.1), 0.5);
          
          cust.walkTo(receptionPos, onComplete: () {
            // Arrived at reception
          });
          _retrievingCustomers[stay.id] = cust;
        }
      }
    }
  }

  void finishOutgoingSequence(BoardingStay stay) {
    final cust = _retrievingCustomers.remove(stay.id);
    if (cust != null) {
      cust.walkTo(scenePoint(0.85, 0.30), onComplete: () {
        cust.removeFromParent();
      }, duration: 3.0);
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
        Vector2 spawnPos;
        if (pet.currentAction == PetAction.walking_in) {
          spawnPos = Vector2(size.x * 0.85, size.y * 0.30);
        } else {
          double spacing   = 160.0;
          double totalW    = (activePets.length - 1) * spacing;
          double startX    = size.x / 2 - totalW / 2;
          spawnPos   = Vector2(startX + i * spacing, size.y * 0.55);
        }

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

  void startIncomingSequence(Pet pet, import_customer.Customer customer, String request, VoidCallback onDialogReady) {
    if (_incomingCustomer != null) return; // Sequence already in progress

    final startPos = scenePoint(0.85, 0.30); // Door
    
    _incomingCustomer = CustomerGraphicComponent(
      customerName: customer.name,
      position: startPos,
    );
    _incomingCustomer!.priority = 15; // Above pets
    add(_incomingCustomer!);

    _incomingPet = PetGraphicComponent(
      pet: pet,
      gameState: gameState,
      spawnPosition: startPos + Vector2(20, 20),
    );
    _incomingPet!.priority = 10;
    add(_incomingPet!);

    // They walk to the center
    final receptionPos = scenePoint(0.5, 0.5);
    
    _incomingCustomer!.walkTo(receptionPos, onComplete: onDialogReady, duration: 2.0);
    // Pet follows
    _incomingPet!.add(MoveToEffect(receptionPos + Vector2(60, 20), EffectController(duration: 2.0)));
  }

  void cancelIncomingSequence() {
    if (_incomingCustomer != null) {
      _incomingCustomer!.walkTo(scenePoint(0.85, 0.30), onComplete: () {
        _incomingCustomer?.removeFromParent();
        _incomingCustomer = null;
      }, duration: 1.5);
    }
    if (_incomingPet != null) {
      _incomingPet!.add(MoveToEffect(scenePoint(0.85, 0.30), EffectController(duration: 1.5)));
      Future.delayed(const Duration(milliseconds: 1500), () {
        _incomingPet?.removeFromParent();
        _incomingPet = null;
      });
    }
  }

  void finishIncomingSequence(Pet pet, VoidCallback onFinish) {
    // Customer leaves
    if (_incomingCustomer != null) {
      _incomingCustomer!.walkTo(scenePoint(0.85, 0.30), onComplete: () {
        _incomingCustomer?.removeFromParent();
        _incomingCustomer = null;
      }, duration: 1.5);
    }
    
    // Pet transfers to real game state!
    if (_incomingPet != null) {
      _incomingPet!.removeFromParent(); // Will be respawned by _syncPets
      _incomingPet = null;
    }
    onFinish(); // This will trigger gameState.adoptPet
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

    // Window with sunlight effect
    add(_WindowLightComponent());
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
    // Door shadow
    canvas.drawRect(Rect.fromLTWH(w * 0.80 - 5, h * 0.04 + 5, 80, h * 0.26),
        Paint()..color = Colors.black.withValues(alpha: 0.1));
    // Door frame
    canvas.drawRect(Rect.fromLTWH(w * 0.80 - 4, h * 0.04 - 4, 88, h * 0.26 + 4),
        Paint()..color = const Color(0xFF6D4C41));
    // Door
    canvas.drawRect(Rect.fromLTWH(w * 0.80, h * 0.04, 80, h * 0.26),
        Paint()..color = const Color(0xFF8D6E63));
    // Doorknob
    canvas.drawCircle(Offset(w * 0.80 + 15, h * 0.17), 5,
        Paint()..color = Colors.yellow[700]!);
  }
}

class _WindowLightComponent extends PositionComponent with HasGameReference<MyPetGame> {
  @override
  Future<void> onLoad() async {
    super.onLoad();
    // A slow moving sunlight across the floor
    add(
      MoveEffect.by(
        Vector2(40, 0),
        EffectController(duration: 10.0, alternate: true, infinite: true),
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    final w = game.size.x;
    final h = game.size.y;

    // Window frame on the wall
    canvas.drawRect(Rect.fromLTWH(w * 0.15 - 4, h * 0.05 - 4, 128, 108), Paint()..color = const Color(0xFFE0F7FA));
    canvas.drawRect(Rect.fromLTWH(w * 0.15, h * 0.05, 120, 100), Paint()..color = Colors.lightBlue[100]!);
    canvas.drawLine(Offset(w * 0.15 + 60, h * 0.05), Offset(w * 0.15 + 60, h * 0.05 + 100), Paint()..color = Colors.white..strokeWidth = 4);
    canvas.drawLine(Offset(w * 0.15, h * 0.05 + 50), Offset(w * 0.15 + 120, h * 0.05 + 50), Paint()..color = Colors.white..strokeWidth = 4);

    // Sunlight on the floor
    final path = Path()
      ..moveTo(w * 0.15 + 20, h * 0.30)
      ..lineTo(w * 0.15 + 140, h * 0.30)
      ..lineTo(w * 0.15 + 180, h * 0.50)
      ..lineTo(w * 0.15 + 60, h * 0.50)
      ..close();
    
    canvas.drawPath(path, Paint()..color = Colors.white.withValues(alpha: 0.15));
  }
}
