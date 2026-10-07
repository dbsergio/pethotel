import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:provider/provider.dart';
import '../../game/mypet_game.dart';
import '../../data/local/game_state.dart';
import '../shop/shop_screen.dart';
import '../inventory/inventory_screen.dart';
import '../../game/models/pet.dart';
import '../../game/models/pet_stats.dart';
import '../../game/models/customer.dart' as import_customer;
import '../../game/models/boarding_stay.dart';
import 'pet_info_panel.dart';
import '../../data/local/local_storage.dart' as import_local_storage;
import '../../data/services/game_sync_service.dart' as import_game_sync;
import '../auth/auth_dialog.dart';
import '../../data/repositories/auth_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Breakpoints
// ─────────────────────────────────────────────────────────────────────────────
const double kTabletBreakpoint  = 600;
const double kDesktopBreakpoint = 900;

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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= kDesktopBreakpoint;

    return Scaffold(
      backgroundColor: Colors.lightGreen[100],
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(game: _game),
            Expanded(
              child: isDesktop
                  ? _DesktopLayout(game: _game)
                  : _MobileLayout(game: _game),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final MyPetGame game;
  const _TopBar({required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white.withValues(alpha: 0.95),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '🐾 MYPET Guardería',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.store, color: Colors.orange, size: 28),
                tooltip: 'Tienda',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ShopScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.backpack, color: Colors.blue, size: 28),
                tooltip: 'Inventario',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InventoryScreen()),
                ),
              ),
              Consumer<GameState>(
                builder: (_, gs, __) {
                  return Row(
                    children: [
                      _SyncIndicator(syncService: gs.syncService),
                      const SizedBox(width: 8),
                      _CoinsChip(coins: gs.player?.coins ?? 0),
                    ],
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.person, color: Colors.blueGrey, size: 28),
                tooltip: 'Cuenta',
                onPressed: () {
                  _showAuthDialog(context);
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (value) {
                  if (value == 'dev') {
                    _showDevOptions(context);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'dev', child: Text('Opciones de Desarrollo')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDevOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Opciones de Desarrollo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                final playerId = import_local_storage.LocalStorage.getPlayerId();
                final jsonStr = import_local_storage.LocalStorage.prefs.getString('player_data_$playerId');
                debugPrint('=== SAVE BACKUP ===\n$jsonStr\n===================');
                showDialog(
                   context: ctx,
                   builder: (c2) => AlertDialog(
                      title: const Text('Save Data'),
                      content: SelectableText(jsonStr ?? 'No save found'),
                   )
                );
              },
              child: const Text('Exportar Save a JSON (Ver)'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAuthDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const AuthDialog(),
    );
  }
}

class _SyncIndicator extends StatelessWidget {
  final import_game_sync.GameSyncService syncService;
  const _SyncIndicator({required this.syncService});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: syncService,
      builder: (context, _) {
        final authRepo = AuthRepository();
        final isLoggedIn = authRepo.isLoggedIn();

        IconData icon;
        Color color;
        String tooltip;

        if (!isLoggedIn) {
          icon = Icons.cloud_off;
          color = Colors.grey;
          tooltip = '☁ Solo local';
        } else {
          switch (syncService.status) {
            case import_game_sync.SyncStatus.synced:
              icon = Icons.cloud_done; color = Colors.green; tooltip = '☁ Guardado'; break;
            case import_game_sync.SyncStatus.syncing:
              icon = Icons.cloud_upload; color = Colors.blue; tooltip = '☁ Sincronizando...'; break;
            case import_game_sync.SyncStatus.pending:
              icon = Icons.cloud_queue; color = Colors.orange; tooltip = '⚠ Pendiente de sincronizar'; break;
            case import_game_sync.SyncStatus.error:
              icon = Icons.cloud_off; color = Colors.red; tooltip = '⚠ Sin conexión'; break;
            case import_game_sync.SyncStatus.conflict:
              icon = Icons.warning; color = Colors.red; tooltip = '⚠ Conflicto de sincronización'; break;
          }
        }
        
        return Tooltip(
          message: tooltip,
          child: Icon(icon, color: color, size: 20),
        );
      },
    );
  }
}

class _CoinsChip extends StatelessWidget {
  final int coins;
  const _CoinsChip({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.yellow[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Row(children: [
        const Text('💰', style: TextStyle(fontSize: 16)),
        const SizedBox(width: 4),
        Text('$coins',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.brown)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Desktop layout  (wide screen: game on left, info panel on right)
// ─────────────────────────────────────────────────────────────────────────────
class _DesktopLayout extends StatelessWidget {
  final MyPetGame game;
  const _DesktopLayout({required this.game});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left: game world + reception button
        Expanded(
          child: Stack(
            children: [
              GameWidget(game: game),
              Consumer<GameState>(
                builder: (_, gs, __) => _ReceptionButton(gameState: gs, game: game),
              ),
            ],
          ),
        ),
        // Right: pet info panel + action bar
        Consumer<GameState>(
          builder: (_, gs, __) {
            final pet = gs.selectedPet;
            if (pet == null) return _NoSelectionHint(desktop: true);
            return SingleChildScrollView(
              child: Column(
                children: [
                  PetInfoPanel(
                    pet: pet,
                    stay: gs.getStayForPet(pet.id),
                    onFeed:  () => gs.feedPet(),
                    onPlay:  () => gs.playWithPet(),
                    onBathe: () => gs.bathePet(),
                    onDeliver: () => _handleDeliver(context, gs, game, gs.getStayForPet(pet.id)!),
                  ),
                  const SizedBox(height: 8),
                  _ActionGrid(gameState: gs, pet: pet),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile / tablet layout  (game on top, info + actions below)
// ─────────────────────────────────────────────────────────────────────────────
class _MobileLayout extends StatelessWidget {
  final MyPetGame game;
  const _MobileLayout({required this.game});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Game area — takes most of the screen
        Expanded(
          flex: 5,
          child: Stack(
            children: [
              GameWidget(game: game),
              Consumer<GameState>(
                builder: (_, gs, __) => _ReceptionButton(gameState: gs, game: game),
              ),
            ],
          ),
        ),
        // Bottom HUD — info + actions
        Consumer<GameState>(
          builder: (_, gs, __) {
            final pet = gs.selectedPet;
            return _BottomHud(gameState: gs, game: game, pet: pet);
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom HUD (mobile/tablet)
// ─────────────────────────────────────────────────────────────────────────────
class _BottomHud extends StatelessWidget {
  final GameState gameState;
  final MyPetGame game;
  final Pet? pet;
  const _BottomHud({required this.gameState, required this.game, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle hint
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (pet != null) ...[
            PetInfoPanel(
              pet: pet!,
              stay: gameState.getStayForPet(pet!.id),
              onFeed:  () => gameState.feedPet(),
              onPlay:  () => gameState.playWithPet(),
              onBathe: () => gameState.bathePet(),
              onDeliver: () => _handleDeliver(context, gameState, game, gameState.getStayForPet(pet!.id)!),
            ),
            _ActionBar(gameState: gameState),
          ] else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Toca una mascota para seleccionarla',
                style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action bar (horizontal scroll of all actions)
// ─────────────────────────────────────────────────────────────────────────────
class _ActionBar extends StatelessWidget {
  final GameState gameState;
  const _ActionBar({required this.gameState});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _actionBtn('🍖', 'Comer',  () => gameState.feedPet()),
            _actionBtn('💧', 'Beber',  () => gameState.drinkPet()),
            _actionBtn('🎾', 'Jugar',  () => gameState.playWithPet()),
            _actionBtn('🧼', 'Bañar',  () => gameState.bathePet()),
            _actionBtn('❤️', 'Mimos',  () => gameState.petPet()),
            _actionBtn('😴', 'Dormir', () => gameState.sleepPet()),
            _actionBtn('🚶', 'Pasear', () => gameState.walkPet()),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(String icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(18),
              backgroundColor: Colors.white,
              foregroundColor: Colors.brown,
              elevation: 3,
            ),
            child: Text(icon, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                  fontSize: 12,
                  shadows: [Shadow(color: Colors.white, blurRadius: 8)])),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action grid (desktop side panel)
// ─────────────────────────────────────────────────────────────────────────────
class _ActionGrid extends StatelessWidget {
  final GameState gameState;
  final Pet pet;
  const _ActionGrid({required this.gameState, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _actionBtn('🍖', 'Comer',  () => gameState.feedPet()),
          _actionBtn('💧', 'Beber',  () => gameState.drinkPet()),
          _actionBtn('🎾', 'Jugar',  () => gameState.playWithPet()),
          _actionBtn('🧼', 'Bañar',  () => gameState.bathePet()),
          _actionBtn('❤️', 'Mimos',  () => gameState.petPet()),
          _actionBtn('😴', 'Dormir', () => gameState.sleepPet()),
          _actionBtn('🚶', 'Pasear', () => gameState.walkPet()),
        ],
      ),
    );
  }

  Widget _actionBtn(String icon, String label, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(14),
            backgroundColor: Colors.white,
            foregroundColor: Colors.brown,
            elevation: 3,
          ),
          child: Text(icon, style: const TextStyle(fontSize: 20)),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.brown, fontSize: 11)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reception button
// ─────────────────────────────────────────────────────────────────────────────
class _ReceptionButton extends StatelessWidget {
  final GameState gameState;
  final MyPetGame game;
  const _ReceptionButton({required this.gameState, required this.game});

  @override
  Widget build(BuildContext context) {
    final player = gameState.player;
    if (player == null || player.activePets.length >= player.capacity) {
      return const SizedBox.shrink();
    }
    return Positioned(
      top: 12,
      right: 12,
      child: ElevatedButton.icon(
        onPressed: () => _triggerReceptionSequence(context, gameState, game),
        icon: const Icon(Icons.doorbell, size: 24),
        label: const Text('Recepción', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[400],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          elevation: 5,
        ),
      ),
    );
  }

  void _triggerReceptionSequence(BuildContext context, GameState gameState, MyPetGame game) {
    final clients    = ['Laura', 'Carlos', 'Ana', 'Mario', 'Lucía'];
    final species    = ['dog', 'cat', 'rabbit', 'hamster'];
    final requests   = [
      'Quiere jugar mucho.',
      'Necesita que le den de comer.',
      'Viene un poco sucio, un baño le vendría bien.',
      'Está muy cansado.',
      'Necesita mucho cariño.',
    ];
    final personalities = ['Juguetón', 'Tímido', 'Curioso', 'Tranquilo', 'Travieso'];
    final petNames = {'dog': 'Toby', 'cat': 'Luna', 'rabbit': 'Coco', 'hamster': 'Pepe'};

    clients.shuffle();
    species.shuffle();
    requests.shuffle();
    personalities.shuffle();

    final clientName    = clients.first;
    final selectedSp    = species.first;
    final request       = requests.first;
    final personality   = personalities.first;
    final petName       = petNames[selectedSp] ?? 'Toby';

    final customer = import_customer.Customer(name: clientName);
    final pet = Pet(
      name: petName,
      species: selectedSp,
      personality: personality,
      clientName: clientName,
      clientRequest: request,
      stats: PetStats(hunger: 50, energy: 50, happiness: 50, hygiene: 50, thirst: 50),
    );

    // Disable button temporarily or just start sequence
    game.startIncomingSequence(pet, customer, request, () {
      _showReceptionDialog(context, gameState, pet, customer, request, game);
    });
  }

  void _showReceptionDialog(BuildContext context, GameState gameState, Pet pet, import_customer.Customer customer, String request, MyPetGame game) {

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.orange[50],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('🚪 ', style: TextStyle(fontSize: 22)),
            Flexible(
              child: Text('Recepción — ${customer.name}',
                  style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👩', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text('"Hola, soy ${customer.name}. Te dejo a ${pet.name} durante un rato."',
                style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange),
              ),
              child: Text('💬 Petición: $request',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              game.cancelIncomingSequence();
            },
            child: const Text('Rechazar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              game.finishIncomingSequence(pet, () {
                gameState.adoptPet(
                  pet,
                  customer: customer,
                  request: request,
                );
              });
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('ACEPTAR MASCOTA'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hint when nothing is selected (desktop only)
// ─────────────────────────────────────────────────────────────────────────────
class _NoSelectionHint extends StatelessWidget {
  final bool desktop;
  const _NoSelectionHint({required this.desktop});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: desktop ? 240 : null,
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            '👆\nToca una\nmascota',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.brown, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

void _handleDeliver(BuildContext context, GameState gs, MyPetGame game, BoardingStay stay) {
  game.finishOutgoingSequence(stay);
  gs.deliverPet(stay);
  showDialog(
    context: context,
    builder: (ctx) => _StayCompletedDialog(stay: stay),
  );
}

class _StayCompletedDialog extends StatefulWidget {
  final BoardingStay stay;
  const _StayCompletedDialog({required this.stay});

  @override
  State<_StayCompletedDialog> createState() => _StayCompletedDialogState();
}

class _StayCompletedDialogState extends State<_StayCompletedDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.yellow[50],
      title: const Text('🌟 Estancia Completada', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('¡El dueño ha venido a recoger a ${widget.stay.petId.substring(0, 4)}!'), // Assuming name wasn't saved, ID used as fallback or change to generic
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return ScaleTransition(
                scale: CurvedAnimation(
                  parent: _controller,
                  curve: Interval(index * 0.1, 0.5 + index * 0.1, curve: Curves.elasticOut),
                ),
                child: Icon(
                  index < (widget.stay.satisfaction ?? 3) ? Icons.star : Icons.star_border,
                  color: Colors.orange,
                  size: 32,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          ScaleTransition(
            scale: CurvedAnimation(
              parent: _controller,
              curve: const Interval(0.6, 1.0, curve: Curves.elasticOut),
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('💰', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text('+${widget.stay.rewardCoins} Monedas', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
                ],
              ),
            ),
          )
        ],
      ),
      actions: [
        Center(
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('¡GENIAL!'),
          ),
        ),
      ],
    );
  }
}

