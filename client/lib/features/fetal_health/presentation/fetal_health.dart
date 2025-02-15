import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:prenova/features/auth/auth_service.dart';

class PostFetalHealthScreen extends StatefulWidget {
  @override
  _PostFetalHealthScreenState createState() => _PostFetalHealthScreenState();
}

class _PostFetalHealthScreenState extends State<PostFetalHealthScreen> {
  final TextEditingController baselineValueController = TextEditingController();
  final TextEditingController accelerationsController = TextEditingController();
  final TextEditingController fetalMovementController = TextEditingController();
  final AuthService _authService = AuthService();

  String _responseMessage = "";
  bool _isLoading = false;

  Future<void> _postFetalHealthData() async {
    setState(() {
      _isLoading = true;
      _responseMessage = "";
    });

    final url = Uri.parse('http://localhost:5003/predict_fetal');

    try {
      final session = _authService.currentSession;
      final token = session?.accessToken;
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json','Authorization':'Bearer $token'},
        body: jsonEncode({
          "baseline value": double.tryParse(baselineValueController.text) ?? 0.0,
          "accelerations": double.tryParse(accelerationsController.text) ?? 0.0,
          "fetal_movement": double.tryParse(fetalMovementController.text) ?? 0.0,
        }),
      );

      final responseData = jsonDecode(response.body);

      setState(() {
        if (response.statusCode == 200) {
          _responseMessage = "Response: ${responseData['message']}";
        } else {
          _responseMessage = "Error: ${responseData['error'] ?? 'Unknown error occurred'}";
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
        decoration: InputDecoration(
          labelText: label,
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
      appBar: AppBar(title: Text('Post Fetal Health Data')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTextField('Baseline Value', baselineValueController),
            _buildTextField('Accelerations', accelerationsController),
            _buildTextField('Fetal Movement', fetalMovementController),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _postFetalHealthData,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Submit Data', style: TextStyle(fontSize: 16)),
                  ),
            SizedBox(height: 20),
            Text(
              _responseMessage,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
