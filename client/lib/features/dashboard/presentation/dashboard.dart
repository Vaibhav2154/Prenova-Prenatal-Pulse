import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
// import 'package:prenova/features/BabyStatus/Body/baby_status_page.dart';
// import 'package:prenova/features/Chatbot/presentation/chatbot.dart';
import 'package:prenova/features/auth/auth_service.dart';
import 'package:prenova/features/auth/presentation/Profilepage.dart';
// import 'package:prenova/features/doctor_cons/presentation/doctor_consulation.dart';
// import 'package:prenova/features/fetal_health/presentation/fetal_health.dart';
// import 'package:prenova/features/pregnancy_diet_screen/pregnancy_diet_screen.dart';
// import 'package:prenova/features/pregnancy_risk/presentation/pregnancy_risk.dart';

class DashboardScreen extends StatelessWidget {
  final authservice = AuthService();

  @override
  Widget build(BuildContext context) {
    final userEmail = authservice.getCurrentUserEmail() ?? "No email found";
    String username = userEmail.split('@')[0]; // Extract name before '@'

    final List<Map<String, dynamic>> dashboardItems = [
      {
        'title': 'Pregnancy Risk Detection',
        'icon': LucideIcons.heartPulse,
        'onPressed': () {
          //Navigator.push(context, MaterialPageRoute(builder: (context) => PregnancyRiskScreen()));
        }
      },
      {
        'title': 'Fetal Health Prediction',
        'icon': LucideIcons.baby,
        'onPressed': () {
          //Navigator.push(context, MaterialPageRoute(builder: (context) => FetalHealthScreen()));
        }
      },
      {
        'title': 'Chatbot',
        'icon': LucideIcons.messageCircle,
        'onPressed': () {
          //Navigator.push(context, MaterialPageRoute(builder: (context) => PregnancyChatScreen()));
        }
      },
      {
        'title': 'Doctor Consultation',
        'icon': LucideIcons.stethoscope,
        'onPressed': () {
         // Navigator.push(context, MaterialPageRoute(builder: (context) => DoctorConsultationPage()));
        }
      },
      {
        'title': 'Baby Status',
        'icon': LucideIcons.baby,
        'onPressed': () {
          //Navigator.push(context, MaterialPageRoute(builder: (context) => BabyStatusPage(builder: (context) {})));
        }
      },
      {
        'title': 'Pregnancy Diet',
        'icon': LucideIcons.utensils,
        'onPressed': () {
          //Navigator.push(context, MaterialPageRoute(builder: (context) => PregnancyDietScreen()));
        }
      },
    ];

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)), // More rounded app bar
          child: Stack(
            children: [
              // Background Gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.pinkAccent, Colors.deepPurpleAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
              ),
              // Glass Effect Overlay
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: AppBar(
                  title: Text(
                    'Dashboard',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Colors.white,
                    ),
                  ),
                  centerTitle: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: IconButton(
                        icon: Icon(Icons.account_circle, size: 32, color: Colors.white),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage()));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Message
            Text(
              "Hello, $username 👋",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 6),
            Text(
              "What would you like to do today?",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 20),

            // Grid Items
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemCount: dashboardItems.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: dashboardItems[index]['onPressed'],
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pinkAccent.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: Offset(0, 8), // Creates a subtle floating effect
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(dashboardItems[index]['icon'], size: 40, color: Colors.pinkAccent),
                          SizedBox(height: 10),
                          Text(
                            dashboardItems[index]['title'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.black, // Dark theme background
    );
  }
}
