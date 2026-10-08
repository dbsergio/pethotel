import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/local/game_state.dart';

class CoinCounterWidget extends StatelessWidget {
  const CoinCounterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final coins = gameState.player?.coins ?? 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.yellow[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange.shade400, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('💰', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                '$coins',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.brown,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
