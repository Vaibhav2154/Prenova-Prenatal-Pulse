import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class DoctorConsultationPage extends StatefulWidget {
  const DoctorConsultationPage({super.key});

  @override
  State<DoctorConsultationPage> createState() => _DoctorConsultationPageState();
}

class _DoctorConsultationPageState extends State<DoctorConsultationPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _doctorsFuture;

  @override
  void initState() {
    super.initState();
    _doctorsFuture = _fetchDoctors();
  }

  Future<List<Map<String, dynamic>>> _fetchDoctors() async {
    try {
      final response = await supabase.from('doctors').select('*');

      print("Fetched doctors: $response"); // Debugging print

      if (response.isEmpty) {
        print("No doctors found in the database.");
      }

      return response.map<Map<String, dynamic>>((doc) => doc).toList();
    } catch (error) {
      print("Error fetching doctors: $error");
      return [];
    }
  }

  // Function to make a phone call
  void _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      print('Could not launch $url');
    }
  }

  // Function to initiate WhatsApp video call
  void _startWhatsAppCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;
    final Uri url = Uri.parse('https://wa.me/$phoneNumber?text=Hello%20Doctor,%20I%20would%20like%20to%20consult%20with%20you.');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      print('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Doctor Consultation',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E1E2A), Color(0xFF12121C)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Doctor List
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _doctorsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(
                  child: Text("Error fetching doctors", style: TextStyle(color: Colors.white)),
                );
              }
              final doctors = snapshot.data ?? [];
              if (doctors.isEmpty) {
                return const Center(
                  child: Text("No doctors available", style: TextStyle(color: Colors.white)),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView.builder(
                  itemCount: doctors.length,
                  itemBuilder: (context, index) {
                    final doctor = doctors[index];

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, spreadRadius: 2),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(14),
                        leading: CircleAvatar(
                          radius: 30,
                          backgroundImage: doctor['image'] != null && doctor['image'].isNotEmpty
                              ? NetworkImage(doctor['image'])
                              : const NetworkImage("https://via.placeholder.com/150"), // Placeholder image
                        ),
                        title: Text(
                          doctor['name'] ?? "Unknown",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        subtitle: Text(
                          doctor['specialization'] ?? "Specialization Unknown",
                          style: const TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(LucideIcons.phoneCall, color: Colors.green),
                              onPressed: () {
                                _makePhoneCall(doctor['phone'] ?? "");
                              },
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.video, color: Colors.blue),
                              onPressed: () {
                                _startWhatsAppCall(doctor['whatsapp'] ?? "");
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
