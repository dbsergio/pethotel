import 'package:flutter/material.dart';
import '../../game/models/pet.dart';
import '../../game/models/boarding_stay.dart';

/// Responsive pet information panel.
///
/// - Desktop (width >= 600): floating card on the right side of the game area.
/// - Mobile/tablet portrait: bottom sheet-style card.
///
/// The panel reads only from the [Pet] passed in — it does NOT hold a copy of
/// the state. The parent is responsible for passing the currently selected pet.
class PetInfoPanel extends StatelessWidget {
  final Pet pet;
  final BoardingStay? stay;
  final VoidCallback? onClose;
  final VoidCallback? onFeed;
  final VoidCallback? onPlay;
  final VoidCallback? onBathe;
  final VoidCallback? onDeliver;

  const PetInfoPanel({
    super.key,
    required this.pet,
    this.stay,
    this.onClose,
    this.onFeed,
    this.onPlay,
    this.onBathe,
    this.onDeliver,
  });

  // ── Species helpers ────────────────────────────────────────────────────────
  static String speciesEmoji(String species) => switch (species) {
        'cat'     => '🐱',
        'rabbit'  => '🐰',
        'hamster' => '🐹',
        _         => '🐶',
      };

  static String speciesLabel(String species) => switch (species) {
        'cat'     => 'Gato',
        'rabbit'  => 'Conejo',
        'hamster' => 'Hámster',
        _         => 'Perro',
      };

  static String actionLabel(PetAction action) => switch (action) {
        PetAction.eating         => '🍖 Comiendo',
        PetAction.drinking       => '💧 Bebiendo',
        PetAction.playing        => '🎾 Jugando',
        PetAction.bathing        => '🧼 Bañándose',
        PetAction.sleeping       => '😴 Durmiendo',
        PetAction.petting        => '❤️ Recibiendo mimos',
        PetAction.walking        => '🚶 Paseando',
        PetAction.going_to_eat   => '🍖 Caminando a comer...',
        PetAction.going_to_drink => '💧 Caminando a beber...',
        PetAction.going_to_play  => '🎾 Caminando a jugar...',
        PetAction.going_to_bath  => '🧼 Caminando al baño...',
        PetAction.going_to_sleep => '😴 Caminando a dormir...',
        PetAction.going_to_walk  => '🚶 Preparándose...',
        PetAction.walking_in     => '🚪 Entrando...',
        PetAction.walking_out    => '🚪 Saliendo...',
        PetAction.happy          => '🎉 Contento',
        _                        => '😌 Descansando',
      };

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 600;
    return isWide ? _desktopPanel(context) : _mobilePanel(context);
  }

  // ── Desktop: floating card ─────────────────────────────────────────────────
  Widget _desktopPanel(BuildContext context) {
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 12, top: 12, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _header(),
          const Divider(height: 1),
          _body(),
          _quickActions(),
        ],
      ),
    );
  }

  // ── Mobile: compact card ───────────────────────────────────────────────────
  Widget _mobilePanel(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _header(),
          const Divider(height: 1),
          _body(),
          _quickActions(),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          Text(speciesEmoji(pet.species), style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D4037),
                  ),
                ),
                Text(
                  '${speciesLabel(pet.species)} · ${pet.personality}',
                  style: TextStyle(fontSize: 13, color: Colors.brown[400]),
                ),
              ],
            ),
          ),
          if (onClose != null)
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close, color: Colors.grey),
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────
  Widget _body() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estado actual
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel(pet.currentAction),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Stats
          _statRow('🍖', 'Hambre', pet.stats.hunger, Colors.orange),
          _statRow('💧', 'Sed', pet.stats.thirst, Colors.blue),
          _statRow('🧼', 'Higiene', pet.stats.hygiene, Colors.lightBlue),
          _statRow('⚡', 'Energía', pet.stats.energy, Colors.amber),
          _statRow('❤️', 'Felicidad', pet.stats.happiness, Colors.red),
          // Client info
          if (stay != null) ...[
            const SizedBox(height: 10),
            const Divider(),
            Row(children: [
              const Icon(Icons.person, size: 16, color: Colors.brown),
              const SizedBox(width: 4),
              Text('Cliente: ${stay!.customer.name}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF5D4037))),
            ]),
            const SizedBox(height: 4),
            Text('💬 ${stay!.request}',
                style: TextStyle(fontSize: 12, color: Colors.brown[300], fontStyle: FontStyle.italic)),
            
            if (stay!.status == StayStatus.readyForPickup && onDeliver != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onDeliver,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('ENTREGAR MASCOTA'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ] else if (stay!.status == StayStatus.active) ...[
              const SizedBox(height: 10),
              const Text('⏱️ Estancia en curso', style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold)),
            ]
          ] else if (pet.clientName != null) ...[
            // Fallback for old pets
            const SizedBox(height: 10),
            const Divider(),
            Row(children: [
              const Icon(Icons.person, size: 16, color: Colors.brown),
              const SizedBox(width: 4),
              Text('Cliente: ${pet.clientName!}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF5D4037))),
            ]),
            if (pet.clientRequest != null) ...[
              const SizedBox(height: 4),
              Text('💬 ${pet.clientRequest!}',
                  style: TextStyle(fontSize: 12, color: Colors.brown[300], fontStyle: FontStyle.italic)),
            ],
          ],
        ],
      ),
    );
  }

  Widget _statRow(String emoji, String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          SizedBox(
            width: 60,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF795548))),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: value / 100.0, end: value / 100.0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                builder: (context, animValue, _) {
                  return LinearProgressIndicator(
                    value: animValue,
                    color: color,
                    backgroundColor: Colors.grey[200],
                    minHeight: 8,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 30,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: value, end: value),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, animValue, _) {
                return Text(
                  animValue.toInt().toString(),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick actions ──────────────────────────────────────────────────────────
  Widget _quickActions() {
    if (onFeed == null && onPlay == null && onBathe == null) {
      return const SizedBox(height: 8);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (onFeed != null)  _quickBtn('🍖', 'Comer',  onFeed!,  Colors.orange),
          if (onPlay != null)  _quickBtn('🎾', 'Jugar',  onPlay!,  Colors.green),
          if (onBathe != null) _quickBtn('🧼', 'Bañar',  onBathe!, Colors.lightBlue),
        ],
      ),
    );
  }

  Widget _quickBtn(String emoji, String label, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
