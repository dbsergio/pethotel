import 'package:flutter/material.dart';
import '../../../game/models/pet.dart';
import 'drag_drop_minigame.dart';

import 'package:provider/provider.dart';
import '../../../core/audio/audio_service.dart';

class DrinkMinigame extends StatelessWidget {
  final Pet pet;

  const DrinkMinigame({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return DragDropMinigame(
      pet: pet,
      title: '¡A beber!',
      inventoryItemId: 'water_basic',
      dragIcon: '💧',
      targetIcon: '💧',
      targetLabelEmpty: 'Bebedero vacío',
      themeColor: Colors.blue,
      thirstChange: 30.0,
      happinessChange: 2.0,
      instructionText: 'Arrastra el agua al bebedero',
      onDrop: () => context.read<AudioService>().playActionDrink(),
    );
  }
}
