import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/local/game_state.dart';
import '../../game/models/shop_item.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0), // Cream background
      appBar: AppBar(
        title: const Text('Inventario', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 24, letterSpacing: 1.5)),
        backgroundColor: const Color(0xFF8D6E63), // Wood color
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
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
                  const Text(
                    'Tu inventario está vacío.',
                    style: TextStyle(fontSize: 18, color: Color(0xFF5D4037), fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Visita la tienda para comprar provisiones.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF8D6E63), fontWeight: FontWeight.w500),
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

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD7CCC8), width: 3),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFEBE9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFD7CCC8), width: 2),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _getIconFor(shopItem),
                            style: const TextStyle(fontSize: 32),
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
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF5D4037),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF8E1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFFFCA28)),
                              ),
                              child: Text(
                                'Cantidad: $quantity',
                                style: const TextStyle(color: Color(0xFFF57F17), fontWeight: FontWeight.w900, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          final pet = gameState.selectedPet;
                          if (pet == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Text('ℹ️ ', style: TextStyle(fontSize: 18)),
                                    Expanded(child: Text('Selecciona una mascota en la guardería primero.', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFE082)))),
                                  ],
                                ),
                                duration: const Duration(seconds: 2),
                                backgroundColor: const Color(0xFF5D4037),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF3E2723), width: 2)),
                              ),
                            );
                            return;
                          }
                          
                          // Consumir
                          final success = await gameState.consumeItem(shopItem.id, pet.id);
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Text('✨ ', style: TextStyle(fontSize: 18)),
                                    Expanded(child: Text('¡${shopItem.name} usado en ${pet.name}!', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                  ],
                                ),
                                duration: const Duration(seconds: 1),
                                backgroundColor: const Color(0xFF66BB6A),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8D6E63),
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: const Text('Usar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
