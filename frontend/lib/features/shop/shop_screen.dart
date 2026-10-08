import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/local/game_state.dart';
import '../../game/models/shop_item.dart';
import '../economy/widgets/coin_counter_widget.dart';
import '../../core/audio/audio_service.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF3E0), // Cream background
        appBar: AppBar(
          title: const Text('Tienda', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 24, letterSpacing: 1.5)),
          backgroundColor: const Color(0xFF8D6E63), // Wood color
          elevation: 4,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: const [
            Center(child: CoinCounterWidget()),
            SizedBox(width: 16),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('🍔', style: TextStyle(fontSize: 18)), SizedBox(width: 8), Text('Consumibles', style: TextStyle(fontWeight: FontWeight.bold))])),
              Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('🏗️', style: TextStyle(fontSize: 18)), SizedBox(width: 8), Text('Mejoras', style: TextStyle(fontWeight: FontWeight.bold))])),
            ],
            indicatorColor: Color(0xFFFFD54F),
            indicatorWeight: 4,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: const TabBarView(
          children: [
            _ShopCategoryView(category: ItemType.consumable),
            _ShopCategoryView(category: ItemType.permanent),
          ],
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
                    color: const Color(0xFFFFE082),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFCA28), width: 2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _getIconFor(item),
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
                        item.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF5D4037),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getDescriptionFor(item),
                        style: const TextStyle(color: Color(0xFF8D6E63), fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      if (item.type == ItemType.consumable) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFEBE9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('En inventario: $qty', style: const TextStyle(color: Color(0xFF5D4037), fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ]
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: hasCoins ? const Color(0xFFFFF8E1) : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: hasCoins ? const Color(0xFFFFCA28) : Colors.red.shade300),
                      ),
                      child: Row(
                        children: [
                          const Text('💰', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            '${item.price}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: hasCoins ? const Color(0xFFF57F17) : Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: (alreadyOwned || !hasCoins)
                          ? () {
                              context.read<AudioService>().playUiError();
                            }
                          : () async {
                              final success = await gameState.buyItem(item.id);
                              if (success && context.mounted) {
                                context.read<AudioService>().playShopPurchase();
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
                        backgroundColor: const Color(0xFF66BB6A),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: Text(alreadyOwned ? 'Adquirido' : 'Comprar', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
