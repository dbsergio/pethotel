import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

enum CustomerVisualState { entering, waiting, talking, leaving, returningForPickup }

class CustomerGraphicComponent extends PositionComponent {
  final String customerName;
  CustomerVisualState state;
  
  CustomerGraphicComponent({
    required this.customerName,
    this.state = CustomerVisualState.entering,
    Vector2? position,
  }) : super(position: position, size: Vector2(60, 140)) {
    anchor = Anchor.bottomCenter; // Anchor at the feet
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Idle breathing animation
    add(
      ScaleEffect.by(
        Vector2(1.0, 0.96),
        EffectController(duration: 1.2, alternate: true, infinite: true),
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    // Body
    final bodyPaint = Paint()..color = Colors.indigo[400]!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(10, 40, 40, 70), const Radius.circular(10)),
      bodyPaint,
    );
    
    // Head
    final headPaint = Paint()..color = Colors.orange[200]!;
    canvas.drawCircle(const Offset(30, 20), 20, headPaint);

    // Legs
    final legPaint = Paint()..color = Colors.grey[800]!;
    canvas.drawRect(const Rect.fromLTWH(15, 110, 10, 30), legPaint);
    canvas.drawRect(const Rect.fromLTWH(35, 110, 10, 30), legPaint);

    // Name tag
    final textPainter = TextPainter(
      text: TextSpan(
        text: customerName,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.white, blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.x / 2 - textPainter.width / 2, -25));
  }

  void walkTo(Vector2 target, {required VoidCallback onComplete, double duration = 2.0}) {
    add(
      MoveToEffect(
        target,
        EffectController(duration: duration),
        onComplete: onComplete,
      ),
    );
  }
}
