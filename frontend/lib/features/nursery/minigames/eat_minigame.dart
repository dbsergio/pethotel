import 'package:flutter/material.dart';
import '../../../game/models/pet.dart';
import 'drag_drop_minigame.dart';

import 'package:provider/provider.dart';
import '../../../core/audio/audio_service.dart';

class EatMinigame extends StatelessWidget {
  final Pet pet;

  const EatMinigame({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return DragDropMinigame(
      pet: pet,
      title: '¡A comer!',
      inventoryItemId: 'food_basic',
      dragIcon: '🍖',
      targetIcon: '🍖',
      targetLabelEmpty: 'Bowl vacío',
      themeColor: Colors.orange,
      hungerChange: 12.0,
      happinessChange: 2.0,
      instructionText: 'Arrastra la comida al comedero',
      onDrop: () => context.read<AudioService>().playActionEat(),
    );
  }
}
