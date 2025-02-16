import 'package:flutter/material.dart';
import 'package:prenova/core/theme/app_pallete.dart';
import 'package:prenova/core/theme/starry_bg.dart';
import 'package:prenova/features/auth/auth_service.dart';
import 'package:prenova/features/auth/presentation/glowing_btn.dart';
import 'package:prenova/features/auth/presentation/loginpage.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final authservice = AuthService();

  // Controllers for user input
  final _emailcontroller = TextEditingController();
  final _passwordcontroller = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  void register() async {
    print("registerUser() called");
    final email = _emailcontroller.text.trim();
    final password = _passwordcontroller.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    print("Email: $email, Password: $password, Confirm Password: $confirmPassword");

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields.")),
      );
      return;
    }

    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid email address.")),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match.")),
      );
      return;
    }

    // Attempt registration
    try {
      print("Attempting Supabase registration");
      await authservice.signUpWithEmailPassword(email, password);
      print("After await authservice");
      if (mounted) {
        print("Inside if(mount)");
        Navigator.pop(context);
      }
      print("Supabase registration successful (or error)");
    } catch (e) {
      print("Error during registration: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    }
    print("registerUser() finished");
  }

  // Google Sign-In
  Future<void> signInWithGoogle() async {
    try {
      await authservice.signInWithGoogle();
      if (mounted) {
        Navigator.pop(context); // Navigate back after successful login
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Google Sign-In Error: ${e.toString()}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: StarryBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 90),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logo.png',
                    height: 300,
                  ),
                  const Text(
                    "Register",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppPallete.textColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _emailcontroller,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      prefixIcon: Icon(Icons.email, color: Colors.grey),
                    ),
                    style: TextStyle(color: AppPallete.textColor),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _passwordcontroller,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Password",
                      prefixIcon: Icon(Icons.lock, color: Colors.grey),
                    ),
                    style: TextStyle(color: AppPallete.textColor),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Confirm Password",
                      prefixIcon: Icon(Icons.lock, color: Colors.grey),
                    ),
                    style: TextStyle(color: AppPallete.textColor),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    height: 60,
                    width: 200,
                    child: GlowingButton(text: "Register", onPressed: register),
                  ),
                  const SizedBox(height: 20),
                  // Google Sign-In Button
                  ElevatedButton(
                    onPressed: signInWithGoogle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        
                        const SizedBox(width: 10),
                        const Text(
                          "Sign up with Google",
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginPage()),
                      );
                    },
                    child: const Text(
                      "Already have an account? Sign in",
                      style: TextStyle(color: AppPallete.textColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}