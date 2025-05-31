import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:prenova/core/theme/app_pallete.dart';
import 'package:prenova/core/widgets/fancy_dropdown.dart';
import 'package:prenova/features/medicine_tracker/models/medication_model.dart';
import 'package:prenova/features/medicine_tracker/services/medication_storage_service.dart';
import 'package:prenova/features/medicine_tracker/presentation/medicine_tracker_screen.dart';
import 'package:prenova/features/medicine_tracker/presentation/add_medication_screen.dart';
import 'package:prenova/features/doctor_cons/presentation/doctor_consultation.dart';
import 'package:prenova/features/MedicalDocuments/medical_documents.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ServicesModal {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ServicesBottomSheet(),
    );
  }
}

class ServicesBottomSheet extends StatefulWidget {
  @override
  _ServicesBottomSheetState createState() => _ServicesBottomSheetState();
}

class _ServicesBottomSheetState extends State<ServicesBottomSheet>
    with TickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;
  final MedicationStorageService _storageService = MedicationStorageService();

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  List<Medication> _medications = [];
  List<Map<String, dynamic>> _doctors = [];
  List<String> _documents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _loadData();
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadMedications(),
      _loadDoctors(),
      _loadDocuments(),
    ]);
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadMedications() async {
    try {
      final medications = await _storageService.getMedications();
      setState(() {
        _medications = medications.where((med) => med.isActive).take(3).toList();
      });
    } catch (e) {
      print('Error loading medications: $e');
    }
  }

  Future<void> _loadDoctors() async {
    try {
      final response = await supabase.from('doctors').select('*').limit(3);
      setState(() {
        _doctors = response.map<Map<String, dynamic>>((doc) => doc).toList();
      });
    } catch (e) {
      print('Error loading doctors: $e');
    }
  }

  Future<void> _loadDocuments() async {
    try {
      final files = await supabase.storage.from('medical_docs').list();
      final validFiles = files.where((file) => !file.name.startsWith('.')).take(3).toList();
      setState(() {
        _documents = validFiles.map((file) => file.name).toList();
      });
    } catch (e) {
      print('Error loading documents: $e');
    }
  }

  void _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: AppPallete.backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppPallete.gradient1, AppPallete.gradient2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Icon(Icons.health_and_safety, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Health Services',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(LucideIcons.x, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          FancyDropdown(
                            title: 'Medicine Tracker',
                            icon: LucideIcons.pill,
                            color: AppPallete.gradient1,
                            items: _medications.map((med) => DropdownItem(
                              title: med.name,
                              subtitle: '${med.dosage} • ${med.frequency}',
                              icon: LucideIcons.clock,
                              trailing: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: med.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  med.isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    color: med.isActive ? Colors.green : Colors.red,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )).toList(),
                            onViewAll: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => MedicineTrackerScreen()),
                              );
                            },
                          ),
                          FancyDropdown(
                            title: 'Doctor Consultation',
                            icon: LucideIcons.stethoscope,
                            color: AppPallete.gradient2,
                            items: _doctors.map((doctor) => DropdownItem(
                              title: doctor['name'] ?? 'Unknown',
                              subtitle: doctor['specialization'] ?? '',
                              icon: LucideIcons.user,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (doctor['phone_number'] != null)
                                    IconButton(
                                      onPressed: () => _makePhoneCall(doctor['phone_number']),
                                      icon: Icon(LucideIcons.phone, size: 16, color: AppPallete.gradient2),
                                      constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                                      padding: EdgeInsets.zero,
                                    ),
                                ],
                              ),
                            )).toList(),
                            onViewAll: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => DoctorConsultationPage()),
                              );
                            },
                          ),
                          FancyDropdown(
                            title: 'Medical Documents',
                            icon: LucideIcons.fileText,
                            color: AppPallete.gradient3,
                            items: _documents.map((doc) => DropdownItem(
                              title: doc,
                              subtitle: 'Tap to view',
                              icon: doc.toLowerCase().contains('.pdf') ? LucideIcons.fileText : LucideIcons.image,
                            )).toList(),
                            onViewAll: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => MedicalDocumentsPage()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}