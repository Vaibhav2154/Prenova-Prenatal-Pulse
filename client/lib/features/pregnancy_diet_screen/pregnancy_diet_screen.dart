import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:prenova/core/constants/api_contants.dart';
import 'package:prenova/core/theme/app_pallete.dart';
import 'package:prenova/features/auth/auth_service.dart';

class PregnancyDietScreen extends StatefulWidget {
  @override
  _PregnancyDietScreenState createState() => _PregnancyDietScreenState();
}

class _PregnancyDietScreenState extends State<PregnancyDietScreen> {
  final TextEditingController weightController = TextEditingController();
  final TextEditingController healthController = TextEditingController();
  final TextEditingController dietController = TextEditingController();
  final AuthService _authService = AuthService();
  String trimester = "First"; // Default selection
  String dietPlan = "";
  bool isLoading = false;

  Future<void> fetchPregnancyDiet() async {
    setState(() {
      isLoading = true;
      dietPlan = ""; // Clear previous results
    });

    try {
      final session = _authService.currentSession;
      final token = session?.accessToken;

      final response = await http.post(
        Uri.parse("${ApiContants.baseUrl}/diet_plan"),
        headers: {"Content-Type": "application/json", 'Authorization': 'Bearer $token'},
        body: jsonEncode({
          "trimester": trimester,
          "weight": weightController.text.trim(),
          "health_conditions": healthController.text.trim(),
          "dietary_preference": dietController.text.trim(),
        }),
      );
      log(response.body);
      if (response.statusCode == 200) {
        setState(() {
          dietPlan = jsonDecode(response.body)["diet_plan"] ?? "No diet plan received.";
          dietPlan = dietPlan.replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '');
        });
      } else {
        setState(() {
          dietPlan = "Failed to fetch recommendations. Please try again.";
        });
      }
    } catch (e) {
      setState(() {
        dietPlan = "Error: ${e.toString()}";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(Icons.fastfood, color: AppPallete.gradient1),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppPallete.gradient1, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppPallete.backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPallete.gradient1, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: trimester,
          dropdownColor: AppPallete.backgroundColor,
          icon: Icon(Icons.arrow_drop_down, color: AppPallete.gradient1),
          style: TextStyle(color: Colors.black, fontSize: 16),
          isExpanded: true,
          items: ["First", "Second", "Third"]
              .map((e) => DropdownMenuItem(value: e, child: Text("$e Trimester")))
              .toList(),
          onChanged: (value) {
            setState(() {
              trimester = value!;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pregnancy Diet Plan", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: AppPallete.gradient1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Select Trimester:", 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppPallete.textColor)),
              SizedBox(height: 8),
              _buildDropdown(),
              SizedBox(height: 10),
          
              _buildTextField("Weight (kg)", weightController),
              _buildTextField("Health Conditions (if any)", healthController),
              _buildTextField("Dietary Preference", dietController),
          
              SizedBox(height: 20),
          
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      backgroundColor: AppPallete.gradient1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isLoading ? null : fetchPregnancyDiet,
                    child: isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text("Get Diet Plan", style: TextStyle(fontSize: 16, color: AppPallete.backgroundColor)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      backgroundColor: Colors.grey[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        weightController.clear();
                        healthController.clear();
                        dietController.clear();
                        dietPlan = "";
                      });
                    },
                    child: Text("Clear", style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ],
              ),
          
              SizedBox(height: 20),
          
              Card(
                elevation: 5,
                color: Colors.grey[900],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: dietPlan.isNotEmpty
                      ? MarkdownBody(
                          data: dietPlan,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(fontSize: 16, color: Colors.white),
                            strong: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
                          ),
                        )
                      : Text(
                          "Your diet recommendations will appear here.",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: AppPallete.backgroundColor, // Keeping the dark theme
    );
  }
}