import 'package:flutter/material.dart';
import '../../../game/models/pet.dart';
import '../../../game/minigames/minigame_result.dart';

class BathMinigame extends StatefulWidget {
  final Pet pet;

  const BathMinigame({super.key, required this.pet});

  @override
  State<BathMinigame> createState() => _BathMinigameState();
}

class _BathMinigameState extends State<BathMinigame> {
  double _cleanliness = 0.0;
  final double _maxCleanliness = 100.0;
  
  // Track last touch position to calculate distance swiped
  Offset? _lastTouch;
  bool _isFinished = false;

  void _onPanStart(DragStartDetails details) {
    _lastTouch = details.localPosition;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_lastTouch != null && !_isFinished) {
      final distance = (details.localPosition - _lastTouch!).distance;
      setState(() {
        _cleanliness += distance * 0.2; // Adjust multiplier for difficulty
        if (_cleanliness > _maxCleanliness) {
          _cleanliness = _maxCleanliness;
        }
      });
      _lastTouch = details.localPosition;
      
      if (_cleanliness >= _maxCleanliness) {
        _isFinished = true;
        _finishGame();
      }
    }
  }

  void _onPanEnd(DragEndDetails details) {
    _lastTouch = null;
  }
  
  void _finishGame() {
    final result = CareMinigameResult(
      success: true,
      quality: 1.0,
      statChanges: {
        'hygiene': 30.0,
        'happiness': 5.0,
      },
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Dirt opacity decreases as cleanliness increases
    final dirtOpacity = (1.0 - (_cleanliness / _maxCleanliness)).clamp(0.0, 1.0);
    
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 350,
        height: 400,
        decoration: BoxDecoration(
          color: Colors.lightBlue[50],
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.blue, width: 4),
        ),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 10),
            Text(
              'Limpia a ${widget.pet.name}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey),
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
                      children: [
                        // Pet
                        const Text('🐶', style: TextStyle(fontSize: 100)),
                        // Dirt layer overlay
                        Opacity(
                          opacity: dirtOpacity,
                          child: const Text('💩', style: TextStyle(fontSize: 80)),
                        ),
                        // Soap bubbles when swiping
                        if (_lastTouch != null)
                          Positioned(
                            left: _lastTouch!.dx - 25,
                            top: _lastTouch!.dy - 25,
                            child: const Text('🫧', style: TextStyle(fontSize: 50)),
                          ),
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
                  value: _cleanliness / _maxCleanliness,
                  minHeight: 12,
                  color: Colors.blue,
                  backgroundColor: Colors.blue[100],
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
        color: Colors.blue,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '¡Hora del baño!',
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
