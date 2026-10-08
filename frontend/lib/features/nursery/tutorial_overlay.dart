import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/local/game_state.dart';
import '../../../core/audio/audio_service.dart';

class TutorialOverlay extends StatefulWidget {
  const TutorialOverlay({super.key});

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  static const String _tutorialKey = 'has_seen_tutorial_v1';
  bool _isVisible = false;
  int _currentStep = 0;

  final List<Map<String, String>> _steps = [
    {
      'title': '¡Bienvenido a la Guardería!',
      'content': 'Tu tarea es cuidar de las mascotas que lleguen. Acéptalas tocando sobre los clientes que aparezcan con una interrogación.',
      'icon': '👋',
    },
    {
      'title': 'Observa sus necesidades',
      'content': 'Selecciona a una mascota tocándola. Podrás ver si tiene hambre, sed, energía o si necesita un baño.',
      'icon': '🔍',
    },
    {
      'title': 'Cuídalas',
      'content': 'Usa los botones de acción para alimentarlas, darles agua o jugar. ¡Cada acción abrirá un pequeño minijuego!',
      'icon': '❤️',
    },
    {
      'title': 'Revisa el Inventario',
      'content': 'Las acciones consumen objetos. Si te quedas sin comida o agua, abre la Tienda en el menú superior para comprar más.',
      'icon': '🎒',
    },
    {
      'title': '¡Cobra tus Recompensas!',
      'content': 'Cuando la barra de progreso de una estancia esté llena, finalízala para cobrar las monedas por tu gran trabajo.',
      'icon': '💰',
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkTutorialStatus();
  }

  Future<void> _checkTutorialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool(_tutorialKey) ?? false;
    if (!hasSeen) {
      setState(() => _isVisible = true);
    }
  }

  Future<void> _finishTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialKey, true);
    setState(() => _isVisible = false);
    if (mounted) {
      context.read<AudioService>().playUiSelect();
    }
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
      context.read<AudioService>().playUiTap();
    } else {
      _finishTutorial();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    final step = _steps[_currentStep];

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFFFCC80), width: 4),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(step['icon']!, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  step['title']!,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  step['content']!,
                  style: const TextStyle(fontSize: 16, color: Color(0xFF5D4037)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _finishTutorial,
                      child: const Text('Omitir', style: TextStyle(color: Colors.grey)),
                    ),
                    Row(
                      children: [
                        Text(
                          '${_currentStep + 1}/${_steps.length}',
                          style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _nextStep,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(_currentStep == _steps.length - 1 ? '¡Empezar!' : 'Siguiente'),
                        ),
                      ],
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
