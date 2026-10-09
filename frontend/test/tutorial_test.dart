import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mypet_frontend/features/nursery/tutorial_overlay.dart';
import 'package:mypet_frontend/core/audio/audio_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestApp(AudioService audio) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AudioService>.value(value: audio),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Container(color: Colors.blue),
              const TutorialOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('Test A & E - Avance sin errores hasta el último paso', (WidgetTester tester) async {
    final audio = AudioService();
    await tester.pumpWidget(buildTestApp(audio));
    await tester.pumpAndSettle();

    expect(find.text('¡Bienvenido a la Guardería!'), findsOneWidget);

    for (int i = 0; i < 4; i++) {
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
    }

    expect(find.text('¡Cobra tus Recompensas!'), findsOneWidget);
    expect(find.text('¡Empezar!'), findsOneWidget);
  });

  testWidgets('Test B & F - Finalización normal y capa desaparece', (WidgetTester tester) async {
    final audio = AudioService();
    await tester.pumpWidget(buildTestApp(audio));
    await tester.pumpAndSettle();

    for (int i = 0; i < 4; i++) {
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
    }

    // Ultimo paso, tap "Empezar!"
    await tester.tap(find.text('¡Empezar!'));
    await tester.pumpAndSettle();

    expect(find.text('¡Cobra tus Recompensas!'), findsNothing);
    
    // Validate it doesn't block taps by checking if IgnorePointer is present
    final ignorePointer = tester.widget<IgnorePointer>(
      find.descendant(of: find.byType(TutorialOverlay), matching: find.byType(IgnorePointer))
    );
    expect(ignorePointer.ignoring, isTrue); 
  });

  testWidgets('Test C - Omisión temprana', (WidgetTester tester) async {
    final audio = AudioService();
    await tester.pumpWidget(buildTestApp(audio));
    await tester.pumpAndSettle();

    expect(find.text('¡Bienvenido a la Guardería!'), findsOneWidget);

    await tester.tap(find.text('Omitir'));
    await tester.pumpAndSettle();

    expect(find.text('¡Bienvenido a la Guardería!'), findsNothing);
  });

  testWidgets('Test D - Persistencia', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'has_seen_tutorial_v1': true});
    final audio = AudioService();
    
    await tester.pumpWidget(buildTestApp(audio));
    await tester.pumpAndSettle();

    expect(find.text('¡Bienvenido a la Guardería!'), findsNothing);
  });
}
