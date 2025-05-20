import 'package:flutter/material.dart';
import 'package:prenova/core/constants/api_contants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:prenova/core/theme/app_pallete.dart';
import 'dart:convert';
import 'package:prenova/features/auth/auth_service.dart';

class PregnancyRiskScreen extends StatefulWidget {
  @override
  _PregnancyRiskScreenState createState() => _PregnancyRiskScreenState();
}

class _PregnancyRiskScreenState extends State<PregnancyRiskScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  final TextEditingController ageController = TextEditingController();
  final TextEditingController systolicBPController = TextEditingController();
  final TextEditingController diastolicBPController = TextEditingController();
  final TextEditingController bloodGlucoseController = TextEditingController();
  final TextEditingController bodyTempController = TextEditingController();
  final TextEditingController heartRateController = TextEditingController();
  final AuthService _authService = AuthService();

  String _prediction = "";
  bool _isLoading = false;
  late Future<List<Map<String, dynamic>>> _previousSubmissions;

  @override
  void initState() {
    super.initState();
    _previousSubmissions = _fetchPreviousSubmissions();
  }

Future<void> _predictAndSave() async {
    setState(() {
      _isLoading = true;
      _prediction = "";
    });

    final url = Uri.parse('${ApiContants.baseUrl}/predict_maternal');
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
          String result = data['prediction'];
          int numericResult = data['prediction_numeric'];

          await supabase.from('vitals').insert({
            "systolic_bp": double.tryParse(systolicBPController.text) ?? 0.0,
            "diastolic_bp": double.tryParse(diastolicBPController.text) ?? 0.0,
            "blood_glucose": double.tryParse(bloodGlucoseController.text) ?? 0.0,
            "body_temp": double.tryParse(bodyTempController.text) ?? 0.0,
            "heart_rate": double.tryParse(heartRateController.text) ?? 0.0,
            "prediction": numericResult,
            "created_at": DateTime.now().toIso8601String(),
          });

          setState(() {
            _prediction = "Predicted Risk Level: $result";
            _previousSubmissions = _fetchPreviousSubmissions();
          });
        }
      } else {
        setState(() {
          _prediction = "Error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _prediction = "Please reload so that model analyzes";
        setState(() {
          
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPreviousSubmissions() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) {
      return [];
    }
    
    final response = await supabase
        .from('vitals')
        .select("*")
        .eq('UID', userId)
        .select("*")
        .order('created_at', ascending: false);

    return response.map<Map<String, dynamic>>((data) => data).toList();
  }

  String formatDate(String dateString) {
    DateTime dateTime = DateTime.parse(dateString);
    return "${dateTime.day}-${dateTime.month}-${dateTime.year} ${dateTime.hour}:${dateTime.minute}";
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: TextStyle(color: AppPallete.textColor,),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppPallete.textColor),
          filled: true,
          fillColor: AppPallete.backgroundColor,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey[700]!, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.pinkAccent, width: 2),
          ),
        ),
      ),
    );
  }

 Widget _buildTable(List<Map<String, dynamic>> vitals) {
  Map<int, String> riskMapping = {
    0: "Normal",
    1: "Suspect",
    2: "Pathological"
  };

  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      border: TableBorder.all(color: Colors.black),
      columns: [
        DataColumn(label: Text('Date', style: TextStyle(color: Colors.black))),
        DataColumn(label: Text('Sys BP', style: TextStyle(color: Colors.black))),
        DataColumn(label: Text('Dia BP', style: TextStyle(color: Colors.black))),
        DataColumn(label: Text('Glucose', style: TextStyle(color: Colors.black))),
        DataColumn(label: Text('Temp', style: TextStyle(color: Colors.black))),
        DataColumn(label: Text('HR', style: TextStyle(color: Colors.black))),
        DataColumn(label: Text('Risk', style: TextStyle(color: Colors.black))),
      ],
      rows: vitals.map((vital) {
        return DataRow(cells: [
          DataCell(Text(formatDate(vital['created_at'].toString()), style: TextStyle(color: Colors.black))),
          DataCell(Text(vital['systolic_bp'].toString(), style: TextStyle(color: Colors.black))),
          DataCell(Text(vital['diastolic_bp'].toString(), style: TextStyle(color: Colors.black))),
          DataCell(Text(vital['blood_glucose'].toString(), style: TextStyle(color: Colors.black))),
          DataCell(Text(vital['body_temp'].toString(), style: TextStyle(color: Colors.black))),
          DataCell(Text(vital['heart_rate'].toString(), style: TextStyle(color: Colors.black))),
          DataCell(Text(riskMapping[vital['prediction']] ?? vital['prediction'].toString(), 
            style: TextStyle(color: Colors.black))),
        ]);
      }).toList(),
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
                : ElevatedButton(
                    onPressed: _predictAndSave,
                    child: Text('Predict & Save',style: TextStyle(color: AppPallete.backgroundColor),),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPallete.gradient1,
                    )
                  ),

            SizedBox(height: 20),
            Text(
              _prediction,
              style: TextStyle(fontSize: 18, color: AppPallete.textColor),
              textAlign: TextAlign.center,
            ),

            //Text(_prediction, style: TextStyle(color: AppPallete.textColor)),

            SizedBox(height: 30),
            Text('Previous Submissions', style: TextStyle(color: AppPallete.textColor, fontSize: 20)),
            SizedBox(height: 8,),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _previousSubmissions,
              builder: (context, snapshot) {
                return snapshot.hasData ? _buildTable(snapshot.data!) : CircularProgressIndicator();
              },
            ),
          ],
        ),
      ),
// Keeping the dark theme
    );
  }
}
