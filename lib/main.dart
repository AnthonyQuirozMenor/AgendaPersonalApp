import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'providers/app_state.dart';
import 'services/storage_service.dart';
import 'services/sqlite_storage_service.dart';
import 'services/web_storage_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for Spanish locale
  await initializeDateFormatting('es', null);

  // Initialize Supabase Auth only if valid credentials are provided
  final bool isSupabaseConfigured = SupabaseConfig.url.startsWith('http');
  if (isSupabaseConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );
    } catch (e) {
      debugPrint('Supabase initialization failed: $e');
    }
  } else {
    debugPrint('Supabase credentials are not configured. Running in offline fallback mode.');
  }

  // Instantiating proper storage service based on platform
  final StorageService storageService = kIsWeb ? WebStorageService() : SqliteStorageService();
  await storageService.init();

  final appState = AppState(storageService: storageService);
  await appState.tryAutoLogin();

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return MaterialApp(
      title: 'Agenda Personal',
      debugShowCheckedModeBanner: false,
      
      // --- Material 3 Light Theme ---
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3F51B5), // Slate Indigo
          brightness: Brightness.light,
        ),
        cardTheme: const CardThemeData(
          margin: EdgeInsets.zero,
        ),
        chipTheme: const ChipThemeData(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        ),
      ),

      // --- Material 3 Dark Theme ---
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3F51B5),
          brightness: Brightness.dark,
        ),
        cardTheme: const CardThemeData(
          margin: EdgeInsets.zero,
        ),
        chipTheme: const ChipThemeData(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        ),
      ),

      themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // --- Routing check based on user session ---
      home: appState.currentUser == null ? const LoginScreen() : const HomeLayout(),
    );
  }
}