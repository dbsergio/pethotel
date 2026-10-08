import 'dart:math' as math;

class PetStats {
  double hunger;
  double thirst;
  double hygiene;
  double energy;
  double happiness;

  PetStats({
    this.hunger = 100.0,
    this.thirst = 100.0,
    this.hygiene = 100.0,
    this.energy = 100.0,
    this.happiness = 100.0,
  });

  factory PetStats.fromJson(Map<String, dynamic> json) {
    return PetStats(
      hunger: (json['hunger'] as num? ?? 100.0).toDouble(),
      thirst: (json['thirst'] as num? ?? 100.0).toDouble(),
      hygiene: (json['hygiene'] as num? ?? 100.0).toDouble(),
      energy: (json['energy'] as num? ?? 100.0).toDouble(),
      happiness: (json['happiness'] as num? ?? 100.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hunger': hunger,
      'thirst': thirst,
      'hygiene': hygiene,
      'energy': energy,
      'happiness': happiness,
    };
  }
  
  void clamp() {
    hunger = hunger.clamp(0.0, 100.0);
    thirst = thirst.clamp(0.0, 100.0);
    hygiene = hygiene.clamp(0.0, 100.0);
    energy = energy.clamp(0.0, 100.0);
    happiness = happiness.clamp(0.0, 100.0);
  }

  factory PetStats.random({
    required String species,
    required String personality,
    math.Random? random,
  }) {
    final r = random ?? math.Random();
    
    // Rango base: 35 - 75
    double baseHunger = 35.0 + r.nextInt(41);
    double baseThirst = 35.0 + r.nextInt(41);
    double baseHygiene = 35.0 + r.nextInt(41);
    double baseEnergy = 35.0 + r.nextInt(41);
    double baseHappiness = 35.0 + r.nextInt(41);

    // Especie modifiers
    switch (species) {
      case 'dog':
        baseHappiness += 10;
        baseEnergy += 10;
        break;
      case 'cat':
        baseEnergy -= 5;
        baseHygiene += 10;
        break;
      case 'hamster':
        baseEnergy += 15;
        baseHunger += 10;
        break;
      case 'rabbit':
        baseHappiness += 5;
        baseEnergy += 5;
        break;
    }

    // Personality modifiers
    switch (personality.toLowerCase()) {
      case 'juguetón':
        baseEnergy -= 10; // gastó energía jugando
        baseHappiness += 10;
        break;
      case 'tímido':
        baseHappiness -= 10; // más miedoso
        break;
      case 'curioso':
        baseEnergy -= 5;
        baseHunger += 5;
        break;
      case 'tranquilo':
      case 'dormilón':
        baseEnergy += 15;
        break;
      case 'travieso':
        baseHygiene -= 15; // se ensucia más
        baseHappiness += 5;
        break;
    }

    final stats = PetStats(
      hunger: baseHunger,
      thirst: baseThirst,
      hygiene: baseHygiene,
      energy: baseEnergy,
      happiness: baseHappiness,
    );
    stats.clamp();
    return stats;
  }
}
