import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:provider/provider.dart';
import '../../game/mypet_game.dart';
import '../../data/local/game_state.dart';
import '../shop/shop_screen.dart';
import '../inventory/inventory_screen.dart';
import '../../game/models/pet.dart';
import '../../game/models/pet_stats.dart';

class NurseryScreen extends StatefulWidget {
  const NurseryScreen({super.key});

  @override
  State<NurseryScreen> createState() => _NurseryScreenState();
}

class _NurseryScreenState extends State<NurseryScreen> {
  late MyPetGame _game;

  @override
  void initState() {
    super.initState();
    final gameState = context.read<GameState>();
    _game = MyPetGame(gameState);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightGreen[100], // Fondo por si el juego no carga rápido
      body: SafeArea(
        child: Column(
          children: [
            // TOP BAR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white.withValues(alpha: 0.9),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '🐾 MYPET Guardería',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.store, color: Colors.orange, size: 28),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen())),
                      ),
                      IconButton(
                        icon: const Icon(Icons.backpack, color: Colors.blue, size: 28),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen())),
                      ),
                      Consumer<GameState>(
                        builder: (context, gameState, child) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.yellow[100],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.orange, width: 2),
                            ),
                            child: Row(
                              children: [
                                const Text('💰', style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 4),
                                Text(
                                  '${gameState.player?.coins ?? 0}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.brown,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // GAME WORLD
            Expanded(
              child: Stack(
                children: [
                  GameWidget(game: _game),
                  Consumer<GameState>(
                    builder: (context, gameState, child) {
                      if (gameState.player != null && gameState.player!.activePets.length < gameState.player!.capacity) {
                        return Positioned(
                          top: 16,
                          right: 16,
                          child: ElevatedButton.icon(
                            onPressed: () => _showReceptionDialog(context, gameState),
                            icon: const Icon(Icons.doorbell, size: 28),
                            label: const Text('Recepción', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[400],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              elevation: 5,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }
                  ),
                ],
              ),
            ),
            
            // BOTTOM HUD
            Consumer<GameState>(
              builder: (context, gameState, child) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))
                    ],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // PET STATS
                      if (gameState.selectedPet != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '${gameState.selectedPet!.name} 🐾',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 12,
                                runSpacing: 8,
                                children: [
                                  _buildStatBar('🍖 Hambre', gameState.selectedPet!.stats.hunger, Colors.orange),
                                  _buildStatBar('💧 Sed', gameState.selectedPet!.stats.thirst, Colors.blue),
                                  _buildStatBar('🧼 Higiene', gameState.selectedPet!.stats.hygiene, Colors.lightBlue),
                                  _buildStatBar('⚡ Energía', gameState.selectedPet!.stats.energy, Colors.yellow),
                                  _buildStatBar('❤️ Feliz', gameState.selectedPet!.stats.happiness, Colors.red),
                                ],
                              ),
                            ],
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Text('Selecciona una mascota en la guardería', style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        
                      // ACTIONS
                      if (gameState.selectedPet != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildActionButton(context, '🍖', 'Comer', () => gameState.feedPet()),
                                _buildActionButton(context, '💧', 'Beber', () => gameState.drinkPet()),
                                _buildActionButton(context, '🎾', 'Jugar', () => gameState.playWithPet()),
                                _buildActionButton(context, '🧼', 'Bañar', () => gameState.bathePet()),
                                _buildActionButton(context, '❤️', 'Mimos', () => gameState.petPet()),
                                _buildActionButton(context, '😴', 'Dormir', () => gameState.sleepPet()),
                                _buildActionButton(context, '🚶', 'Pasear', () => gameState.walkPet()),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBar(String label, double value, Color color) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown)),
              Text('${value.toInt()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: value / 100,
              color: color,
              backgroundColor: Colors.grey[300],
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String icon, String label, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(20),
            backgroundColor: Colors.white,
            foregroundColor: Colors.brown,
            elevation: 4,
          ),
          child: Text(icon, style: const TextStyle(fontSize: 24)),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.brown,
            shadows: [
              Shadow(
                color: Colors.white,
                blurRadius: 10,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showReceptionDialog(BuildContext context, GameState gameState) {
    final clients = ['Laura', 'Carlos', 'Ana', 'Mario', 'Lucía'];
    final speciesList = ['dog', 'cat', 'rabbit', 'hamster'];
    final requests = ['Quiere jugar mucho.', 'Necesita que le den de comer.', 'Viene un poco sucio, un baño le vendría bien.', 'Está muy cansado.'];
    
    clients.shuffle();
    speciesList.shuffle();
    requests.shuffle();

    final clientName = clients.first;
    final species = speciesList.first;
    final request = requests.first;
    final petName = species == 'dog' ? 'Toby' : species == 'cat' ? 'Luna' : species == 'rabbit' ? 'Coco' : 'Pepe';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.orange[50],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Text('🚪 ', style: TextStyle(fontSize: 24)),
              Text('Recepción - $clientName', style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('👩', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 10),
              Text('"Hola, soy $clientName. Te dejo a $petName durante un rato."', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange),
                ),
                child: Text('💬 Petición: $request', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Rechazar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                gameState.adoptPet(Pet(
                  name: petName,
                  species: species,
                  stats: PetStats(hunger: 50, energy: 50, happiness: 50, hygiene: 50, thirst: 50),
                ));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text('ACEPTAR MASCOTA'),
            ),
          ],
        );
      }
    );
  }
}

