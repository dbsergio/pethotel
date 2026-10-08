import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/audio/audio_service.dart';
import '../../../game/models/pet.dart';
import '../../../game/minigames/minigame_result.dart';
import '../../../data/local/game_state.dart';

class BathMinigame extends StatefulWidget {
  final Pet pet;

  const BathMinigame({super.key, required this.pet});

  @override
  State<BathMinigame> createState() => _BathMinigameState();
}

class _BathMinigameState extends State<BathMinigame> {
  double _cleanliness = 0.0;
  final double _maxCleanliness = 100.0;
  int _availableSoap = 0;

  // Track last touch position to calculate distance swiped
  Offset? _lastTouch;
  bool _isFinished = false;
  DateTime _lastAudioTime = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    final gs = context.read<GameState>();
    _availableSoap = gs.getInventoryQuantity('soap_basic');
  }

  void _onPanStart(DragStartDetails details) {
    if (_availableSoap == 0) return;
    _lastTouch = details.localPosition;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_availableSoap == 0) return;
    if (_lastTouch != null && !_isFinished) {
      final distance = (details.localPosition - _lastTouch!).distance;
      setState(() {
        _cleanliness += distance * 0.2; // Adjust multiplier for difficulty
        if (_cleanliness > _maxCleanliness) {
          _cleanliness = _maxCleanliness;
        }
      });
      _lastTouch = details.localPosition;

      final now = DateTime.now();
      if (now.difference(_lastAudioTime).inMilliseconds > 800) {
        context.read<AudioService>().playActionBath();
        _lastAudioTime = now;
      }

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
      consumedItems: {
        'soap_basic': 1,
      }
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_availableSoap == 0) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.lightBlue[50],
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.blue, width: 4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('😢', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 16),
              const Text(
                'No tienes jabón',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Visita la tienda para comprar más jabón para tu mascota.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(CareMinigameResult.cancelled()),
                child: const Text('Entendido'),
              ),
            ],
          ),
        ),
      );
    }

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
