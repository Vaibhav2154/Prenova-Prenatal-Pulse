import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prenova/core/theme/app_pallete.dart';
import 'package:prenova/features/dashboard/presentation/dashboard.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  _OnboardingPageState createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final SupabaseClient supabase = Supabase.instance.client;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController trimesterController = TextEditingController();
  final TextEditingController dueDateController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkIfUserExists();
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
    if (usernameController.text.isEmpty ||
        heightController.text.isEmpty ||
        weightController.text.isEmpty ||
        ageController.text.isEmpty ||
        trimesterController.text.isEmpty ||
        dueDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
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
        'expected_due_date': dueDateController.text, // Saving expected due date
      });

      // Navigate only if no error occurs
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen()),
      );
    } catch (e) {
      print("Database Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  // Show date picker for due date selection
  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime initialDate = DateTime.now();
    final DateTime firstDate = DateTime(
      initialDate.year,
      initialDate.month - 10,
      initialDate.day,
    );
    final DateTime lastDate = DateTime(
      initialDate.year,
      initialDate.month + 10,
      initialDate.day,
    );

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
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppPallete.gradient1,
              ),
            ),
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
    return Scaffold(
      backgroundColor: AppPallete.backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Onboarding",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppPallete.gradient1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField("Full name", usernameController),
            _buildTextField("Height (cm)", heightController, isNumber: true),
            _buildTextField("Weight (kg)", weightController, isNumber: true),
            _buildTextField("Age", ageController, isNumber: true),
            _buildTextField("Pregnancy Trimester", trimesterController,
                isNumber: true),

            // Due Date Picker Field
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                style: TextStyle(color: AppPallete.textColor),
                controller: dueDateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Expected Due Date",
                  labelStyle: TextStyle(color: Colors.black),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  fillColor: Colors.white,
                  filled: true,
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () => _selectDueDate(context),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _saveUserData,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: AppPallete.gradient1,
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "Save & Continue",
                        style:
                            GoogleFonts.lato(fontSize: 18, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Reusable Input Field
  Widget _buildTextField(String label, TextEditingController controller,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,

          labelStyle: TextStyle(color: Colors.black),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          // fillColor: Colors,
          // filled: true,
        ),
        style: TextStyle(color: AppPallete.textColor),
      ),
    );
  }
}
