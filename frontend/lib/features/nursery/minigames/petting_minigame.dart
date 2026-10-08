import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/audio/audio_service.dart';
import '../../../game/models/pet.dart';
import '../../../game/minigames/minigame_result.dart';

class PettingMinigame extends StatefulWidget {
  final Pet pet;

  const PettingMinigame({super.key, required this.pet});

  @override
  State<PettingMinigame> createState() => _PettingMinigameState();
}

class _PettingMinigameState extends State<PettingMinigame> {
  int _swipes = 0;
  final int _maxSwipes = 4;
  Offset? _lastTouch;

  // List of active hearts to show on screen
  final List<_HeartEffect> _hearts = [];

  void _onPanStart(DragStartDetails details) {
    _lastTouch = details.localPosition;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_lastTouch != null) {
      final distance = (details.localPosition - _lastTouch!).distance;
      if (distance > 30) {
        // Registered a swipe
        _swipes++;
        _lastTouch = details.localPosition;
        
        setState(() {
          _hearts.add(_HeartEffect(
            position: details.localPosition,
            id: DateTime.now().millisecondsSinceEpoch,
          ));
        });

        // Clean up old hearts
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() {
              if (_hearts.isNotEmpty) _hearts.removeAt(0);
            });
          }
        });

        if (_swipes >= _maxSwipes) {
          _lastTouch = null;
          _finishGame();
        }
      }
    }
  }

  void _onPanEnd(DragEndDetails details) {
    _lastTouch = null;
  }
  
  void _finishGame() {
    final audio = context.read<AudioService>();
    if (widget.pet.species == 'dog') {
      audio.playDogHappy();
    } else if (widget.pet.species == 'cat') {
      audio.playCatMeow();
    } else {
      audio.playActionPetting();
    }

    final result = CareMinigameResult(
      success: true,
      quality: 1.0,
      statChanges: {
        'happiness': 15.0,
      },
    );

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 350,
        height: 400,
        decoration: BoxDecoration(
          color: Colors.pink[50],
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.pink, width: 4),
        ),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 10),
            Text(
              'Acaricia a ${widget.pet.name}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.pink),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Center(
                child: GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: Container(
                    width: 250,
                    height: 250,
                    color: Colors.transparent, // Important for gesture detection
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Pet
                        const Text('🐶', style: TextStyle(fontSize: 100)),
                        // Hearts
                        ..._hearts.map((heart) {
                          return Positioned(
                            left: heart.position.dx - 20,
                            top: heart.position.dy - 30,
                            child: const _AnimatedHeart(),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _swipes / _maxSwipes,
                  minHeight: 12,
                  color: Colors.pink,
                  backgroundColor: Colors.pink[100],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.pink,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '¡Mimos!',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(CareMinigameResult.cancelled()),
          ),
        ],
      ),
    );
  }
}

class _HeartEffect {
  final Offset position;
  final int id;
  _HeartEffect({required this.position, required this.id});
}

class _AnimatedHeart extends StatefulWidget {
  const _AnimatedHeart();
  @override
  State<_AnimatedHeart> createState() => _AnimatedHeartState();
}

class _AnimatedHeartState extends State<_AnimatedHeart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _slideAnimation = Tween<double>(begin: 0, end: -40).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _opacityAnimation = Tween<double>(begin: 1, end: 0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: const Text('💖', style: TextStyle(fontSize: 40)),
          ),
        );
      },
    );
  }
}
