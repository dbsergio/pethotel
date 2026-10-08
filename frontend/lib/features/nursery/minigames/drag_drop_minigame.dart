import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../game/models/pet.dart';
import '../../../game/minigames/minigame_result.dart';
import '../../../data/local/game_state.dart';

class DragDropMinigame extends StatefulWidget {
  final Pet pet;
  final String title;
  final String inventoryItemId;
  final String dragIcon;
  final String targetIcon;
  final String targetLabelEmpty;
  final Color themeColor;
  final double hungerChange;
  final double thirstChange;
  final double happinessChange;
  final String instructionText;

  const DragDropMinigame({
    super.key,
    required this.pet,
    required this.title,
    required this.inventoryItemId,
    required this.dragIcon,
    required this.targetIcon,
    required this.targetLabelEmpty,
    required this.themeColor,
    this.hungerChange = 0,
    this.thirstChange = 0,
    this.happinessChange = 0,
    required this.instructionText,
  });

  @override
  State<DragDropMinigame> createState() => _DragDropMinigameState();
}

class _DragDropMinigameState extends State<DragDropMinigame> {
  int _portionsInBowl = 0;
  int _maxPortions = 0;
  bool _isFinished = false; // Prevent double trigger

  @override
  void initState() {
    super.initState();
    final gs = context.read<GameState>();
    _maxPortions = gs.getInventoryQuantity(widget.inventoryItemId);
  }

  void _onDropped() {
    if (_portionsInBowl < _maxPortions) {
      setState(() {
        _portionsInBowl++;
      });
    }
  }

  void _finishGame() {
    if (_isFinished) return;
    _isFinished = true;

    final result = CareMinigameResult(
      success: _portionsInBowl > 0,
      quality: _maxPortions > 0 ? _portionsInBowl / _maxPortions : 0,
      statChanges: {
        if (widget.hungerChange > 0) 'hunger': _portionsInBowl * widget.hungerChange,
        if (widget.thirstChange > 0) 'thirst': _portionsInBowl * widget.thirstChange,
        if (widget.happinessChange > 0) 'happiness': _portionsInBowl * widget.happinessChange,
      },
      consumedItems: {
        widget.inventoryItemId: _portionsInBowl,
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
    if (_maxPortions == 0) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: widget.themeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: widget.themeColor, width: 4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('😢', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 16),
              const Text(
                'No tienes suficientes provisiones',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Visita la tienda para comprar más.',
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
          color: widget.themeColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: widget.themeColor, width: 4),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Ampliamos significativamente la hitbox del DragTarget para móviles
                  Positioned(
                    bottom: 0,
                    child: DragTarget<String>(
                      builder: (context, candidateData, rejectedData) {
                        final isActive = candidateData.isNotEmpty;
                        return Container(
                          width: 250, // Gran hitbox
                          height: 180, // Gran hitbox
                          color: Colors.transparent,
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: 140, // Objetivo visual
                            height: 90,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green[300] : Colors.grey[300],
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(45),
                              ),
                              border: Border.all(
                                color: isActive ? Colors.green[800]! : Colors.grey[500]!,
                                width: isActive ? 4 : 3,
                              ),
                              boxShadow: isActive
                                  ? [BoxShadow(color: Colors.green.withValues(alpha: 0.5), blurRadius: 15, spreadRadius: 5)]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                _portionsInBowl == 0
                                    ? widget.targetLabelEmpty
                                    : '${widget.targetIcon} x $_portionsInBowl',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ),
                          ),
                        );
                      },
                      onWillAcceptWithDetails: (details) => true,
                      onAcceptWithDetails: (details) {
                        _onDropped();
                      },
                    ),
                  ),
                  
                  // Pet waiting
                  Positioned(
                    top: 20,
                    right: 40,
                    child: Column(
                      children: [
                        const Text('🐶', style: TextStyle(fontSize: 60)),
                        Text(widget.pet.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),

                  // Object to drag
                  if (_portionsInBowl < _maxPortions)
                    Positioned(
                      top: 100,
                      left: 40,
                      child: Draggable<String>(
                        data: 'item',
                        feedback: Text(widget.dragIcon, style: const TextStyle(fontSize: 50, decoration: TextDecoration.none)),
                        childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: Text(widget.dragIcon, style: const TextStyle(fontSize: 50)),
                        ),
                        child: Text(widget.dragIcon, style: const TextStyle(fontSize: 50)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                '${widget.instructionText} (${_portionsInBowl}/$_maxPortions)',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: ElevatedButton(
                onPressed: (_portionsInBowl > 0 && !_isFinished) ? _finishGame : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey,
                  minimumSize: const Size(200, 40),
                ),
                child: const Text('¡Listo!'),
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
      decoration: BoxDecoration(
        color: widget.themeColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.title,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
