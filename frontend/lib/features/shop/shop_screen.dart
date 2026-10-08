import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/local/game_state.dart';
import '../../game/models/shop_item.dart';
import '../economy/widgets/coin_counter_widget.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tienda'),
          backgroundColor: Colors.orange.shade400,
          actions: const [
            Center(child: CoinCounterWidget()),
            SizedBox(width: 16),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Consumibles', icon: Icon(Icons.fastfood)),
              Tab(text: 'Mejoras', icon: Icon(Icons.upgrade)),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: Container(
          color: Colors.orange.shade50,
          child: const TabBarView(
            children: [
              _ShopCategoryView(category: ItemType.consumable),
              _ShopCategoryView(category: ItemType.permanent),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopCategoryView extends StatelessWidget {
  final ItemType category;
  const _ShopCategoryView({required this.category});

  @override
  Widget build(BuildContext context) {
    final items = StoreCatalog.items.values.where((item) => item.type == category).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _ShopItemCard(item: item);
      },
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  final ShopItem item;
  const _ShopItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final hasCoins = gameState.hasCoins(item.price);
        final alreadyOwned = item.type == ItemType.permanent && gameState.hasInventoryItem(item.id, 1);
        final qty = gameState.getInventoryQuantity(item.id);

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
                    color: Colors.orange.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _getIconFor(item),
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
                        item.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getDescriptionFor(item),
                        style: TextStyle(color: Colors.brown.shade400, fontSize: 13),
                      ),
                      if (item.type == ItemType.consumable) ...[
                        const SizedBox(height: 4),
                        Text('En inventario: $qty', style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 12)),
                      ]
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    Row(
                      children: [
                        const Text('💰', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(
                          '${item.price}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: hasCoins ? Colors.orange.shade800 : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: (alreadyOwned || !hasCoins)
                          ? null
                          : () async {
                              final success = await gameState.buyItem(item.id);
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Text('✅ ', style: TextStyle(fontSize: 18)),
                                        Expanded(child: Text('¡Compraste ${item.name}! -${item.price} 💰', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFFFE082)))),
                                      ],
                                    ),
                                    duration: const Duration(seconds: 2),
                                    backgroundColor: const Color(0xFF5D4037),
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.all(16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: const BorderSide(color: Color(0xFF3E2723), width: 2),
                                    ),
                                    elevation: 6,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: Text(alreadyOwned ? 'Adquirido' : 'Comprar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getIconFor(ShopItem item) {
    if (item.id.contains('food')) return '🍖';
    if (item.id.contains('soap')) return '🧼';
    if (item.id.contains('upgrade')) return '🏗️';
    return '📦';
  }

  String _getDescriptionFor(ShopItem item) {
    if (item.effectValue > 0) {
      String statName = '';
      switch (item.effectType) {
        case EffectType.hunger: statName = 'Hambre'; break;
        case EffectType.hygiene: statName = 'Higiene'; break;
        case EffectType.happiness: statName = 'Felicidad'; break;
        case EffectType.energy: statName = 'Energía'; break;
        case EffectType.thirst: statName = 'Sed'; break;
        default: break;
      }
      return 'Recupera $statName';
    }
    if (item.type == ItemType.permanent) {
      return 'Mejora permanente para la guardería';
    }
    return '';
  }
}
