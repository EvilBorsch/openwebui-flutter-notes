import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/app.dart';
import 'src/services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = SettingsService();
  await settings.load();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => settings)],
      child: const NotesApp(),
    ),
  );
}
