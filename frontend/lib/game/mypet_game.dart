import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../../data/local/game_state.dart';
import 'components/pet_graphic_component.dart';
import 'components/nursery_objects.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Playable area (pixels, relative to canvas)
// ─────────────────────────────────────────────────────────────────────────────
const double _kWallBottom = 0.30; // floor starts at 30 % of canvas height
const double _kHudMargin  = 60;   // don't go behind the HUD bottom padding

// ─────────────────────────────────────────────────────────────────────────────
// MyPetGame
// ─────────────────────────────────────────────────────────────────────────────
class MyPetGame extends FlameGame {
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

  MyPetGame(this.gameState);

  @override
  Color backgroundColor() => Colors.orange[100]!;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(NurseryBackgroundComponent());
    add(CarpetComponent(position: scenePoint(kCarpet.dx, kCarpet.dy)));
    add(BedComponent(position: scenePoint(kBed.dx, kBed.dy)));
    add(FoodBowlComponent(position: scenePoint(kFoodBowl.dx, kFoodBowl.dy)));
    add(WaterBowlComponent(position: scenePoint(kWaterBowl.dx, kWaterBowl.dy)));
    add(ToyComponent(position: scenePoint(kToy.dx, kToy.dy)));
    add(BathComponent(position: scenePoint(kBath.dx, kBath.dy)));
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

    // ── Carpet (Now a Component) ──────────────────────────────────────────
    // ── Bed (Now a Component) ─────────────────────────────────────────────
    // ── Food Bowl (Now a Component) ───────────────────────────────────────
    // ── Water Bowl (Now a Component) ──────────────────────────────────────
    // ── Toy (Now a Component) ─────────────────────────────────────────────
    // ── Bath (Now a Component) ────────────────────────────────────────────
  }
}
