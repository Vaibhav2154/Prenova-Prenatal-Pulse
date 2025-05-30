import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:prenova/core/constants/api_contants.dart';
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

  @override
  void initState() {
    super.initState();
    print("🏗️ Initializing PostFetalHealthScreen");
    print("🌐 Base URL: ${ApiContants.baseUrl}");
    print("📋 Feature names: $featureNames");
    print("🎛️ Controllers count: ${controllers.length}");
  }

  Future<void> _postFetalHealthData() async {
    print("🚀 Starting fetal health prediction...");

    setState(() {
      _isLoading = true;
      _responseMessage = "";
    });

    final url = Uri.parse('${ApiContants.baseUrl}/predict_fetal');
    print("📡 API URL: $url");

    try {
      final session = _authService.currentSession;
      print("🔐 Session: $session");

      final token = session?.accessToken;
      print("🎫 Token: ${token != null ? 'Present (${token.substring(0, 20)}...)' : 'Missing'}");

      if (token == null) {
        print("❌ Authentication token is missing");
        setState(() {
          _responseMessage = "Error: Authentication token is missing.";
          _isLoading = false;
        });
        return;
      }

      // Log input values
      final features = controllers
          .map((controller) => double.tryParse(controller.text) ?? 0.0)
          .toList();

      print("📊 Input features: $features");
      print("📊 Features count: ${features.length}");

      final Map<String, dynamic> requestData = {
        "features": features
      };

      print("📤 Request data: ${jsonEncode(requestData)}");

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(requestData),
      );

      print("📥 Response status code: ${response.statusCode}");
      print("📥 Response headers: ${response.headers}");
      print("📥 Response body: ${response.body}");

      final responseData = jsonDecode(response.body);
      print("📊 Parsed response data: $responseData");

      setState(() {
        if (response.statusCode == 200) {
          print("✅ Prediction successful: ${responseData['status']}");
          _responseMessage = "Prediction: ${responseData['status']}";
        } else {
          print("❌ Prediction failed with status ${response.statusCode}");
          _responseMessage =
              "Error: ${responseData['error'] ?? 'Unknown error occurred'}";
        }
      });
    } catch (e) {
      print("💥 Exception occurred: $e");
      print("💥 Exception type: ${e.runtimeType}");
      setState(() {
        _responseMessage = "Error: Failed to connect to the server - $e";
      });
    } finally {
      print("🏁 Prediction process completed");
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
        onChanged: (value) {
          print("📝 Input changed for $label: $value");
        },
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                if (_responseMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      _responseMessage,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
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
