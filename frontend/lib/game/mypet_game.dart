import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../data/local/game_state.dart';
import 'components/pet_graphic_component.dart';
import 'components/nursery_objects.dart';
import 'components/customer_graphic_component.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'models/pet.dart';
import 'models/boarding_stay.dart';
import 'models/customer.dart' as import_customer;
import '../core/config/app_config.dart';
import 'minigames/play_minigame_toy.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Playable area (pixels, relative to canvas)
// ─────────────────────────────────────────────────────────────────────────────
const double _kWallBottom = 0.30; // floor starts at 30 % of canvas height
const double _kHudMargin  = 60;   // don't go behind the HUD bottom padding

// ─────────────────────────────────────────────────────────────────────────────
// MyPetGame
// ─────────────────────────────────────────────────────────────────────────────
class MyPetGame extends FlameGame with TapCallbacks, DragCallbacks {
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

  Vector2 get virtualSize {
    // We want a minimum world size to guarantee objects are not cramped.
    // If the screen is larger, we just use the screen size (desktop).
    final double w = size.x < 800 ? 800 : size.x;
    final double h = size.y < 600 ? 600 : size.y;
    return Vector2(w, h);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // 1 logical pixel = 1 virtual pixel.
    camera.viewfinder.zoom = 1.0;
    _clampCamera();
  }

  void _clampCamera() {
    if (!camera.isMounted) return;
    final visibleWidth = size.x / camera.viewfinder.zoom;
    final visibleHeight = size.y / camera.viewfinder.zoom;

    final minX = visibleWidth / 2;
    final maxX = virtualSize.x - visibleWidth / 2;
    final minY = visibleHeight / 2;
    final maxY = virtualSize.y - visibleHeight / 2;

    double px = camera.viewfinder.position.x;
    double py = camera.viewfinder.position.y;

    if (px < minX) px = minX;
    if (px > maxX) px = maxX;
    if (py < minY) py = minY;
    if (py > maxY) py = maxY;

    // Center if visible area is larger than virtual world (desktop)
    if (visibleWidth >= virtualSize.x) px = virtualSize.x / 2;
    if (visibleHeight >= virtualSize.y) py = virtualSize.y / 2;

    camera.viewfinder.position = Vector2(px, py);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    // Move the camera in the opposite direction of the drag to pan the world
    camera.viewfinder.position -= event.localDelta;
    _clampCamera();
  }

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    if (!event.handled) {
      gameState.selectPetById(null);
    }
  }

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
          
          Future.delayed(Duration(seconds: AppConfig.pickupDelaySeconds), () {
            // Re-check if it's still ready in case of weird state changes
            if (stay.status != StayStatus.readyForPickup) return;
            
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
              stay.status = StayStatus.pickingUp;
              gameState.requestNotify(); // Tell UI to show 'ENTREGAR'
            });
            _retrievingCustomers[stay.id] = cust;
          });
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

  void startPlayMinigame(Pet pet) {
    // Stop any existing action gracefully
    if (pet.currentAction != PetAction.idle) {
       gameState.resetActionState(pet);
    }
    
    gameState.playWithPet(); // Sets going_to_play

    // Spawn toy at random reachable location
    final toy = PlayMinigameToy(
      pet: pet,
      gameState: gameState,
      position: scenePoint(0.5, 0.5),
      onComplete: () {}, // Handled internally
    );
    toy.priority = 20; // Above everything
    add(toy);
  }

  /// Convert normalised (0-1) to virtual pixels
  Vector2 scenePoint(double nx, double ny) => Vector2(virtualSize.x * nx, virtualSize.y * ny);

  Rect get playableRect => Rect.fromLTRB(
    60,
    virtualSize.y * _kWallBottom + 40,
    virtualSize.x - 60,
    virtualSize.y - _kHudMargin,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Background
// ─────────────────────────────────────────────────────────────────────────────
class NurseryBackgroundComponent extends PositionComponent with HasGameReference<MyPetGame> {
  @override
  Future<void> onLoad() async {
    super.onLoad();
    size = game.virtualSize;

    // Window with sunlight effect
    add(_WindowLightComponent());
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = game.virtualSize;
  }

  @override
  void render(Canvas canvas) {
    final w = size.x, h = size.y;

    // ── Wall ──────────────────────────────────────────────────────────────
    // Wall gradient (darker at bottom for ambient occlusion)
    final wallPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, h * 0.30),
        [const Color(0xFFFFF3E0), const Color(0xFFFFCCBC)],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.30), wallPaint);

    // Wallpaper stripes (subtle)
    final stripePaint = Paint()..color = Colors.white.withValues(alpha: 0.2);
    for (double x = 0; x < w; x += 60) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 30, h * 0.30), stripePaint);
    }

    // Baseboard (zócalo) with depth
    canvas.drawRect(Rect.fromLTWH(0, h * 0.28, w, h * 0.02), Paint()..color = const Color(0xFFEFEBE9));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.30, w, 2), Paint()..color = const Color(0xFFBCAAA4)); // Shadow edge

    // ── Floor ─────────────────────────────────────────────────────────────
    // Isometric depth gradient for the floor
    final floorPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, h * 0.30),
        Offset(0, h),
        [const Color(0xFFA1887F), const Color(0xFFD7CCC8)], // Darker at back
      );
    canvas.drawRect(Rect.fromLTWH(0, h * 0.30, w, h * 0.70), floorPaint);

    // Floor planks with perspective illusion (diagonal or fading)
    final plankPaint = Paint()
      ..color = const Color(0xFF8D6E63).withValues(alpha: 0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    // Draw horizontal plank lines that get wider apart
    for (double y = h * 0.35; y < h; y += (y - h * 0.30) * 0.2) {
      canvas.drawLine(Offset(0, y), Offset(w, y), plankPaint);
    }
    // Draw vertical planks
    for (double x = 0; x < w; x += 50) {
      canvas.drawLine(Offset(x, h * 0.30), Offset(x, h), plankPaint);
    }

    // ── Door ──────────────────────────────────────────────────────────────
    // Door shadow on wall
    canvas.drawRect(Rect.fromLTWH(w * 0.80 - 10, h * 0.04 + 10, 80, h * 0.26),
        Paint()..color = Colors.black.withValues(alpha: 0.15));
    // Door frame
    canvas.drawRect(Rect.fromLTWH(w * 0.80 - 6, h * 0.04 - 6, 92, h * 0.26 + 6),
        Paint()..color = const Color(0xFF5D4037));
    // Door depth
    canvas.drawRect(Rect.fromLTWH(w * 0.80 - 2, h * 0.04 - 2, 84, h * 0.26 + 2),
        Paint()..color = const Color(0xFF3E2723));
    // Door
    canvas.drawRect(Rect.fromLTWH(w * 0.80, h * 0.04, 80, h * 0.26),
        Paint()..color = const Color(0xFF8D6E63));
    
    // Door panels
    final panelPaint = Paint()..color = const Color(0xFF6D4C41)..style = PaintingStyle.stroke..strokeWidth = 2;
    canvas.drawRect(Rect.fromLTWH(w * 0.80 + 10, h * 0.06, 60, h * 0.08), panelPaint);
    canvas.drawRect(Rect.fromLTWH(w * 0.80 + 10, h * 0.16, 60, h * 0.12), panelPaint);

    // Doorknob
    canvas.drawCircle(Offset(w * 0.80 + 15, h * 0.17), 5, Paint()..color = const Color(0xFFFFD54F));
    canvas.drawCircle(Offset(w * 0.80 + 15, h * 0.17), 2, Paint()..color = const Color(0xFFFFECB3)); // Highlight
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
    final w = game.virtualSize.x;
    final h = game.virtualSize.y;

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
