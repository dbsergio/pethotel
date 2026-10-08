import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mypet_frontend/features/nursery/minigames/eat_minigame.dart';
import 'package:mypet_frontend/data/local/game_state.dart';
import 'package:mypet_frontend/data/services/game_sync_service.dart';
import 'package:mypet_frontend/data/repositories/local_game_repository.dart';
import 'package:mypet_frontend/data/repositories/remote_game_repository.dart';
import 'package:mypet_frontend/game/models/player.dart';
import 'package:mypet_frontend/game/models/pet.dart';
import 'package:mypet_frontend/game/minigames/minigame_result.dart';

class MockGameSyncService extends GameSyncService {
  MockGameSyncService() : super(localRepo: LocalGameRepository(), remoteRepo: RemoteGameRepository());
  @override
  void markPending() {}
  @override
  Future<void> syncNow() async {}
}

void main() {
  Widget createWidgetUnderTest(GameState gameState, Pet pet) {
    return MaterialApp(
      home: ChangeNotifierProvider<GameState>.value(
        value: gameState,
        child: Scaffold(
          body: EatMinigame(pet: pet),
        ),
      ),
    );
  }

  group('EatMinigame dynamic consumption limits', () {
    late GameState gameState;
    late Pet testPet;

    setUp(() async {
      final localRepo = LocalGameRepository();
      final syncService = MockGameSyncService();
      gameState = GameState(localRepo, syncService);
      
      testPet = Pet(id: 'pet_1', name: 'Toby', species: 'dog');
      gameState.player = Player(
        id: 'user123',
        coins: 100,
        activePets: [testPet],
        inventory: {},
      );
    });

    testWidgets('Inventario con 1 unidad permite elegir 1', (WidgetTester tester) async {
      await gameState.addInventoryItem('food_basic', 1);
      
      await tester.pumpWidget(createWidgetUnderTest(gameState, testPet));
      await tester.pumpAndSettle();
      
      expect(find.text('Arrastra la comida al comedero (0/1)'), findsOneWidget);
      expect(find.byType(Draggable<String>), findsOneWidget);
      
      // Mover comida al DragTarget
      final draggable = find.byType(Draggable<String>).first;
      final target = find.byType(DragTarget<String>).first;
      
      await tester.drag(draggable, tester.getCenter(target) - tester.getCenter(draggable));
      await tester.pumpAndSettle();
      
      expect(find.text('Arrastra la comida al comedero (1/1)'), findsOneWidget);
      
      // Presionar terminar
      expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed, isNotNull);
    });

    testWidgets('Inventario con 3 unidades permite elegir hasta 3', (WidgetTester tester) async {
      await gameState.addInventoryItem('food_basic', 3);
      
      await tester.pumpWidget(createWidgetUnderTest(gameState, testPet));
      await tester.pumpAndSettle();
      
      expect(find.text('Arrastra la comida al comedero (0/3)'), findsOneWidget);
      
      final draggable = find.byType(Draggable<String>).first;
      final target = find.byType(DragTarget<String>).first;
      
      // Drag 1
      await tester.drag(draggable, tester.getCenter(target) - tester.getCenter(draggable));
      await tester.pumpAndSettle();
      expect(find.text('Arrastra la comida al comedero (1/3)'), findsOneWidget);
      
      // Drag 2
      await tester.drag(draggable, tester.getCenter(target) - tester.getCenter(draggable));
      await tester.pumpAndSettle();
      expect(find.text('Arrastra la comida al comedero (2/3)'), findsOneWidget);
      
      // Drag 3
      await tester.drag(draggable, tester.getCenter(target) - tester.getCenter(draggable));
      await tester.pumpAndSettle();
      expect(find.text('Arrastra la comida al comedero (3/3)'), findsOneWidget);
    });

    testWidgets('Inventario con >3 unidades permite elegir el maximo real (ej 5)', (WidgetTester tester) async {
      await gameState.addInventoryItem('food_basic', 5);
      
      await tester.pumpWidget(createWidgetUnderTest(gameState, testPet));
      await tester.pumpAndSettle();
      
      expect(find.text('Arrastra la comida al comedero (0/5)'), findsOneWidget);
      
      final draggable = find.byType(Draggable<String>).first;
      final target = find.byType(DragTarget<String>).first;
      
      for (int i = 1; i <= 5; i++) {
        await tester.drag(draggable, tester.getCenter(target) - tester.getCenter(draggable));
        await tester.pumpAndSettle();
        expect(find.text('Arrastra la comida al comedero ($i/5)'), findsOneWidget);
      }
    });
  });
}
