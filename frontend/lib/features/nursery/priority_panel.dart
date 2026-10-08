import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/local/game_state.dart';
import '../../../game/models/pet.dart';

class PriorityPanel extends StatelessWidget {
  final bool isDesktop;

  const PriorityPanel({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final recommendation = _getRecommendation(gameState);
        if (recommendation == null) return const SizedBox.shrink();

        return Container(
          margin: EdgeInsets.only(
            top: isDesktop ? 80 : 70,
            right: 12,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1).withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFB300), width: 2),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(recommendation.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sugerencia',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),
                  Text(
                    recommendation.message,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  _Recommendation? _getRecommendation(GameState gs) {
    if (gs.player == null) return null;

    // 1. Ready to checkout
    for (final stay in gs.player!.activeStays) {
      if (stay.isReady) {
        final pet = gs.player!.activePets.cast<Pet?>().firstWhere(
          (p) => p?.id == stay.petId,
          orElse: () => null,
        );
        final name = pet?.name ?? 'Una mascota';
        return _Recommendation('💰', 'La estancia de $name ha terminado. ¡Cóbrala!');
      }
    }

    // 2. Urgent needs (thirst < 20, hunger < 20)
    for (final pet in gs.player!.activePets) {
      if (pet.stats.thirst < 20) {
        if (gs.getInventoryQuantity('water_bowl') <= 0) {
          return _Recommendation('💧', '${pet.name} tiene mucha sed. ¡Compra agua en la Tienda!');
        }
        return _Recommendation('💧', '${pet.name} tiene mucha sed. ¡Dale de beber!');
      }
      if (pet.stats.hunger < 20) {
        if (gs.getInventoryQuantity('premium_food') <= 0) {
          return _Recommendation('🍖', '${pet.name} tiene mucha hambre. ¡Compra comida!');
        }
        return _Recommendation('🍖', '${pet.name} tiene mucha hambre. ¡Dale de comer!');
      }
    }

    // 3. Needs bath
    for (final pet in gs.player!.activePets) {
      if (pet.stats.hygiene < 30) {
        if (gs.getInventoryQuantity('shampoo') <= 0) {
          return _Recommendation('🛁', '${pet.name} necesita un baño. ¡Compra champú!');
        }
        return _Recommendation('🛁', '${pet.name} necesita un baño.');
      }
    }

    // 4. Needs play
    for (final pet in gs.player!.activePets) {
      if (pet.stats.happiness < 30) {
        return _Recommendation('🎾', '${pet.name} está triste. ¡Juega con él!');
      }
    }

    // 5. Incoming customer
    if (gs.player!.activePets.length < gs.player!.capacity && gs.player!.activePets.isEmpty) {
       return _Recommendation('👋', 'Toca a los clientes para aceptar mascotas.');
    }

    return null;
  }
}

class _Recommendation {
  final String icon;
  final String message;
  _Recommendation(this.icon, this.message);
}
