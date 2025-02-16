import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MedicalDocumentsPage extends StatefulWidget {
  @override
  _MedicalDocumentsPageState createState() => _MedicalDocumentsPageState();
}

class _MedicalDocumentsPageState extends State<MedicalDocumentsPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  List<String> uploadedFiles = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  /// Pick a file and upload to Supabase
  Future<void> _pickDocument() async {
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) {
        debugPrint("No file selected.");
        return;
      }

      Uint8List fileBytes = await file.readAsBytes();
      final String fileName =
          "${DateTime.now().millisecondsSinceEpoch}.${file.path.split('.').last}";
      final String? mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';

      setState(() => isLoading = true);

      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception("User not authenticated. Please log in.");
      }

      await supabase.storage
          .from('medical_docs')
          .uploadBinary(fileName, fileBytes, fileOptions: FileOptions(contentType: mimeType));

      /// ✅ Corrected URL fetching
      final String fileUrl = supabase.storage.from('medical_docs').getPublicUrl(fileName).split('?')[0];

      setState(() {
        uploadedFiles.add(fileUrl);
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Uploaded Successfully!")),
      );
    } catch (error) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload Failed: $error")),
      );
      debugPrint("Upload Error: $error");
    }
  }

  /// Fetch documents from Supabase storage
  Future<void> _fetchDocuments() async {
    try {
      setState(() => isLoading = true);

      final List<FileObject> files = await supabase.storage.from('medical_docs').list();

      if (files.isEmpty) {
        debugPrint("No files found in storage.");
        setState(() => isLoading = false);
        return;
      }

      List<String> fileUrls = files.map((file) {
        return supabase.storage.from('medical_docs').getPublicUrl(file.name).split('?')[0];
      }).toList();

      setState(() {
        uploadedFiles = fileUrls;
        isLoading = false;
      });
    } catch (error) {
      setState(() => isLoading = false);
      debugPrint("Error fetching documents: $error");
    }
  }

  /// Opens files in the browser
  void _openFile(String url, String extension) async {
    String cleanedUrl = url.trim();
    debugPrint("Opening File: $cleanedUrl");

    if (extension == 'pdf') {
      if (await canLaunchUrl(Uri.parse(cleanedUrl))) {
        await launchUrl(Uri.parse(cleanedUrl), mode: LaunchMode.externalApplication);
      } else {
        debugPrint("Could not open PDF: $cleanedUrl");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not open PDF")),
        );
      }
    } else {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: CachedNetworkImage(
              imageUrl: cleanedUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => CircularProgressIndicator(),
              errorWidget: (context, url, error) =>
                  Icon(Icons.broken_image, size: 50, color: Colors.red),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Medical Documents",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.pinkAccent,
        elevation: 3,
        centerTitle: true,
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _pickDocument,
            icon: Icon(Icons.upload_file, color: Colors.white),
            label: Text("Upload Document",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            ),
          ),
          SizedBox(height: 20),
          isLoading
              ? Expanded(child: Center(child: CircularProgressIndicator()))
              : Expanded(
                  child: uploadedFiles.isEmpty
                      ? Center(
                          child: Text("No documents uploaded yet.",
                              style: TextStyle(fontSize: 16)))
                      : ListView.builder(
                          itemCount: uploadedFiles.length,
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          itemBuilder: (context, index) {
                            String fileUrl = uploadedFiles[index];
                            String fileExtension =
                                fileUrl.split('.').last.toLowerCase();
                            bool isPdf = fileExtension == 'pdf';

                            return Card(
                              elevation: 2,
                              margin: EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                contentPadding: EdgeInsets.all(12),
                                leading: isPdf
                                    ? Icon(Icons.picture_as_pdf,
                                        color: Colors.red, size: 40)
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: CachedNetworkImage(
                                          imageUrl: fileUrl,
                                          height: 50,
                                          width: 50,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              CircularProgressIndicator(),
                                          errorWidget: (context, url, error) =>
                                              Icon(Icons.image,
                                                  color: Colors.grey,
                                                  size: 50),
                                        ),
                                      ),
                                title: Text("Document ${index + 1}",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text("Tap to view",
                                    style: TextStyle(color: Colors.grey[600])),
                                onTap: () => _openFile(fileUrl, fileExtension),
                              ),
                            );
                          },
                        ),
                ),
        ],
      ),
    );
  }
}