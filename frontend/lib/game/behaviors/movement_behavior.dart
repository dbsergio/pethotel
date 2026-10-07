import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/widgets.dart';
import '../components/pet_graphic_component.dart';

class MovementBehavior extends Component with ParentIsA<PetGraphicComponent> {
  MoveToEffect? _currentMove;

  bool get isMoving => _currentMove != null;

  void moveTo(Vector2 target, {double speed = 100, VoidCallback? onComplete}) {
    cancel();
    
    // Calculate duration based on distance and speed
    final distance = (parent.position - target).length;
    final duration = distance / speed;
    
    if (target.x > parent.position.x) {
      parent.facingRight = true;
    } else {
      parent.facingRight = false;
    }

    _currentMove = MoveToEffect(
      target,
      EffectController(duration: duration),
      onComplete: () {
        _currentMove = null;
        if (onComplete != null) onComplete();
      },
    );
    parent.add(_currentMove!);
  }

  void cancel() {
    if (_currentMove != null) {
      _currentMove!.removeFromParent();
      _currentMove = null;
    }
  }
}
