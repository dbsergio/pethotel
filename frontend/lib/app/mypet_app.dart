import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/home/home_screen.dart';
import '../data/local/game_state.dart';
import '../data/repositories/local_game_repository.dart';
import '../data/local/local_storage.dart';

class MyPetApp extends StatelessWidget {
  const MyPetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final gameState = GameState(LocalGameRepository());
          final playerId = LocalStorage.getPlayerId();
          gameState.loadPlayer(playerId);
          return gameState;
        }),
      ],
      child: MaterialApp(
        title: 'MyPet',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.orange,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Inter',
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

