import 'package:flutter/material.dart';
import 'package:prenova/core/theme/app_pallete.dart';
import 'package:prenova/features/auth/auth_service.dart';
import 'package:prenova/features/auth/presentation/loginpage.dart';
import 'package:prenova/features/auth/presentation/edit_profile_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final authService = AuthService();
  final SupabaseClient supabase = Supabase.instance.client;

  String userName = "Loading...";
  String pregnancyTrimester = "Loading...";
  String currentWeight = "Loading...";
  String bmi = "Loading...";

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response = await supabase
        .from('profiles')
        .select('user_name, pregnancy_trimester, current_weight, current_height')
        .eq('UID', user.id)
        .maybeSingle();

    if (response != null) {
      setState(() {
        userName = response['user_name'] ?? "Unknown";
        pregnancyTrimester = "${response['pregnancy_trimester']} Trimester";
        currentWeight = "${response['current_weight']} kg";

        double weight = double.tryParse(response['current_weight'].toString()) ?? 0;
        double height = double.tryParse(response['current_height'].toString()) ?? 0;
        bmi = (height > 0) ? (weight / ((height / 100) * (height / 100))).toStringAsFixed(2) : "N/A";
      });
    }
  }

  void logout() async {
    await authService.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  void navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(
          userName: userName,
          trimester: pregnancyTrimester.split(" ")[0],
          weight: currentWeight.split(" ")[0],
        ),
      ),
    ).then((_) => _fetchUserProfile()); // Refresh profile after editing
  }

  @override
  Widget build(BuildContext context) {
    final currentEmail = authService.getCurrentUserEmail() ?? "No email found";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppPallete.borderColor,AppPallete.backgroundColor],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 100),

                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.pinkAccent.withOpacity(0.4), blurRadius: 12, spreadRadius: 3)
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 5),
                  Text(currentEmail, style: const TextStyle(fontSize: 14, color: Colors.white70)),

                  const SizedBox(height: 10),

                  // Edit Button
                  ElevatedButton.icon(
                    onPressed: navigateToEditProfile,
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),

                  const SizedBox(height: 30),

                  _buildProfileCard("Pregnancy Trimester", pregnancyTrimester, Icons.pregnant_woman),
                  _buildProfileCard("Current Weight", currentWeight, Icons.monitor_weight),
                  _buildProfileCard("Medical Documents", "View & Manage", Icons.folder_open),
                  _buildProfileCard("BMI (Body Mass Index)", bmi, Icons.fitness_center),

                  const SizedBox(height: 30),

                  ElevatedButton.icon(
                    onPressed: logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text("Logout", style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[900]?.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.pinkAccent.withOpacity(0.4), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5, spreadRadius: 1)],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.pinkAccent, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
        ],
      ),
    );
  }
}
