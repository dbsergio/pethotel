import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class RoundedRectangleComponent extends PositionComponent {
  final Paint paint;
  final double radius;

  RoundedRectangleComponent({
    required Vector2 size,
    required this.paint,
    this.radius = 10,
    Vector2? position,
    Anchor? anchor,
  }) : super(size: size, position: position, anchor: anchor);

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(size.toRect(), Radius.circular(radius)),
      paint,
    );
  }
}

class EllipseComponent extends PositionComponent {
  final Paint paint;

  EllipseComponent({
    required Vector2 size,
    required this.paint,
    Vector2? position,
    Anchor? anchor,
  }) : super(size: size, position: position, anchor: anchor);

  @override
  void render(Canvas canvas) {
    canvas.drawOval(size.toRect(), paint);
  }
}

class TriangleComponent extends PositionComponent {
  final Paint paint;

  TriangleComponent({
    required Vector2 size,
    required this.paint,
    Vector2? position,
    Anchor? anchor,
  }) : super(size: size, position: position, anchor: anchor);

  @override
  void render(Canvas canvas) {
    final path = Path();
    path.moveTo(size.x / 2, 0);
    path.lineTo(size.x, size.y);
    path.lineTo(0, size.y);
    path.close();
    canvas.drawPath(path, paint);
  }
}
