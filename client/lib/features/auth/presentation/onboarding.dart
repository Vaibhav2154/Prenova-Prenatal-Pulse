import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prenova/core/theme/app_pallete.dart';
import 'package:prenova/core/theme/starry_bg.dart';
import 'package:prenova/features/dashboard/presentation/dashboard.dart';
import 'package:lucide_icons/lucide_icons.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  _OnboardingPageState createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> with TickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController trimesterController = TextEditingController();
  final TextEditingController dueDateController = TextEditingController();

  bool isLoading = false;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    
    _checkIfUserExists();
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    usernameController.dispose();
    heightController.dispose();
    weightController.dispose();
    ageController.dispose();
    trimesterController.dispose();
    dueDateController.dispose();
    super.dispose();
  }

  // Check if user data exists
  Future<void> _checkIfUserExists() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response = await supabase
        .from('profiles')
        .select('user_name')
        .eq('UID', user.id)
        .maybeSingle();

    if (response != null && response['user_name'] != null) {
      // User already completed onboarding, redirect to dashboard
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => DashboardScreen()));
    }
  }

  // Save User Data
  Future<void> _saveUserData() async {
    if (!_validateInputs()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('profiles').upsert({
        'UID': user.id,
        'user_name': usernameController.text,
        'current_height': int.parse(heightController.text),
        'current_weight': int.parse(weightController.text),
        'age': int.parse(ageController.text),
        'pregnancy_trimester': int.parse(trimesterController.text),
        'expected_due_date': dueDateController.text,
      });

      // Navigate only if no error occurs
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen()),
      );
    } catch (e) {
      print("Database Error: $e");
      _showErrorSnackBar("Error saving data: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  bool _validateInputs() {
    if (usernameController.text.isEmpty ||
        heightController.text.isEmpty ||
        weightController.text.isEmpty ||
        ageController.text.isEmpty ||
        trimesterController.text.isEmpty ||
        dueDateController.text.isEmpty) {
      _showErrorSnackBar("Please fill all fields");
      return false;
    }

    // Validate height
    final height = int.tryParse(heightController.text);
    if (height == null || height < 100 || height > 250) {
      _showErrorSnackBar("Height should be between 100-250 cm");
      return false;
    }

    // Validate weight
    final weight = int.tryParse(weightController.text);
    if (weight == null || weight < 30 || weight > 200) {
      _showErrorSnackBar("Weight should be between 30-200 kg");
      return false;
    }

    // Validate age
    final age = int.tryParse(ageController.text);
    if (age == null || age < 15 || age > 50) {
      _showErrorSnackBar("Age should be between 15-50 years");
      return false;
    }

    // Validate trimester
    final trimester = int.tryParse(trimesterController.text);
    if (trimester == null || trimester < 1 || trimester > 3) {
      _showErrorSnackBar("Trimester should be 1, 2, or 3");
      return false;
    }

    return true;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppPallete.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  // Show date picker for due date selection
  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime initialDate = DateTime.now().add(Duration(days: 100));
    final DateTime firstDate = DateTime.now();
    final DateTime lastDate = DateTime.now().add(Duration(days: 300));

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppPallete.gradient1,
              onPrimary: Colors.white,
              onSurface: AppPallete.textColor,
              surface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppPallete.gradient1,
                textStyle: GoogleFonts.lato(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        dueDateController.text = pickedDate.toLocal().toString().split(' ')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StarryBackground(
      child: Scaffold(
        backgroundColor: AppPallete.transparentColor,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(
            "Complete Your Profile",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: Container(),
        ),
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    
                    // Welcome header
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(24),
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
                        border: Border.all(
                          color: AppPallete.gradient1.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppPallete.gradient1.withOpacity(0.1),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            LucideIcons.user,
                            size: 48,
                            color: AppPallete.gradient1,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Tell us about yourself",
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppPallete.textColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "This information helps us provide personalized care throughout your pregnancy journey",
                            style: GoogleFonts.lato(
                              fontSize: 14,
                              color: AppPallete.textColor.withOpacity(0.7),
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 32),
                    
                    // Form fields
                    _buildStyledTextField(
                      "Full Name",
                      usernameController,
                      icon: LucideIcons.user,
                      hint: "Enter your full name",
                    ),
                    
                    SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildStyledTextField(
                            "Height",
                            heightController,
                            icon: LucideIcons.ruler,
                            hint: "cm",
                            isNumber: true,
                            suffix: "cm",
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildStyledTextField(
                            "Weight",
                            weightController,
                            icon: LucideIcons.scale,
                            hint: "kg",
                            isNumber: true,
                            suffix: "kg",
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildStyledTextField(
                            "Age",
                            ageController,
                            icon: LucideIcons.calendar,
                            hint: "years",
                            isNumber: true,
                            suffix: "years",
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildStyledTextField(
                            "Trimester",
                            trimesterController,
                            icon: LucideIcons.baby,
                            hint: "1, 2, or 3",
                            isNumber: true,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 20),
                    
                    // Due Date Picker Field
                    _buildDatePickerField(),
                    
                    SizedBox(height: 40),
                    
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: isLoading
                          ? Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppPallete.gradient1, AppPallete.gradient2],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                            )
                          : Container(
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
                                    blurRadius: 20,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _saveUserData,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          LucideIcons.arrowRight,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          "Save & Continue",
                                          style: GoogleFonts.lato(
                                            fontSize: 18,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                    
                    SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStyledTextField(
    String label,
    TextEditingController controller, {
    required IconData icon,
    required String hint,
    bool isNumber = false,
    String? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppPallete.gradient1.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: GoogleFonts.lato(
          color: AppPallete.textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppPallete.gradient1, size: 20),
          suffixText: suffix,
          suffixStyle: GoogleFonts.lato(
            color: AppPallete.textColor.withOpacity(0.6),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          labelStyle: GoogleFonts.lato(
            color: AppPallete.gradient1,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          hintStyle: GoogleFonts.lato(
            color: AppPallete.textColor.withOpacity(0.5),
            fontSize: 14,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppPallete.gradient1.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppPallete.gradient1,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppPallete.errorColor,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppPallete.gradient1.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        style: GoogleFonts.lato(
          color: AppPallete.textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        controller: dueDateController,
        readOnly: true,
        decoration: InputDecoration(
          labelText: "Expected Due Date",
          hintText: "Select your due date",
          prefixIcon: Icon(LucideIcons.calendar, color: AppPallete.gradient1, size: 20),
          suffixIcon: IconButton(
            icon: Icon(
              LucideIcons.calendarDays,
              color: AppPallete.gradient1,
              size: 20,
            ),
            onPressed: () => _selectDueDate(context),
          ),
          labelStyle: GoogleFonts.lato(
            color: AppPallete.gradient1,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          hintStyle: GoogleFonts.lato(
            color: AppPallete.textColor.withOpacity(0.5),
            fontSize: 14,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppPallete.gradient1.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppPallete.gradient1,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}