import 'package:flutter/material.dart';
import 'package:prenova/core/theme/app_pallete.dart';
import 'package:prenova/core/theme/starry_bg.dart';
import 'package:prenova/features/auth/auth_service.dart';
import 'package:prenova/features/auth/presentation/glowing_btn.dart';
import 'package:prenova/features/auth/presentation/registerpage.dart';
import 'package:prenova/features/dashboard/presentation/dashboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
//import 'package:unihub/pages/forgotpassword.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final authservice = AuthService();
  final _emailcontroller = TextEditingController();
  final _passwordcontroller = TextEditingController();

  void login() async {
    final email = _emailcontroller.text.trim();
    final password = _passwordcontroller.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both email and password.")),
      );
      return;
    }


    try {
      await authservice.signInWithEmailPassword(email, password);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) =>  DashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e is AuthException ? e.message : "Something went wrong!"}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StarryBackground(
      child: Scaffold(
        backgroundColor: AppPallete.transparentColor,
        body: SingleChildScrollView(
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 50,),
                  Image.asset(
                    'assets/logo.png',
                    height: 320,
                  ),
                  const Text(
                    "Sign in to continue",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppPallete.textColor,
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: _emailcontroller,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: "Email",
                    hoverColor: AppPallete.errorColor,
                    prefixIcon: const Icon(Icons.email, color: Colors.grey),
                    focusColor: AppPallete.borderColor
                    ),
                    style: TextStyle(color: AppPallete.textColor),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _passwordcontroller,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "Password",
                    prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                    ),
                    style: TextStyle(color: AppPallete.textColor),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 200,
                    height: 60,
                    child: GlowingButton(
                      text: "Login",
                      onPressed: login,
                    ),
                  ),
                  const SizedBox(height: 10),

                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterPage()),
                      );
                    },
                    child: const Text("Don't have an account? Sign up",
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
