import 'pet_stats.dart';
import 'package:uuid/uuid.dart';

enum PetAction { 
  idle, walking, eating, drinking, playing, bathing, sleeping, petting, happy, walking_in, walking_out,
  going_to_eat, going_to_drink, going_to_play, going_to_bath, going_to_sleep, going_to_walk 
}

class Pet {
  final String id;
  String name;
  String species;
  PetStats stats;
  
  // Transient state for animations, not serialized
  PetAction currentAction = PetAction.idle;
  String? currentActionMessage;
  String? currentActionId;

  Pet({
    String? id,
    required this.name,
    required this.species,
    PetStats? stats,
  })  : id = id ?? const Uuid().v4(),
        stats = stats ?? PetStats();

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'] as String,
      name: json['name'] as String,
      species: json['species'] as String,
      stats: PetStats.fromJson(json['stats'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'stats': stats.toJson(),
    };
  }
}
