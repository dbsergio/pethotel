import 'pet.dart';
import 'boarding_stay.dart';

class Player {
  final String id;
  int saveVersion;
  int revision;
  int coins;
  int nurseryLevel;
  int capacity;
  List<Pet> activePets;
  List<BoardingStay> activeStays;
  List<BoardingStay> completedStays;

  Player({
    required this.id,
    this.saveVersion = 1,
    this.revision = 1,
    this.coins = 100,
    this.nurseryLevel = 1,
    this.capacity = 4,
    List<Pet>? activePets,
    List<BoardingStay>? activeStays,
    List<BoardingStay>? completedStays,
  })  : activePets = activePets ?? [],
        activeStays = activeStays ?? [],
        completedStays = completedStays ?? [];

  factory Player.fromJson(Map<String, dynamic> json) {
    var list = json['activePets'] as List? ?? [];
    List<Pet> petsList = list.map((i) => Pet.fromJson(i as Map<String, dynamic>)).toList();
    
    if (json['currentPet'] != null && petsList.isEmpty) {
      petsList.add(Pet.fromJson(json['currentPet'] as Map<String, dynamic>));
    }

    var activeStaysList = (json['activeStays'] as List? ?? [])
        .map((i) => BoardingStay.fromJson(i as Map<String, dynamic>))
        .toList();
    var completedStaysList = (json['completedStays'] as List? ?? [])
        .map((i) => BoardingStay.fromJson(i as Map<String, dynamic>))
        .toList();

    return Player(
      id: json['id'] as String,
      saveVersion: json['saveVersion'] as int? ?? 1,
      revision: json['revision'] as int? ?? 1,
      coins: json['coins'] as int? ?? 100,
      nurseryLevel: json['nurseryLevel'] as int? ?? 1,
      capacity: json['capacity'] as int? ?? 4,
      activePets: petsList,
      activeStays: activeStaysList,
      completedStays: completedStaysList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'saveVersion': saveVersion,
      'revision': revision,
      'coins': coins,
      'nurseryLevel': nurseryLevel,
      'capacity': capacity,
      'activePets': activePets.map((p) => p.toJson()).toList(),
      'activeStays': activeStays.map((s) => s.toJson()).toList(),
      'completedStays': completedStays.map((s) => s.toJson()).toList(),
    };
  }
}
