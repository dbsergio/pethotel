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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF5D4037), Color(0xFF4E342E)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFD54F), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('💰', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: coins.toDouble(), end: coins.toDouble()),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFFE082),
                      letterSpacing: 1.1,
                      shadows: [Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 2)],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
