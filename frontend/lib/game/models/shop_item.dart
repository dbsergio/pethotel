enum ItemType { consumable, permanent, cosmetic }
enum EffectType { none, hunger, hygiene, happiness, energy, thirst }

class ShopItem {
  final String id;
  final String name;
  final ItemType type;
  final int price;
  final int effectValue;
  final EffectType effectType;

  const ShopItem({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    this.effectValue = 0,
    this.effectType = EffectType.none,
  });
}

class StoreCatalog {
  static const Map<String, ShopItem> items = {
    'food_basic': ShopItem(
      id: 'food_basic',
      name: 'Comida Básica',
      type: ItemType.consumable,
      price: 15,
      effectValue: 100, // Recupera el hambre a 100
      effectType: EffectType.hunger,
    ),
    'water_basic': ShopItem(
      id: 'water_basic',
      name: 'Agua Fresca',
      type: ItemType.consumable,
      price: 5,
      effectValue: 100,
      effectType: EffectType.thirst,
    ),
    'soap_basic': ShopItem(
      id: 'soap_basic',
      name: 'Jabón Rápido',
      type: ItemType.consumable,
      price: 10,
      effectValue: 100, // Recupera la higiene a 100
      effectType: EffectType.hygiene,
    ),
    'upgrade_capacity_1': ShopItem(
      id: 'upgrade_capacity_1',
      name: 'Ampliación de Guardería (Nivel 2)',
      type: ItemType.permanent,
      price: 500,
    ),
    'upgrade_capacity_2': ShopItem(
      id: 'upgrade_capacity_2',
      name: 'Ampliación de Guardería (Nivel 3)',
      type: ItemType.permanent,
      price: 1200,
    ),
  };
}
