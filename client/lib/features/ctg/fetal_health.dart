import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PDFUploadScreen extends StatefulWidget {
  @override
  _PDFUploadScreenState createState() => _PDFUploadScreenState();
}

class _PDFUploadScreenState extends State<PDFUploadScreen> {
  File? selectedFile;
  String? analysisResult;

  Future<void> pickAndUploadPDF() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
      });

      await uploadPDF();
    }
  }

  Future<void> uploadPDF() async {
    if (selectedFile == null) return;

    var request = http.MultipartRequest(
      'POST',
      Uri.parse("http://10.0.2,2:5000/analyze-ctg"),
    );

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        selectedFile!.path,
      ),
    );

    var response = await request.send();
    if (response.statusCode == 200) {
      var responseBody = await response.stream.bytesToString();
      var decodedResponse = jsonDecode(responseBody);
      setState(() {
        analysisResult = decodedResponse["analysis"];
      });
    } else {
      setState(() {
        analysisResult = "Error in processing CTG report.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Fetal CTG Analyzer")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: pickAndUploadPDF,
              child: Text("Upload CTG Report"),
            ),
            SizedBox(height: 20),
            analysisResult != null
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "Analysis: $analysisResult",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}
