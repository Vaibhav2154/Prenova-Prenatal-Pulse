import 'package:flutter/material.dart';
import 'package:prenova/core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prenova/features/auth/auth_gate.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';




void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName:".env");
  String url = dotenv.env['SUPABASE_URL'] ?? '';
  String anonKey = dotenv.env['SUPABASE_KEY'] ?? '';
  try {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      debug: true,
    );
  } catch (e) {
    debugPrint("Error initializing Supabase: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkThemeMode,
      home:  AuthGate(), // Uses AuthGate to handle session-based navigation
    );
  }
}
