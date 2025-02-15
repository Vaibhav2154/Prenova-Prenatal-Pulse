import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:prenova/core/theme/app_pallete.dart';
import 'package:prenova/features/MedicalDocuments/medical_documents.dart';
import 'package:prenova/features/auth/auth_service.dart';
import 'package:prenova/features/auth/presentation/Profilepage.dart';
import 'package:prenova/features/pregnancy_risk/presentation/pregnancy_risk.dart';
// import 'package:prenova/features/fetal_health/presentation/fetal_health.dart';
// import 'package:prenova/features/pregnancy_risk/presentation/pregnancy_risk.dart';
import 'package:prenova/features/kick_tracker/presentation/kick_tracker.dart';
// import 'package:prenova/features/contraction_timer/presentation/contraction_timer.dart';
import 'package:prenova/features/chatbot/presentation/chatbot.dart';
import 'package:prenova/features/pregnancy_diet_screen/pregnancy_diet_screen.dart';
// import 'package:prenova/features/medical_docs/presentation/upload_docs.dart';
import 'package:prenova/features/doctor_cons/presentation/doctor_consultation.dart';

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
      // {
      //   'title': 'Fetal Health Monitoring',
      //   'icon': LucideIcons.baby,
      //   'onPressed': () {
      //     Navigator.push(
      //         context, MaterialPageRoute(builder: (context) => FetalHealthScreen()));
      //   }
      // },
      {
        'title': 'Vitals Monitoring',
        'icon': LucideIcons.heartPulse,
        'onPressed': () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => PregnancyRiskScreen()));
        }
      },
      {
        'title': 'Kick Tracker',
        'icon': LucideIcons.footprints,
        'onPressed': () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => KickTrackerScreen()));
        }
      },
      // {
      //   'title': 'Contraction Timer',
      //   'icon': LucideIcons.timer,
      //   'onPressed': () {
      //     Navigator.push(
      //         context, MaterialPageRoute(builder: (context) => ContractionTimerScreen()));
      //   }
      // },
    ];

    final List<Widget> bottomNavScreens = [
      PregnancyChatScreen(),
      PregnancyDietScreen(),
      MedicalDocumentsPage(),
      DoctorConsultationPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.pinkAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle, size: 32),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage()));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Hello, $username 👋",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("What would you like to do today?",
                style: TextStyle(fontSize: 20, color: Colors.grey[700])),
            SizedBox(height: 30),
            
            Row(
              children: [
                Text("Week 19 - 3rd Trimester",
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                TextButton(onPressed: (){}, child: Text('View Progress')),
              ],
            ),
            SizedBox(height: 8),
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
                        color: AppPallete.borderColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pinkAccent.withOpacity(0.2),
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: Offset(0, 6),
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
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
        selectedItemColor: Colors.pinkAccent,
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