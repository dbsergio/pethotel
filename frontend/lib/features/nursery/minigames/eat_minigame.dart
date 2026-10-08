import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../game/models/pet.dart';
import '../../../game/minigames/minigame_result.dart';
import '../../../data/local/game_state.dart';

class EatMinigame extends StatefulWidget {
  final Pet pet;

  const EatMinigame({super.key, required this.pet});

  @override
  State<EatMinigame> createState() => _EatMinigameState();
}

class _EatMinigameState extends State<EatMinigame> {
  int _portionsInBowl = 0;
  int _maxPortions = 0;

  @override
  void initState() {
    super.initState();
    // Leer inventario inicial. Usamos read porque estamos en initState.
    final gs = context.read<GameState>();
    _maxPortions = gs.getInventoryQuantity('food_basic');
  }

  void _onFoodDropped() {
    if (_portionsInBowl < _maxPortions) {
      setState(() {
        _portionsInBowl++;
      });
    }
  }

  void _finishGame() {
    final double hunger = _portionsInBowl * 12.0;
    final double happiness = _portionsInBowl * 2.0;

    final result = CareMinigameResult(
      success: _portionsInBowl > 0,
      quality: _maxPortions > 0 ? _portionsInBowl / _maxPortions : 0,
      statChanges: {
        'hunger': hunger,
        'happiness': happiness,
      },
      consumedItems: {
        'food_basic': _portionsInBowl,
      },
    );

    // Pequeño retraso para ver el bowl lleno
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_maxPortions == 0) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.orange, width: 4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('😢', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 16),
              const Text(
                'No tienes comida',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Visita la tienda para comprar más comida para tu mascota.',
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

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 350,
        height: 400,
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.orange, width: 4),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Bowl
                  Positioned(
                    bottom: 20,
                    child: DragTarget<String>(
                      builder: (context, candidateData, rejectedData) {
                        return Container(
                          width: 120,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(40),
                            ),
                            border: Border.all(
                              color: candidateData.isNotEmpty ? Colors.green : Colors.grey[500]!,
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _portionsInBowl == 0
                                  ? 'Bowl vacío'
                                  : '🍖 x $_portionsInBowl',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                        );
                      },
                      onAcceptWithDetails: (details) {
                        _onFoodDropped();
                      },
                    ),
                  ),
                  
                  // Pet waiting
                  Positioned(
                    top: 20,
                    right: 40,
                    child: Column(
                      children: [
                        const Text('🐶', style: TextStyle(fontSize: 60)), // Simplified representation
                        Text(widget.pet.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),

                  // Food portions to drag
                  if (_portionsInBowl < _maxPortions)
                    Positioned(
                      top: 100,
                      left: 40,
                      child: Draggable<String>(
                        data: 'food',
                        feedback: const Text('🍖', style: TextStyle(fontSize: 50, decoration: TextDecoration.none)),
                        childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: const Text('🍖', style: TextStyle(fontSize: 50)),
                        ),
                        child: const Text('🍖', style: TextStyle(fontSize: 50)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Arrastra la comida al comedero (${_portionsInBowl}/$_maxPortions)',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: ElevatedButton(
                onPressed: _portionsInBowl > 0 ? _finishGame : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey,
                  minimumSize: const Size(200, 40),
                ),
                child: const Text('¡Listo! Alimentar'),
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
        color: Colors.orange,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '¡A comer!',
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
