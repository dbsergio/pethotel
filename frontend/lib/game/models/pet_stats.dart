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
}
