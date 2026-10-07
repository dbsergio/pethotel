import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mypet_frontend/data/local/local_storage.dart';
import 'package:mypet_frontend/data/repositories/local_game_repository.dart';
import 'package:mypet_frontend/game/models/player.dart';

void main() {
  test('Migración desde partida antigua sin saveVersion', () async {
    // 1. Simular JSON antiguo en SharedPreferences
    final oldJson = {
      "id": "player-123",
      // NOTA: sin saveVersion ni revision
      "coins": 450,
      "nurseryLevel": 1,
      "capacity": 3,
      "activePets": [
        {
          "id": "pet-1",
          "name": "Toby",
          "species": "dog",
          "stats": {
            "hunger": 50,
            "thirst": 50,
            "hygiene": 50,
            "energy": 50,
            "happiness": 50
          },
          "currentAction": "idle"
        }
      ],
      "activeStays": [],
      "completedStays": []
    };

    SharedPreferences.setMockInitialValues({
      'player_data_player-123': jsonEncode(oldJson),
      'playerId': 'player-123',
    });
    
    // Inicializar LocalStorage para que use las mock prefs
    await LocalStorage.init();

    // 2. Cargar usando el repositorio
    final repo = LocalGameRepository();
    final player = await repo.loadPlayer('player-123');

    // 3. Verificar que se cargó y los valores por defecto se aplicaron (saveVersion=1, revision=1)
    expect(player, isNotNull);
    expect(player!.id, 'player-123');
    expect(player.coins, 450);
    expect(player.capacity, 3);
    expect(player.activePets.length, 1);
    expect(player.activePets.first.name, 'Toby');
    expect(player.saveVersion, 1);
    expect(player.revision, 1);
  });
}
