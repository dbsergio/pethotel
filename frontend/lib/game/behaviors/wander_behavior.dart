import 'dart:math';
import 'package:flame/components.dart';
import '../components/pet_graphic_component.dart';
import '../mypet_game.dart';

class WanderBehavior extends Component with ParentIsA<PetGraphicComponent>, HasGameReference<MyPetGame> {
  late final Random _rng;
  double _pauseTimer = 0;
  bool _isPaused = false;
  
  @override
  Future<void> onLoad() async {
    _rng = Random(parent.pet.id.hashCode);
    _pauseTimer = _idlePause();
  }

  void pause() {
    _isPaused = true;
    parent.movement.cancel();
  }
  
  void resume() {
    _isPaused = false;
    _pauseTimer = _idlePause();
  }

  @override
  void update(double dt) {
    if (_isPaused) return;

    if (!parent.movement.isMoving) {
      _pauseTimer -= dt;
      if (_pauseTimer <= 0) {
        _startWander();
      }
    }
  }

  void _startWander() {
    final r = game.playableRect;
    final tx = r.left + _rng.nextDouble() * r.width;
    final ty = r.top  + _rng.nextDouble() * r.height;
    
    final speed = 50 + _rng.nextDouble() * 40; // 50-90 px/s
    
    parent.movement.moveTo(
      Vector2(tx, ty), 
      speed: speed,
      onComplete: () {
        _pauseTimer = _idlePause();
      },
    );
  }

  double _idlePause() => 2.0 + _rng.nextDouble() * 4.0; // 2-6 s
}
