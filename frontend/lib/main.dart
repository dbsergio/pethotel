import 'package:flutter/material.dart';
import 'data/local/local_storage.dart';
import 'app/mypet_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorage.init();
  runApp(const MyPetApp());
}
