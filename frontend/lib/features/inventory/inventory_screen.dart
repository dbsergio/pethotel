import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/local/game_state.dart';
import '../../game/models/shop_item.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        backgroundColor: Colors.blue.shade400,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.blue.shade50,
      body: Consumer<GameState>(
        builder: (context, gameState, child) {
          final inventory = gameState.player?.inventory ?? {};
          // Only show consumables (permanents are hidden from visual inventory)
          final items = inventory.entries.where((entry) {
            final shopItem = StoreCatalog.items[entry.key];
            return shopItem != null && shopItem.type == ItemType.consumable && entry.value > 0;
          }).toList();

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎒', style: TextStyle(fontSize: 60)),
                  const SizedBox(height: 16),
                  Text(
                    'Tu inventario está vacío.',
                    style: TextStyle(fontSize: 18, color: Colors.blueGrey.shade400, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Visita la tienda para comprar provisiones.',
                    style: TextStyle(fontSize: 14, color: Colors.blueGrey.shade300),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final entry = items[index];
              final shopItem = StoreCatalog.items[entry.key]!;
              final quantity = entry.value;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _getIconFor(shopItem),
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shopItem.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Cantidad: $quantity',
                              style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          // Placeholder for Phase 3.4
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('El uso de objetos se implementará en el próximo paso.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Usar'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _getIconFor(ShopItem item) {
    if (item.id.contains('food')) return '🍖';
    if (item.id.contains('soap')) return '🧼';
    return '📦';
  }
}
