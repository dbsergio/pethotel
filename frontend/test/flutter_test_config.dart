import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mypet_frontend/data/local/local_storage.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Configurar mock de SharedPreferences para tests
  SharedPreferences.setMockInitialValues({});
  
  // Inicializar LocalStorage para evitar LateInitializationError
  await LocalStorage.init();
  
  // Ejecutar el resto de los tests
  await testMain();
}
