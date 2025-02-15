import 'package:flutter/material.dart';
import 'package:prenova/core/theme/app_pallete.dart';
import 'package:prenova/core/theme/starry_bg.dart';
import 'package:prenova/features/auth/auth_service.dart';
import 'package:prenova/features/auth/presentation/glowing_btn.dart';
//import 'package:unihub/pages/loginpage.dart';

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

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: StarryBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: const Text("Register")),
          body: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                      'assets/logo.png',
                      height: 250,
                    ),
                  const Text(
                    "Register",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppPallete.greyColor,
                    ),
                  ),
                  const SizedBox(height: 20,),
                  TextField(
                    controller: _emailcontroller,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: "Email",
                    prefixIcon: const Icon(Icons.email, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _passwordcontroller,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "Password",
                    prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "Confirm Password",
                    prefixIcon: Icon(Icons.lock, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 25),
                  // Container(
                  //   decoration: BoxDecoration(
                  //     gradient: const LinearGradient(
                  //       colors: [
                  //         AppPallete.gradient1,
                  //         AppPallete.gradient2,
                  //         // AppPallete.gradient3,
                  //       ],
                  //       begin: Alignment.bottomLeft,
                  //       end: Alignment.topRight,
                  //     ),
                  //     borderRadius: BorderRadius.circular(7),
                  //   ),
                  //     child: Container(

                          // child:
                             SizedBox(
                              height: 60,
                              width: 200,
                              child: GlowingButton(text: "Register", onPressed: register)),
                    //
                    // ElevatedButton(
                    //   onPressed: register,
                    //   style: ElevatedButton.styleFrom(
                    //     fixedSize: const Size(395, 55),
                    //     backgroundColor: AppPallete.transparentColor,
                    //     shadowColor: AppPallete.transparentColor,
                    //   ),
                    //   child: const Text(
                    //     "Register",
                    //     style: TextStyle(
                    //       fontSize: 17,
                    //       fontWeight: FontWeight.w600,
                    //     ),
                    //   ),
                    // ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
