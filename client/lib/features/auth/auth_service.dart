import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class AuthService {
  final SupabaseClient supabase = Supabase.instance.client;

  // Get current session
  Session? get currentSession => supabase.auth.currentSession;

  // Get current user
  User? get currentUser => supabase.auth.currentUser;

  // Sign in with email and password
  Future<void> signInWithEmailPassword(String email, String password) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session == null) {
        throw Exception('Invalid email or password');
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Sign up with email and password
  Future<void> signUpWithEmailPassword(String email, String password) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Sign-up failed');
      }
    } catch (e) {
      throw Exception('Sign-up error: $e');
    }
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      await supabase.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      throw Exception("Password update failed: $e");
    }
  }

  // Reset Password
  Future<void> resetPassword(String email) async {
    try {
      await supabase.auth.resetPasswordForEmail(email, redirectTo: "unihub://auth/callback");
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      throw Exception('Sign-out error: $e');
    }
  }

  String? getCurrentUserEmail() {
    final session = supabase.auth.currentSession;
    return session?.user.email;
  }
  

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  // Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      // Trigger Google OAuth flow
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google, // Use the correct provider enum
        redirectTo: 'https://xgfvhqskjdgcfynnbpky.supabase.co/auth/v1/callback', // Your custom redirect URL
      );
    } catch (e) {
      throw Exception('Google Sign-in error: $e');
    }
  }
}