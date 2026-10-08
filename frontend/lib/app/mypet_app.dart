import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/home/home_screen.dart';
import '../data/local/game_state.dart';
import '../data/repositories/local_game_repository.dart';
import '../data/repositories/remote_game_repository.dart';
import '../data/services/game_sync_service.dart';
import '../data/local/local_storage.dart';
import '../core/audio/audio_service.dart';

class MyPetApp extends StatelessWidget {
  const MyPetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final audio = AudioService();
          // Intentar iniciar la música de fondo al abrir (sujeto a autoplay policies en web)
          audio.playBgm();
          return audio;
        }),
        ChangeNotifierProvider(create: (_) {
          final localRepo = LocalGameRepository();
          final remoteRepo = RemoteGameRepository();
          final syncService = GameSyncService(localRepo: localRepo, remoteRepo: remoteRepo);
          final gameState = GameState(localRepo, syncService);
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

