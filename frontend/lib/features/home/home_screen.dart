import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../pet_selection/pet_selection_screen.dart';
import '../nursery/nursery_screen.dart';
import '../../data/local/game_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    
    return Scaffold(
      backgroundColor: Colors.orange[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🐾',
              style: TextStyle(fontSize: 80),
            ),
            const SizedBox(height: 20),
            const Text(
              'MYPET',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Bienvenido a tu guardería',
              style: TextStyle(
                fontSize: 20,
                color: Colors.brown,
              ),
            ),
            const SizedBox(height: 60),
            gameState.player == null 
            ? const CircularProgressIndicator()
            : ElevatedButton(
              onPressed: () {
                if (gameState.player?.activePets.isNotEmpty == true) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const NurseryScreen(),
                    ),
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PetSelectionScreen(),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('JUGAR'),
            ),
          ],
        ),
      ),
    );
  }
}

