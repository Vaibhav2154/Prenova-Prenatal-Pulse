import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:prenova/core/theme/app_pallete.dart';
import 'dart:convert';
import 'package:prenova/features/auth/auth_service.dart';

class PostFetalHealthScreen extends StatefulWidget {
  @override
  _PostFetalHealthScreenState createState() => _PostFetalHealthScreenState();
}

class _PostFetalHealthScreenState extends State<PostFetalHealthScreen> {
  final AuthService _authService = AuthService();
  final List<TextEditingController> controllers =
      List.generate(15, (index) => TextEditingController());

  String _responseMessage = "";
  bool _isLoading = false;

  final List<String> featureNames = [
    'baseline_value',
    'accelerations',
    'fetal_movement',
    'uterine_contractions',
    'light_decelerations',
    'severe_decelerations',
    'prolonged_decelerations',
    'abnormal_short_term_variability',
    'mean_value_of_short_term_variability',
    'percentage_of_time_with_abnormal_long_term_variability',
    'mean_value_of_long_term_variability',
    'histogram_width',
    'histogram_min',
    'histogram_max',
    'histogram_number_of_peaks'
  ];

  Future<void> _postFetalHealthData() async {
    setState(() {
      _isLoading = true;
      _responseMessage = "";
    });

    final url = Uri.parse('http://localhost:5003/predict_fetal');

    try {
      final session = _authService.currentSession;
      final token = session?.accessToken;
      if (token == null) {
        setState(() {
          _responseMessage = "Error: Authentication token is missing.";
        });
        return;
      }

      final Map<String, dynamic> requestData = {
        "features": controllers
            .map((controller) => double.tryParse(controller.text) ?? 0.0)
            .toList()
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(requestData),
      );

      final responseData = jsonDecode(response.body);

      setState(() {
        if (response.statusCode == 200) {
          _responseMessage = "Prediction: ${responseData['status']}";
        } else {
          _responseMessage =
              "Error: ${responseData['error'] ?? 'Unknown error occurred'}";
        }
      });
    } catch (e) {
      setState(() {
        _responseMessage = "Error: Failed to connect to the server - $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: TextStyle(color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.black),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Post Fetal Health Data'),
        backgroundColor: AppPallete.gradient1,
        shadowColor: AppPallete.gradient1.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ...List.generate(
                  featureNames.length,
                  (index) =>
                      _buildTextField(featureNames[index], controllers[index])),
              SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _postFetalHealthData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPallete.gradient1,
                        padding:
                            EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          Text('Submit Data', style: TextStyle(fontSize: 16,color: AppPallete.backgroundColor)),
                    ),
              SizedBox(height: 20),
              Text(
                _responseMessage,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
