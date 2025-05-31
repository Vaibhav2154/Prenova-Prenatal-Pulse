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

class _DoctorConsultationPageState extends State<DoctorConsultationPage> 
    with TickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _doctorsFuture;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _doctorsFuture = _fetchDoctors();
    
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchDoctors() async {
    try {
      final response = await supabase.from('doctors').select('*');

      print("Fetched doctors: $response");

      if (response.isEmpty) {
        print("No doctors found in the database.");
      }

      return response.map<Map<String, dynamic>>((doc) => doc).toList();
    } catch (error) {
      print("Error fetching doctors: $error");
      return [];
    }
  }

  void _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      print('Could not launch $url');
      _showSnackBar("Could not initiate call", AppPallete.errorColor);
    }
  }

  void _startWhatsAppChat(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      _showSnackBar("Phone number not available", AppPallete.errorColor);
      return;
    }

    String cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (cleanedNumber.startsWith('0')) {
      cleanedNumber = cleanedNumber.substring(1);
    }
    
    if (cleanedNumber.startsWith('+91')) {
      cleanedNumber = cleanedNumber.substring(3);
    } else if (cleanedNumber.startsWith('91') && cleanedNumber.length > 10) {
      cleanedNumber = cleanedNumber.substring(2);
    }
    
    if (cleanedNumber.length == 10) {
      cleanedNumber = '91$cleanedNumber';
    } else if (!cleanedNumber.startsWith('91')) {
      cleanedNumber = '91$cleanedNumber';
    }

    print('Original: $phoneNumber, Cleaned: $cleanedNumber');

    final List<String> whatsappUrls = [
      'whatsapp://send?phone=$cleanedNumber&text=${Uri.encodeComponent("Hello Doctor, I would like to consult with you.")}',
      'https://wa.me/$cleanedNumber?text=${Uri.encodeComponent("Hello Doctor, I would like to consult with you.")}',
      'https://api.whatsapp.com/send?phone=$cleanedNumber&text=${Uri.encodeComponent("Hello Doctor, I would like to consult with you.")}'
    ];

    bool launched = false;
    
    for (String urlString in whatsappUrls) {
      try {
        final Uri url = Uri.parse(urlString);
        print('Trying URL: $urlString');
        
        if (await canLaunchUrl(url)) {
          await launchUrl(
            url,
            mode: LaunchMode.externalApplication,
          );
          launched = true;
          print('Successfully launched: $urlString');
          break;
        }
      } catch (e) {
        print('Failed to launch $urlString: $e');
      }
    }

    if (!launched) {
      try {
        final Uri whatsappUri = Uri.parse('whatsapp://');
        if (await canLaunchUrl(whatsappUri)) {
          await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
          _showSnackBar("WhatsApp opened. Please search for: $cleanedNumber", AppPallete.gradient1);
        } else {
          throw Exception('WhatsApp not found');
        }
      } catch (e) {
        print('Could not launch WhatsApp: $e');
        _showSnackBar("WhatsApp not found. Please install WhatsApp.", AppPallete.errorColor);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

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
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppPallete.gradient1.withOpacity(0.1), AppPallete.gradient2.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(LucideIcons.userPlus, color: AppPallete.gradient1),
              ),
              SizedBox(width: 12),
              Text(
                'Add New Doctor',
                style: TextStyle(
                  color: AppPallete.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogTextField(nameController, 'Name', LucideIcons.user),
                SizedBox(height: 16),
                _buildDialogTextField(specializationController, 'Specialization', LucideIcons.stethoscope),
                SizedBox(height: 16),
                _buildDialogTextField(detailsController, 'Details', LucideIcons.fileText, maxLines: 2),
                SizedBox(height: 16),
                _buildDialogTextField(phoneController, 'Phone', LucideIcons.phone, keyboardType: TextInputType.phone),
                SizedBox(height: 16),
                _buildDialogTextField(whatsappController, 'WhatsApp', LucideIcons.messageCircle, keyboardType: TextInputType.phone),
                SizedBox(height: 16),
                _buildDialogTextField(imageController, 'Image URL (optional)', LucideIcons.image),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppPallete.textColor.withOpacity(0.6), fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppPallete.gradient1, AppPallete.gradient2],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppPallete.gradient1.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isLoading ? null : () async {
                    if (nameController.text.isEmpty ||
                        specializationController.text.isEmpty ||
                        phoneController.text.isEmpty) {
                      _showSnackBar("Please fill all required fields", AppPallete.errorColor);
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
                        this.setState(() {
                          _doctorsFuture = _fetchDoctors();
                        });
                        _showSnackBar("Doctor added successfully!", AppPallete.gradient1);
                      }
                    } catch (error) {
                      print("Error adding doctor: $error");
                      _showSnackBar("Failed to add doctor", AppPallete.errorColor);
                    } finally {
                      if (mounted) {
                        setState(() {
                          isLoading = false;
                        });
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                            'Add Doctor',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(
        color: AppPallete.textColor,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppPallete.gradient1, size: 20),
        labelStyle: TextStyle(
          color: AppPallete.gradient1,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppPallete.gradient1.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppPallete.gradient1,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppPallete.errorColor,
            width: 2,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Doctor Consultation',
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppPallete.gradient1, AppPallete.gradient2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppPallete.gradient1.withOpacity(0.4),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _showAddDoctorDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Icon(LucideIcons.userPlus, color: Colors.white, size: 28),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppPallete.backgroundColor,
              AppPallete.gradient1.withOpacity(0.03),
              AppPallete.backgroundColor,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _doctorsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: AppPallete.gradient1,
                          strokeWidth: 3,
                        ),
                        SizedBox(height: 20),
                        Text(
                          "Loading doctors...",
                          style: TextStyle(
                            color: AppPallete.textColor.withOpacity(0.7),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                if (snapshot.hasError) {
                  return _buildErrorState();
                }
                
                final doctors = snapshot.data ?? [];
                if (doctors.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildDoctorsList(doctors);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: EdgeInsets.all(32),
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppPallete.gradient1.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppPallete.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                LucideIcons.alertCircle,
                size: 48,
                color: AppPallete.errorColor,
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Error Loading Doctors",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppPallete.textColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Something went wrong while fetching the doctors list",
              style: TextStyle(
                fontSize: 14,
                color: AppPallete.textColor.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppPallete.gradient1, AppPallete.gradient2],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _doctorsFuture = _fetchDoctors();
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.refreshCw, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          "Retry",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: EdgeInsets.all(32),
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppPallete.gradient1.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                LucideIcons.stethoscope,
                size: 64,
                color: AppPallete.gradient1,
              ),
            ),
            SizedBox(height: 24),
            Text(
              "No Doctors Available",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppPallete.textColor,
              ),
            ),
            SizedBox(height: 12),
            Text(
              "Add your first doctor to start consultations and keep track of your healthcare providers",
              style: TextStyle(
                fontSize: 16,
                color: AppPallete.textColor.withOpacity(0.7),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppPallete.gradient1, AppPallete.gradient2],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppPallete.gradient1.withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showAddDoctorDialog,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.userPlus, color: Colors.white, size: 20),
                        SizedBox(width: 12),
                        Text(
                          "Add Your First Doctor",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorsList(List<Map<String, dynamic>> doctors) {
    return Padding(
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
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppPallete.gradient1.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.stethoscope,
                    color: AppPallete.gradient1,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Your Healthcare Providers",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppPallete.textColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "${doctors.length} doctor${doctors.length == 1 ? '' : 's'} available for consultation",
                        style: TextStyle(
                          fontSize: 14,
                          color: AppPallete.textColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              physics: BouncingScrollPhysics(),
              itemCount: doctors.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppPallete.gradient1.withOpacity(0.08),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _buildDoctorCard(doctors[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppPallete.gradient1.withOpacity(0.8),
                      AppPallete.gradient2.withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppPallete.gradient1.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: doctor['image'] != null && doctor['image'].isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          doctor['image'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              LucideIcons.userCircle,
                              color: Colors.white,
                              size: 32,
                            );
                          },
                        ),
                      )
                    : Icon(
                        LucideIcons.userCircle,
                        color: Colors.white,
                        size: 32,
                      ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor['name'] ?? "Unknown",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppPallete.textColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppPallete.gradient1.withOpacity(0.1),
                            AppPallete.gradient2.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        doctor['specialization'] ?? "Specialization Unknown",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppPallete.gradient1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (doctor['details'] != null && doctor['details'].isNotEmpty) ...[
                      SizedBox(height: 8),
                      Text(
                        doctor['details'],
                        style: TextStyle(
                          fontSize: 14,
                          color: AppPallete.textColor.withOpacity(0.7),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade600],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _makePhoneCall(doctor['phone']?.toString() ?? ""),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.phone, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              "Call",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF25D366), Color(0xFF1DA851)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF25D366).withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _startWhatsAppChat(
                        (doctor['whatsapp'] ?? doctor['phone'])?.toString() ?? "",
                      ),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.messageCircle, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              "WhatsApp",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}