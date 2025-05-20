import 'package:flutter/material.dart';
import 'package:prenova/core/theme/app_theme.dart';
// import 'package:prenova/features/auth/presentation/Registerpage.dart';
// import 'package:prenova/features/auth/presentation/loginpage.dart';
// import 'package:prenova/features/auth/presentation/welcome_pg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prenova/features/auth/auth_gate.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: 'https://xgfvhqskjdgcfynnbpky.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhnZnZocXNramRnY2Z5bm5icGt5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzkxNjUwNzcsImV4cCI6MjA1NDc0MTA3N30.j61xNNnCtK_Kqv3_m1nQLj0Fdxn8gsV7kNGkJTXil6o',
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
