import 'package:flutter/material.dart';

import 'core/app.dart';
import 'data/content/chord_library.dart';
import 'data/local/local_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final chordLibrary = await ChordLibrary.loadFromAsset();
  runApp(App(store: PrefsLocalStore(), chordLibrary: chordLibrary));
}
