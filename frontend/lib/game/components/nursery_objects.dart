import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../mypet_game.dart';

class BedComponent extends PositionComponent with HasGameReference<MyPetGame> {
  BedComponent({required super.position}) : super(size: Vector2(130, 85), anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    Color baseColor = const Color(0xFF90CAF9);
    final variant = game.gameState.getEquippedCosmetic('bed');
    if (variant == 'bed_pink') baseColor = Colors.pink[200]!;
    if (variant == 'bed_green') baseColor = Colors.green[300]!;

    canvas.drawRRect(
      RRect.fromRectAndRadius(size.toRect(), const Radius.circular(20)),
      Paint()..color = baseColor,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(size.x/2, size.y/2), width: 100, height: 55), const Radius.circular(10)),
      Paint()..color = Colors.white,
    );
  }
}

class FoodBowlComponent extends PositionComponent {
  FoodBowlComponent({required super.position}) : super(size: Vector2(50, 25), anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    canvas.drawOval(size.toRect(), Paint()..color = Colors.red[300]!);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.x/2, size.y/2 - 3), width: 36, height: 13), Paint()..color = Colors.brown[600]!);
    
    // kibble
    final cX = size.x/2;
    final cY = size.y/2;
    canvas.drawCircle(Offset(cX - 8, cY - 5), 4, Paint()..color = Colors.orange[800]!);
    canvas.drawCircle(Offset(cX + 5, cY - 4), 5, Paint()..color = Colors.orange[700]!);
    canvas.drawCircle(Offset(cX,     cY - 8), 4, Paint()..color = Colors.orange[900]!);
  }
}

class WaterBowlComponent extends PositionComponent {
  WaterBowlComponent({required super.position}) : super(size: Vector2(50, 25), anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    canvas.drawOval(size.toRect(), Paint()..color = Colors.blue[300]!);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.x/2, size.y/2 - 3), width: 36, height: 13), Paint()..color = Colors.lightBlue[100]!);
  }
}

class ToyComponent extends PositionComponent {
  ToyComponent({required super.position}) : super(size: Vector2(36, 36), anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset(size.x/2, size.y/2), 18, Paint()..color = Colors.pinkAccent);
    canvas.drawCircle(Offset(size.x/2, size.y/2), 7,  Paint()..color = Colors.yellow);
  }
}

class BathComponent extends PositionComponent {
  BathComponent({required super.position}) : super(size: Vector2(110, 65), anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(size.toRect(), const Radius.circular(10)),
      Paint()..color = Colors.lightBlue[50]!,
    );
    canvas.drawOval(Rect.fromCenter(center: Offset(size.x/2, size.y/2), width: 90, height: 45), Paint()..color = Colors.lightBlue[200]!);
    // bubbles
    for (int b = 0; b < 4; b++) {
      canvas.drawCircle(Offset(size.x/2 - 30 + b * 20, size.y/2 - 25), 5, Paint()..color = Colors.white.withAlpha(180));
    }
  }
}

class CarpetComponent extends PositionComponent with HasGameReference<MyPetGame> {
  CarpetComponent({required super.position}) : super(size: Vector2(320, 160), anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    Color baseColor = const Color(0xFFA5D6A7);
    final variant = game.gameState.getEquippedCosmetic('carpet');
    if (variant == 'carpet_red') baseColor = Colors.red[300]!;
    if (variant == 'carpet_purple') baseColor = Colors.purple[300]!;

    canvas.drawOval(size.toRect(), Paint()..color = baseColor);
  }
}
