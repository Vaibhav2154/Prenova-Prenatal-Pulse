import 'package:flutter/material.dart';
import 'package:prenova/features/auth/presentation/loginpage.dart';
import 'package:prenova/features/auth/presentation/welcome_pg.dart';
import 'package:prenova/features/dashboard/presentation/dashboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = Supabase.instance.client.auth.currentSession;
        print(session);
        return session == null ? const WelcomePage() :  DashboardScreen();
      },
    );
  }
}
