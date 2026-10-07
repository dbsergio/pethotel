import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../game/models/pet.dart';
import '../../data/local/game_state.dart';
import '../nursery/nursery_screen.dart';

class PetSelectionScreen extends StatefulWidget {
  const PetSelectionScreen({super.key});

  @override
  State<PetSelectionScreen> createState() => _PetSelectionScreenState();
}

class _PetSelectionScreenState extends State<PetSelectionScreen> {
  String? selectedPet;

  final Map<String, String> pets = {
    'dog': '🐶 Perro',
    'cat': '🐱 Gato',
    'hamster': '🐹 Hámster',
    'rabbit': '🐰 Conejo',
  };

  void _onPetSelected(String petId) {
    setState(() {
      selectedPet = petId;
    });
  }

  void _onContinue() {
    if (selectedPet == null) return;
    
    // Ask for name
    showDialog(
      context: context,
      builder: (context) {
        String name = '';
        return AlertDialog(
          title: const Text('¿Cómo se llama la mascota de este cliente?'),
          content: TextField(
            onChanged: (value) => name = value,
            decoration: const InputDecoration(
              hintText: 'Nombre...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (name.trim().isNotEmpty) {
                  Navigator.pop(context);
                  _finishSelection(name.trim());
                }
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }
  
  void _finishSelection(String name) async {
    final pet = Pet(name: name, species: selectedPet!);
    final gameState = context.read<GameState>();
    
    await gameState.adoptPet(pet);
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name ha sido ingresado en la guardería')),
    );
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const NurseryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[50],
      appBar: AppBar(
        title: const Text('PRIMER CLIENTE'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(20),
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              children: pets.entries.map((entry) {
                final isSelected = selectedPet == entry.key;
                return GestureDetector(
                  onTap: () => _onPetSelected(entry.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.orange[200] : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.orange : Colors.grey[300]!,
                        width: 3,
                      ),
                      boxShadow: [
                        if (isSelected)
                          const BoxShadow(
                            color: Colors.orangeAccent,
                            blurRadius: 10,
                          )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        entry.value,
                        style: const TextStyle(fontSize: 24),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton(
              onPressed: selectedPet != null ? _onContinue : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('CONTINUAR'),
            ),
          ),
        ],
      ),
    );
  }
}

