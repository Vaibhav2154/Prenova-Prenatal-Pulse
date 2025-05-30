import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:prenova/core/theme/app_pallete.dart';
import 'package:prenova/features/MedicalDocuments/medical_documents.dart';
import 'package:prenova/features/doctor_cons/presentation/doctor_consultation.dart';
import 'package:prenova/features/medicine_tracker/presentation/medicine_tracker_screen.dart';

class ServicesHub extends StatefulWidget {
  const ServicesHub({super.key});

  @override
  State<ServicesHub> createState() => _ServicesHubState();
}

class _ServicesHubState extends State<ServicesHub> 
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> services = [
      {
        'title': 'Doctor\nConsultation',
        'subtitle': 'Connect with healthcare providers',
        'icon': LucideIcons.stethoscope,
        'color': AppPallete.gradient1,
        'onPressed': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DoctorConsultationPage()),
          );
        }
      },
      {
        'title': 'Medical\nDocuments',
        'subtitle': 'Store and manage your documents',
        'icon': LucideIcons.fileText,
        'color': AppPallete.gradient2,
        'onPressed': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MedicalDocumentsPage()),
          );
        }
      },
      {
        'title': 'Medicine\nTracker',
        'subtitle': 'Track your medications',
        'icon': LucideIcons.pill,
        'color': AppPallete.gradient3,
        'onPressed': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MedicineTrackerScreen()),
          );
        }
      },
    ];

    return Scaffold(
      backgroundColor: AppPallete.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Health Services',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppPallete.gradient1, AppPallete.gradient2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: AppPallete.gradient1.withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppPallete.gradient1.withOpacity(0.1),
                      AppPallete.gradient2.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppPallete.gradient1.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.health_and_safety, color: AppPallete.gradient1, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Comprehensive Care',
                            style: TextStyle(
                              color: AppPallete.textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Access all your health services in one place',
                            style: TextStyle(
                              color: AppPallete.textColor.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),
              Text(
                'Available Services',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppPallete.textColor,
                ),
              ),
              SizedBox(height: 20),
              ...services.asMap().entries.map((entry) {
                final index = entry.key;
                final service = entry.value;
                return TweenAnimationBuilder(
                  duration: Duration(milliseconds: 600 + (index * 150)),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, double value, child) {
                    return Transform.translate(
                      offset: Offset(0, 50 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: _buildServiceCard(service),
                      ),
                    );
                  },
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: service['color'].withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 2,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: service['onPressed'],
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        service['color'].withOpacity(0.1),
                        service['color'].withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    service['icon'],
                    size: 32,
                    color: service['color'],
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service['title'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppPallete.textColor,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        service['subtitle'],
                        style: TextStyle(
                          fontSize: 14,
                          color: AppPallete.textColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                Icon(
                  LucideIcons.arrowRight,
                  color: service['color'],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}