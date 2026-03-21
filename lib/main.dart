import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force dark status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Supabase
  // Pass real values via --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
  await Supabase.initialize(
    url: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://fildemavidnskmhcyqin.supabase.co',
    ),
    anonKey: const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZpbGRlbWF2aWRuc2ttaGN5cWluIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQxMjA4NDIsImV4cCI6MjA4OTY5Njg0Mn0.RMvXg1oy3ZC2z4KJb6BI0OcxBaS6yhk5jdnQWTp8yRk',
    ),
  );

  runApp(
    const ProviderScope(
      child: SparkApp(),
    ),
  );
}
