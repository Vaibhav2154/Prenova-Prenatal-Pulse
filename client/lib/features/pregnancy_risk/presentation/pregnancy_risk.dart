import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:prenova/features/auth/auth_service.dart';

class PregnancyRiskScreen extends StatefulWidget {
  @override
  _PregnancyRiskScreenState createState() => _PregnancyRiskScreenState();
}

class _PregnancyRiskScreenState extends State<PregnancyRiskScreen> {
  final TextEditingController ageController = TextEditingController();
  final TextEditingController systolicBPController = TextEditingController();
  final TextEditingController diastolicBPController = TextEditingController();
  final TextEditingController bloodGlucoseController = TextEditingController();
  final TextEditingController bodyTempController = TextEditingController();
  final TextEditingController heartRateController = TextEditingController();
  final AuthService _authService = AuthService();

  String _prediction = "";
  bool _isLoading = false;

  Future<void> _predict() async {
    setState(() {
      _isLoading = true;
      _prediction = "";
    });

    final url = Uri.parse('http://localhost:5003/predict_maternal');
    try {
      final session = _authService.currentSession;
      final token = session?.accessToken;
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json",'Authorization':'Bearer $token'},
        body: jsonEncode({
          "age": double.tryParse(ageController.text) ?? 0.0,
          "systolic_bp": double.tryParse(systolicBPController.text) ?? 0.0,
          "diastolic_bp": double.tryParse(diastolicBPController.text) ?? 0.0,
          "blood_glucose": double.tryParse(bloodGlucoseController.text) ?? 0.0,
          "body_temp": double.tryParse(bodyTempController.text) ?? 0.0,
          "heart_rate": double.tryParse(heartRateController.text) ?? 0.0,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data.containsKey('prediction')) {
          setState(() {
            _prediction = "Predicted Risk Level: ${data['prediction']}";
          });
        } else {
          setState(() {
            _prediction = "Error: Unexpected response format";
          });
        }
      } else {
        setState(() {
          _prediction = "Error: ${response.statusCode} - ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _prediction = "Error: Failed to connect to the server";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearFields() {
    ageController.clear();
    systolicBPController.clear();
    diastolicBPController.clear();
    bloodGlucoseController.clear();
    bodyTempController.clear();
    heartRateController.clear();
    setState(() {
      _prediction = "";
    });
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Focus(
        child: Builder(
          builder: (context) {
            final isFocused = Focus.of(context).hasFocus;
            return TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.grey[900],
                prefixIcon: Icon(Icons.health_and_safety, color: Colors.pinkAccent),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey[700]!, width: 1.2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.pinkAccent, width: 2),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pregnancy Risk Detection', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.pinkAccent,
        elevation: 5,
        shadowColor: Colors.pinkAccent.withOpacity(0.5),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTextField('Age (years)', ageController),
            _buildTextField('Systolic BP (mmHg)', systolicBPController),
            _buildTextField('Diastolic BP (mmHg)', diastolicBPController),
            _buildTextField('Blood Glucose (mg/dL)', bloodGlucoseController),
            _buildTextField('Body Temperature (°F)', bodyTempController),
            _buildTextField('Heart Rate (bpm)', heartRateController),
            SizedBox(height: 20),

            _isLoading
                ? CircularProgressIndicator(color: Colors.pinkAccent)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          backgroundColor: Colors.pinkAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _predict,
                        child: Text('Predict Risk', style: TextStyle(fontSize: 16)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          backgroundColor: Colors.grey[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _clearFields,
                        child: Text('Clear', style: TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ],
                  ),
            SizedBox(height: 20),
            Text(
              _prediction,
              style: TextStyle(fontSize: 18, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white, // Keeping the dark theme
    );
  }
}