import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PregnancyDietScreen extends StatefulWidget {
  @override
  _PregnancyDietScreenState createState() => _PregnancyDietScreenState();
}

class _PregnancyDietScreenState extends State<PregnancyDietScreen> {
  final TextEditingController weightController = TextEditingController();
  final TextEditingController healthController = TextEditingController();
  final TextEditingController dietController = TextEditingController();
  String trimester = "First"; // Default selection
  String dietPlan = "";
  bool isLoading = false;

  Future<void> fetchPregnancyDiet() async {
    setState(() {
      isLoading = true;
      dietPlan = ""; // Clear previous results
    });

    try {
      final response = await http.post(
        Uri.parse("http://10.0.2.2:5000/pregnancy-diet"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "trimester": trimester,
          "weight": weightController.text.trim(),
          "health_conditions": healthController.text.trim(),
          "dietary_preference": dietController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          dietPlan = jsonDecode(response.body)["diet_plan"] ?? "No diet plan received.";
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Pregnancy Diet Plan")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Select Trimester:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: trimester,
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
            SizedBox(height: 10),

            TextField(controller: weightController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Weight (kg)")),
            TextField(controller: healthController, decoration: InputDecoration(labelText: "Health Conditions (if any)")),
            TextField(controller: dietController, decoration: InputDecoration(labelText: "Dietary Preference")),

            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : fetchPregnancyDiet,
              child: isLoading ? CircularProgressIndicator(color: Colors.white) : Text("Get Diet Plan"),
            ),

            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(dietPlan, style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
