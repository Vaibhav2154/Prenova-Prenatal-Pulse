import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class DoctorConsultationPage extends StatelessWidget {
  final List<Map<String, String>> doctors = [
    {
      'name': 'Dr. Aisha Patel',
      'specialization': 'Gynecologist',
      'image': 'https://static.vecteezy.com/system/resources/thumbnails/028/287/555/small/an-indian-young-female-doctor-isolated-on-green-ai-generated-photo.jpg',
      'phone': '+919876543210', // Replace with actual numbers
      'whatsapp': '+919876543210', // Replace with actual numbers
    },
    {
      'name': 'Dr. Rohan Mehta',
      'specialization': 'Obstetrician',
      'image': 'https://static.vecteezy.com/system/resources/thumbnails/026/375/249/small/ai-generative-portrait-of-confident-male-doctor-in-white-coat-and-stethoscope-standing-with-arms-crossed-and-looking-at-camera-photo.jpg',
      'phone': '+919812345678',
      'whatsapp': '+919812345678',
    },
    {
      'name': 'Dr. Priya Sharma',
      'specialization': 'Fetal Medicine Specialist',
      'image': 'https://png.pngtree.com/png-clipart/20240302/original/pngtree-indian-lady-doctor-png-image_14479572.png',
      'phone': '+919834567890',
      'whatsapp': '+919834567890',
    },
  ];

  // Function to make a phone call
  void _makePhoneCall(String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      print('Could not launch $url');
    }
  }

  // Function to initiate WhatsApp video call
  void _startWhatsAppCall(String phoneNumber) async {
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
      appBar: AppBar(
        title: Text('Doctor Consultation', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: doctors.length,
          itemBuilder: (context, index) {
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                contentPadding: EdgeInsets.all(12),
                leading: CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(doctors[index]['image']!),
                ),
                title: Text(
                  doctors[index]['name']!,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  doctors[index]['specialization']!,
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(LucideIcons.phoneCall, color: Colors.green),
                      onPressed: () {
                        _makePhoneCall(doctors[index]['phone']!);
                      },
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.video, color: Colors.blue),
                      onPressed: () {
                        _startWhatsAppCall(doctors[index]['whatsapp']!);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}