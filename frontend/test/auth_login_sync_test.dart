import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mypet_frontend/data/local/local_storage.dart';
import 'package:mypet_frontend/data/repositories/local_game_repository.dart';
import 'package:mypet_frontend/data/repositories/remote_game_repository.dart';
import 'package:mypet_frontend/data/services/game_sync_service.dart';
import 'package:mypet_frontend/game/models/player.dart';
import 'package:mypet_frontend/game/models/pet.dart';
import 'package:mypet_frontend/data/local/game_state.dart';

class MockRemoteRepoWithData extends RemoteGameRepository {
  @override
  Future<Player?> loadRemotePlayer(String playerId) async {
    // Simulamos que el servidor devuelve un Player con revision = 3 y mascota "szh"
    return Player(
      id: playerId,
      revision: 3,
      coins: 100,
      activePets: [Pet(id: 'szh', name: 'Szh', species: 'dog')],
    );
  }
}

class MockRemoteRepoWithLatency extends RemoteGameRepository {
  @override
  Future<Player?> loadRemotePlayer(String playerId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return Player(
      id: playerId,
      revision: 4,
      coins: 100,
      activePets: [Pet(id: 'szh', name: 'Szh', species: 'dog')],
    );
  }
}

void main() {
  test('login con conflicto de revision: local rev 2, server rev 3 -> termina con estado del servidor', () async {
    final playerId = 'user123';
    
    // 1. Configuramos el estado inicial de LocalStorage simulando que la app arranca
    // con un guardado antiguo de este usuario (revision 2, mascota "shbaa")
    final oldLocalPlayer = Player(
      id: playerId,
      revision: 2,
      coins: 50,
      activePets: [Pet(id: 'shbaa', name: 'Shbaa', species: 'cat')],
    );
    
    SharedPreferences.setMockInitialValues({
      'jwt_token': 'dummy_token',
      'playerId': playerId,
      'player_data_$playerId': jsonEncode(oldLocalPlayer.toJson()),
    });
    
    await LocalStorage.init();

    final localRepo = LocalGameRepository();
    final remoteRepo = MockRemoteRepoWithData();
    final syncService = GameSyncService(localRepo: localRepo, remoteRepo: remoteRepo);
    final gameState = GameState(localRepo, syncService);
    
    // 2. Simulamos el login (o la carga inicial de la app estando logueado)
    await gameState.loadPlayer(playerId);
    
    // 3. Verificamos que el estado final es el del servidor
    expect(gameState.player, isNotNull);
    expect(gameState.player!.revision, 3);
    expect(gameState.player!.activePets.first.id, 'szh');
    
    // 4. Verificamos que se actualizó el LocalStorage para la próxima vez
    final savedData = LocalStorage.prefs.getString('player_data_$playerId');
    expect(savedData, isNotNull);
    final savedJson = jsonDecode(savedData!);
    expect(savedJson['revision'], 3);
    expect(savedJson['activePets'][0]['id'], 'szh');
  });

  test('login con conflicto de revision: local rev 4, server rev 3 -> termina con estado local y fuerza sync', () async {
    final playerId = 'user123';
    
    final oldLocalPlayer = Player(
      id: playerId,
      revision: 4,
      coins: 50,
      activePets: [Pet(id: 'shbaa', name: 'Shbaa', species: 'cat')],
    );
    
    SharedPreferences.setMockInitialValues({
      'jwt_token': 'dummy_token',
      'playerId': playerId,
      'player_data_$playerId': jsonEncode(oldLocalPlayer.toJson()),
    });
    
    await LocalStorage.init();

    final localRepo = LocalGameRepository();
    final remoteRepo = MockRemoteRepoWithData();
    final syncService = GameSyncService(localRepo: localRepo, remoteRepo: remoteRepo);
    final gameState = GameState(localRepo, syncService);
    
    await gameState.loadPlayer(playerId);
    
    // Verifica que el estado final ES EL LOCAL
    expect(gameState.player, isNotNull);
    expect(gameState.player!.revision, 4);
    expect(gameState.player!.activePets.first.id, 'shbaa');
    
    // Verifica que se forzó la sincronización al servidor
    expect(syncService.status, SyncStatus.pending);
  });
  test('carga remota en segundo plano no sobrescribe modificación local concurrente', () async {
    final playerId = 'user123';
    
    final oldLocalPlayer = Player(
      id: playerId,
      revision: 2,
      coins: 50,
      activePets: [Pet(id: 'shbaa', name: 'Shbaa', species: 'cat')],
    );
    
    SharedPreferences.setMockInitialValues({
      'jwt_token': 'dummy_token',
      'playerId': playerId,
      'player_data_$playerId': jsonEncode(oldLocalPlayer.toJson()),
    });
    
    await LocalStorage.init();

    final localRepo = LocalGameRepository();
    final remoteRepo = MockRemoteRepoWithLatency();
    final syncService = GameSyncService(localRepo: localRepo, remoteRepo: remoteRepo);
    final gameState = GameState(localRepo, syncService);
    
    // Iniciar la carga
    final loadFuture = gameState.loadPlayer(playerId);
    
    // Antes de que termine la carga, el usuario hace una acción local (por ejemplo, ganar monedas)
    // Esto incrementa la revisión local a 3 (o más).
    // Esperamos un poquito para que loadPlayer haya cargado el local pero no el remoto
    await Future.delayed(const Duration(milliseconds: 20));
    gameState.player!.coins += 10;
    await gameState.save(); // esto incrementa la revisión local a 3
    
    // Esperamos a que la carga remota termine
    await loadFuture;
    
    // El remotePlayer que llega tiene revision 3. El localPlayer acaba de alcanzar la revision 3.
    // Como el local fue modificado (revision != initialRevision), NO debe ser sobrescrito
    // por la versión remota, sino que debe preservarse la local.
    expect(gameState.player!.coins, 60);
    expect(gameState.player!.activePets.first.id, 'shbaa');
    expect(syncService.status, SyncStatus.pending);
  });
}
