import 'pet.dart';

class Player {
  final String id;
  int coins;
  int nurseryLevel;
  int capacity;
  List<Pet> activePets;

  Player({
    required this.id,
    this.coins = 100,
    this.nurseryLevel = 1,
    this.capacity = 2,
    List<Pet>? activePets,
  }) : activePets = activePets ?? [];

  factory Player.fromJson(Map<String, dynamic> json) {
    var list = json['activePets'] as List? ?? [];
    List<Pet> petsList = list.map((i) => Pet.fromJson(i as Map<String, dynamic>)).toList();
    
    if (json['currentPet'] != null && petsList.isEmpty) {
      petsList.add(Pet.fromJson(json['currentPet'] as Map<String, dynamic>));
    }

    return Player(
      id: json['id'] as String,
      coins: json['coins'] as int? ?? 100,
      nurseryLevel: json['nurseryLevel'] as int? ?? 1,
      capacity: json['capacity'] as int? ?? 2,
      activePets: petsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coins': coins,
      'nurseryLevel': nurseryLevel,
      'capacity': capacity,
      'activePets': activePets.map((p) => p.toJson()).toList(),
    };
  }
}
