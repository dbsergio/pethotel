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
import '../../data/repositories/auth_repository.dart';
import 'minigames/eat_minigame.dart';
import 'minigames/bath_minigame.dart';
import 'minigames/petting_minigame.dart';
import '../../game/minigames/minigame_result.dart';
import '../economy/widgets/coin_counter_widget.dart';
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
      backgroundColor: const Color(0xFFFFF3E0),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: isDesktop
                  ? _DesktopLayout(game: _game)
                  : _MobileLayout(game: _game),
            ),
            Positioned(
              top: 0, left: 0, right: 0,
              child: _TopBar(game: _game, isDesktop: isDesktop),
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
  final bool isDesktop;
  const _TopBar({required this.game, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF6D4C41),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4E342E), width: 4),
        boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 4)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (isDesktop || MediaQuery.sizeOf(context).width > 450)
            const Text(
              '🐾 MYPET',
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.w900, 
                color: Color(0xFFFFE082),
                shadows: [Shadow(color: Colors.black54, offset: Offset(1, 2), blurRadius: 2)],
                letterSpacing: 1.2,
              ),
            )
          else
            const Text('🐾', style: TextStyle(fontSize: 24)),
          
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildHudIconButton(
                  context, 
                  icon: Icons.store_rounded, 
                  color: Colors.orange[300]!, 
                  tooltip: 'Tienda', 
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen())),
                ),
                _buildHudIconButton(
                  context, 
                  icon: Icons.backpack_rounded, 
                  color: Colors.lightBlue[300]!, 
                  tooltip: 'Inventario', 
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen())),
                ),
                Consumer<GameState>(
                  builder: (_, gs, __) {
                    return Row(
                      children: [
                        _SyncIndicator(syncService: gs.syncService),
                        const SizedBox(width: 4),
                        const CoinCounterWidget(),
                      ],
                    );
                  },
                ),
                const SizedBox(width: 4),
                _buildHudIconButton(
                  context, 
                  icon: Icons.person_rounded, 
                  color: Colors.white70, 
                  tooltip: 'Cuenta', 
                  onPressed: () => _showAuthDialog(context),
                ),
                Theme(
                  data: Theme.of(context).copyWith(iconTheme: const IconThemeData(color: Colors.white70)),
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    padding: EdgeInsets.zero,
                    onSelected: (value) {
                      if (value == 'dev') _showDevOptions(context);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'dev', child: Text('Desarrollo')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHudIconButton(BuildContext context, {required IconData icon, required Color color, required String tooltip, required VoidCallback onPressed}) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF5D4037),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF3E2723), width: 2),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
        onPressed: onPressed,
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
            color = Colors.grey[400]!;
            tooltip = 'Solo local';
          } else {
            switch (syncService.status) {
              case import_game_sync.SyncStatus.synced:
                icon = Icons.cloud_done; color = Colors.greenAccent; tooltip = 'Guardado'; break;
              case import_game_sync.SyncStatus.syncing:
                icon = Icons.cloud_upload; color = Colors.lightBlueAccent; tooltip = 'Sincronizando...'; break;
              case import_game_sync.SyncStatus.pending:
                icon = Icons.cloud_queue; color = Colors.orangeAccent; tooltip = 'Pendiente'; break;
              case import_game_sync.SyncStatus.error:
                icon = Icons.cloud_off; color = Colors.redAccent; tooltip = 'Error de conexión'; break;
              case import_game_sync.SyncStatus.conflict:
                icon = Icons.warning; color = Colors.redAccent; tooltip = 'Conflicto de sincronización'; break;
            }
          }

          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF5D4037),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF3E2723), width: 2),
            ),
            width: 40,
            height: 40,
            child: Tooltip(
              message: tooltip,
              child: Icon(icon, color: color, size: 20),
            ),
          );
        },
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
                    onFeed:  () => _startFeedMinigame(context, gs, pet),
                    onPlay:  () => game.startPlayMinigame(pet),
                    onBathe: () => _startBathMinigame(context, gs, pet),
                    onDeliver: () => _handleDeliver(context, gs, game, gs.getStayForPet(pet.id)!),
                  ),
                  const SizedBox(height: 8),
                  _ActionGrid(gameState: gs, game: game, pet: pet),
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
class _MobileLayout extends StatefulWidget {
  final MyPetGame game;
  const _MobileLayout({required this.game});

  @override
  State<_MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends State<_MobileLayout> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Game area — takes most of the screen
        Expanded(
          flex: _isExpanded ? 3 : 6,
          child: Stack(
            children: [
              GameWidget(game: widget.game),
              Consumer<GameState>(
                builder: (_, gs, __) => _ReceptionButton(gameState: gs, game: widget.game),
              ),
            ],
          ),
        ),
        // Bottom HUD — info + actions
        Consumer<GameState>(
          builder: (_, gs, __) {
            final pet = gs.selectedPet;
            return GestureDetector(
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity! < -300) {
                  setState(() => _isExpanded = true);
                } else if (details.primaryVelocity! > 300) {
                  setState(() => _isExpanded = false);
                }
              },
              onTap: () {
                if (pet != null) setState(() => _isExpanded = !_isExpanded);
              },
              child: _BottomHud(
                gameState: gs, 
                game: widget.game, 
                pet: pet, 
                isExpanded: _isExpanded,
              ),
            );
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
  final bool isExpanded;
  const _BottomHud({required this.gameState, required this.game, required this.pet, required this.isExpanded});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
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
            if (isExpanded)
              PetInfoPanel(
                pet: pet!,
                stay: gameState.getStayForPet(pet!.id),
                onFeed:  () => _startFeedMinigame(context, gameState, pet!),
                onPlay:  () => game.startPlayMinigame(pet!),
                onBathe: () => _startBathMinigame(context, gameState, pet!),
                onDeliver: () => _handleDeliver(context, gameState, game, gameState.getStayForPet(pet!.id)!),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Text(PetInfoPanel.speciesEmoji(pet!.species), style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pet!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.brown)),
                          Text(PetInfoPanel.actionLabel(pet!.currentAction), style: TextStyle(fontSize: 13, color: Colors.brown[400])),
                        ],
                      ),
                    ),
                    _MiniStat('❤️', pet!.stats.happiness),
                    const SizedBox(width: 8),
                    _MiniStat('⚡', pet!.stats.energy),
                  ],
                ),
              ),
            _ActionBar(gameState: gameState, game: game, pet: pet!),
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

class _MiniStat extends StatelessWidget {
  final String emoji;
  final double value;
  const _MiniStat(this.emoji, this.value);
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 2),
        Text(value.toInt().toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action bar (horizontal scroll of all actions)
// ─────────────────────────────────────────────────────────────────────────────
class _ActionBar extends StatelessWidget {
  final GameState gameState;
  final MyPetGame game;
  final Pet pet;
  const _ActionBar({required this.gameState, required this.game, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _actionBtn('🍖', 'Comer',  () => _startFeedMinigame(context, gameState, pet)),
            _actionBtn('💧', 'Beber',  () => gameState.drinkPet()),
            _actionBtn('🎾', 'Jugar',  () => game.startPlayMinigame(pet)),
            _actionBtn('🧼', 'Bañar',  () => _startBathMinigame(context, gameState, pet)),
            _actionBtn('❤️', 'Mimos',  () => _startPettingMinigame(context, gameState, pet)),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF6D4C41), width: 3),
              ),
              padding: const EdgeInsets.all(16),
              backgroundColor: const Color(0xFFFFF3E0),
              foregroundColor: Colors.brown,
              elevation: 4,
              shadowColor: Colors.black54,
            ),
            child: Text(icon, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF4E342E),
                  fontSize: 12,
                  letterSpacing: 0.5,
                  shadows: [Shadow(color: Colors.white, blurRadius: 4)])),
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
  final MyPetGame game;
  final Pet pet;
  const _ActionGrid({required this.gameState, required this.game, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _actionBtn('🍖', 'Comer',  () => _startFeedMinigame(context, gameState, pet)),
          _actionBtn('💧', 'Beber',  () => gameState.drinkPet()),
          _actionBtn('🎾', 'Jugar',  () => game.startPlayMinigame(pet)),
          _actionBtn('🧼', 'Bañar',  () => _startBathMinigame(context, gameState, pet)),
          _actionBtn('❤️', 'Mimos',  () => _startPettingMinigame(context, gameState, pet)),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF6D4C41), width: 3),
            ),
            padding: const EdgeInsets.all(14),
            backgroundColor: const Color(0xFFFFF3E0),
            foregroundColor: Colors.brown,
            elevation: 4,
            shadowColor: Colors.black54,
          ),
          child: Text(icon, style: const TextStyle(fontSize: 20)),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w900, color: Color(0xFF4E342E), fontSize: 11, letterSpacing: 0.5)),
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
    if (player == null) return const SizedBox.shrink();

    final activeCount = player.activePets.length;
    final maxCapacity = player.capacity;
    final isFull = activeCount >= maxCapacity;

    return Positioned(
      top: 80,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF8D6E63),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF5D4037), width: 3),
              boxShadow: const [BoxShadow(color: Colors.black38, offset: Offset(2, 4), blurRadius: 4)],
            ),
            child: Text(
              isFull ? 'Lleno ($activeCount/$maxCapacity)' : 'Ocupación: $activeCount/$maxCapacity',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isFull ? const Color(0xFFFF8A65) : const Color(0xFFFFE082),
                fontSize: 14,
              ),
            ),
          ),
          if (!isFull)
            ElevatedButton.icon(
              onPressed: () => _triggerReceptionSequence(context, gameState, game),
              icon: const Icon(Icons.doorbell, size: 24),
              label: const Text('Recepción', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD84315),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFBF360C), width: 3),
                ),
                elevation: 6,
                shadowColor: Colors.black54,
              ),
            ),
        ],
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
      stats: PetStats.random(species: selectedSp, personality: personality),
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

void _startFeedMinigame(BuildContext context, GameState gs, Pet pet) {
  showDialog<CareMinigameResult>(
    context: context,
    builder: (ctx) => EatMinigame(pet: pet),
  ).then((result) {
    if (result != null && !result.cancelled) {
       gs.feedPet(result: result);
    }
  });
}

void _startBathMinigame(BuildContext context, GameState gs, Pet pet) {
  showDialog<CareMinigameResult>(
    context: context,
    builder: (ctx) => BathMinigame(pet: pet),
  ).then((result) {
    if (result != null && !result.cancelled) {
       gs.bathePet(result: result);
    }
  });
}

void _startPettingMinigame(BuildContext context, GameState gs, Pet pet) {
  showDialog<CareMinigameResult>(
    context: context,
    builder: (ctx) => PettingMinigame(pet: pet),
  ).then((result) {
    if (result != null && !result.cancelled) {
       gs.petPet(result: result);
    }
  });
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

