import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:prenova/core/theme/app_pallete.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not initiate call")),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not open WhatsApp")),
      );
    }
  }

  // Function to add a new doctor
  Future<void> _showAddDoctorDialog() async {
    final nameController = TextEditingController();
    final specializationController = TextEditingController();
    final detailsController = TextEditingController();
    final phoneController = TextEditingController();
    final whatsappController = TextEditingController();
    final imageController = TextEditingController();
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Add New Doctor',
            style: TextStyle(
              color: AppPallete.gradient1,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(LucideIcons.user, color: AppPallete.gradient1),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: specializationController,
                  decoration: InputDecoration(
                    labelText: 'Specialization',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(LucideIcons.stethoscope, color: AppPallete.gradient1),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: detailsController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Details',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(LucideIcons.fileText, color: AppPallete.gradient1),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(LucideIcons.phone, color: AppPallete.gradient1),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: whatsappController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'WhatsApp',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(LucideIcons.messageCircle, color: AppPallete.gradient1),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: imageController,
                  decoration: InputDecoration(
                    labelText: 'Image URL (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(LucideIcons.image, color: AppPallete.gradient1),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppPallete.greyColor),
              ),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (nameController.text.isEmpty ||
                          specializationController.text.isEmpty ||
                          phoneController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Please fill all required fields")),
                        );
                        return;
                      }

                      setState(() {
                        isLoading = true;
                      });

                      try {
                        await supabase.from('doctors').insert({
                          'name': nameController.text,
                          'specialization': specializationController.text,
                          'details': detailsController.text,
                          'phone': phoneController.text,
                          'whatsapp': whatsappController.text.isNotEmpty
                              ? whatsappController.text
                              : phoneController.text,
                          'image': imageController.text,
                        });

                        if (mounted) {
                          Navigator.pop(context);
                          // Refresh the doctors list
                          this.setState(() {
                            _doctorsFuture = _fetchDoctors();
                          });
                        }
                      } catch (error) {
                        print("Error adding doctor: $error");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Failed to add doctor")),
                        );
                      } finally {
                        if (mounted) {
                          setState(() {
                            isLoading = false;
                          });
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPallete.gradient1,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Add',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Doctor Consultation',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: AppPallete.gradient1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        elevation: 4,
        shadowColor: Colors.black38,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDoctorDialog,
        backgroundColor: AppPallete.gradient1,
        child: Icon(LucideIcons.userPlus, color: Colors.white),
        tooltip: 'Add New Doctor',
      ),
      body: Container(
        decoration: BoxDecoration(
          color: AppPallete.backgroundColor,
        ),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _doctorsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppPallete.gradient1,
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.alertCircle, size: 60, color: AppPallete.errorColor),
                    const SizedBox(height: 16),
                    Text(
                      "Error fetching doctors",
                      style: TextStyle(fontSize: 18, color: AppPallete.textColor),
                    ),
                  ],
                ),
              );
            }
            
            final doctors = snapshot.data ?? [];
            if (doctors.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.userX, size: 60, color: AppPallete.gradient2),
                    const SizedBox(height: 16),
                    Text(
                      "No doctors available",
                      style: TextStyle(fontSize: 18, color: AppPallete.textColor),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _showAddDoctorDialog,
                      icon: Icon(LucideIcons.userPlus, color: Colors.white),
                      label: Text("Add Doctor", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPallete.gradient1,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppPallete.greyColor.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundColor: AppPallete.gradient3.withOpacity(0.2),
                        backgroundImage: doctor['image'] != null && doctor['image'].isNotEmpty
                            ? NetworkImage(doctor['image'])
                            : null,
                        child: doctor['image'] == null || doctor['image'].isEmpty 
                            ? Icon(Icons.person, color: AppPallete.gradient1, size: 30)
                            : null,
                      ),
                      title: Text(
                        doctor['name'] ?? "Unknown",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppPallete.textColor),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            doctor['specialization'] ?? "Specialization Unknown",
                            style: TextStyle(fontSize: 14, color: AppPallete.textColor.withOpacity(0.7)),
                          ),
                          if (doctor['details'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                doctor['details'],
                                style: TextStyle(fontSize: 12, color: AppPallete.textColor.withOpacity(0.6)),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              _makePhoneCall(doctor['phone'] ?? "");
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(12),
                            ),
                            child: const Icon(LucideIcons.phoneCall, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              _startWhatsAppCall(doctor['whatsapp'] ?? "");
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppPallete.gradient1,
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(12),
                            ),
                            child: const Icon(LucideIcons.video, color: Colors.white, size: 22),
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
      ),
    );
  }
}
