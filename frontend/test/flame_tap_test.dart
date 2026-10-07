import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:mypet_frontend/data/local/game_state.dart';
import 'package:mypet_frontend/data/repositories/game_repository.dart';
import 'package:mypet_frontend/game/models/player.dart';
import 'package:mypet_frontend/game/models/pet.dart';
import 'package:mypet_frontend/game/models/pet_stats.dart';
import 'package:mypet_frontend/game/mypet_game.dart';

class MockGameRepository implements GameRepository {
  @override
  Future<Player?> loadPlayer(String playerId) async => null;
  @override
  Future<void> savePlayer(Player player) async {}
  @override
  Future<void> syncPending() async {}
}

void main() {
  testWidgets('Flame PetGraphicComponent Tap Test', (WidgetTester tester) async {
    final gameState = GameState(MockGameRepository());
    
    final toby = Pet(id: 'toby_1', name: 'Toby', species: 'dog', stats: PetStats());
    final luna = Pet(id: 'luna_2', name: 'Luna', species: 'cat', stats: PetStats());
    
    gameState.player = Player(id: 'player_1')..activePets.addAll([toby, luna]);

    final game = MyPetGame(gameState);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameWidget(game: game),
        ),
      ),
    );
    await tester.pump();

    // Verify initial state
    expect(gameState.selectedPetId, isNull);

    // Wait for Flame to load components
    await tester.pump(const Duration(seconds: 1));

    // Calculate Toby's position. 
    // In _syncPets, Toby (index 0) is at startX.
    // game.size is set by layout.
    final rect = tester.getRect(find.byType(GameWidget<MyPetGame>));
    final gameSize = game.size;
    final spacing = 160.0;
    final totalW = (2 - 1) * spacing;
    final startX = gameSize.x / 2 - totalW / 2;
    
    final tobyPos = rect.topLeft + Offset(startX, gameSize.y * 0.55);
    
    await tester.tapAt(tobyPos);
    await tester.pump();
    
    // Check if the state was updated via TapCallbacks
    expect(gameState.selectedPetId, toby.id);

    // Now tap Luna
    final lunaPos = rect.topLeft + Offset(startX + spacing, gameSize.y * 0.55);
    
    await tester.tapAt(lunaPos);
    await tester.pump();

    // Check if Luna is selected
    expect(gameState.selectedPetId, luna.id);
  });
}
