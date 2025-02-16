import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:prenova/core/theme/app_pallete.dart';
import 'package:prenova/features/MedicalDocuments/medical_documents.dart';
import 'package:prenova/features/auth/auth_service.dart';
import 'package:prenova/features/auth/presentation/Profilepage.dart';
import 'package:prenova/features/dashboard/presentation/contraction_timer.dart';
import 'package:prenova/features/pregnancy_risk/presentation/pregnancy_risk.dart';
import 'package:prenova/features/fetal_health/presentation/fetal_health.dart';
import 'package:prenova/features/pregnancy_risk/presentation/pregnancy_risk.dart';
import 'package:prenova/features/kick_tracker/presentation/kick_tracker.dart';
import 'package:prenova/features/chatbot/presentation/chatbot.dart';
import 'package:prenova/features/pregnancy_diet_screen/pregnancy_diet_screen.dart';
// import 'package:prenova/features/medical_docs/presentation/upload_docs.dart';
import 'package:prenova/features/auth/presentation/Profilepage.dart';
import 'package:prenova/features/doctor_cons/presentation/doctor_consultation.dart';
import 'package:prenova/features/dashboard/presentation/contraction_timer.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final authservice = AuthService();

  @override
  Widget build(BuildContext context) {
    final userEmail = authservice.getCurrentUserEmail() ?? "No email found";
    String username = userEmail.split('@')[0];

    final List<Map<String, dynamic>> dashboardItems = [
      {
        'title': 'Fetal Health Monitoring',
        'icon': LucideIcons.baby,
        'onPressed': () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => PostFetalHealthScreen()));
        }
      },
      {
        'title': 'Vitals Monitoring',
        'icon': LucideIcons.heartPulse,
        'onPressed': () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => PregnancyRiskScreen()));
        }
      },
      {
        'title': 'Kick Tracker',
        'icon': LucideIcons.footprints,
        'onPressed': () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => KickTrackerScreen()));
        }
      },
      {
        'title': 'Contraction Tracker',
        'icon': LucideIcons.timer,
        'onPressed': () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ContractionTrackerScreen()));
        }
      },
    ];

    final List<Widget> bottomNavScreens = [
      PregnancyChatScreen(),
      PregnancyDietScreen(),
      DoctorConsultationPage(),
      MedicalDocumentsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30)),
        centerTitle: true,
        backgroundColor: AppPallete.gradient1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle, size: 42),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => ProfilePage()));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Hello, $username 👋",
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: AppPallete.textColor)),
            SizedBox(height: 8),
            Text("What would you like to do today?",
                style: TextStyle(fontSize: 20, color: AppPallete.textColor)),
            SizedBox(height: 30),
            SizedBox(height: 80),
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
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color: AppPallete.gradient1,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppPallete.gradient2.withOpacity(0.7),
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(dashboardItems[index]['icon'],
                              size: 40, color: AppPallete.gradient3),
                          SizedBox(height: 10),
                          Text(
                            dashboardItems[index]['title'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              height: 5,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => bottomNavScreens[index],
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: AppPallete.accentFgColor,
        selectedItemColor: AppPallete.gradient1,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.bot),
            label: 'Ask Prenova',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.utensils),
            label: 'Diet Plan',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.stethoscope),
            label: 'Doctor',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.file),
            label: 'Upload Docs',
          ),
        ],
      ),
    );
  }
}
