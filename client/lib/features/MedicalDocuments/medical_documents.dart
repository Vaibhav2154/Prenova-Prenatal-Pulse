import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:prenova/core/theme/app_pallete.dart';

class MedicalDocumentsPage extends StatefulWidget {
  @override
  _MedicalDocumentsPageState createState() => _MedicalDocumentsPageState();
}

class _MedicalDocumentsPageState extends State<MedicalDocumentsPage>
    with TickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  List<String> uploadedFiles = [];
  bool isLoading = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchDocuments();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
      final String? mimeType =
          lookupMimeType(file.path) ?? 'application/octet-stream';

      setState(() => isLoading = true);

      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception("User not authenticated. Please log in.");
      }

      await supabase.storage.from('medical_docs').uploadBinary(
          fileName, fileBytes,
          fileOptions: FileOptions(contentType: mimeType));

      final String fileUrl = supabase.storage
          .from('medical_docs')
          .getPublicUrl(fileName)
          .split('?')[0];

      setState(() {
        uploadedFiles.add(fileUrl);
        isLoading = false;
      });

      _showSuccessSnackBar("Document uploaded successfully!");
    } catch (error) {
      setState(() => isLoading = false);
      _showErrorSnackBar("Upload failed: $error");
      debugPrint("Upload Error: $error");
    }
  }

  /// Fetch documents from Supabase storage
  Future<void> _fetchDocuments() async {
    try {
      setState(() => isLoading = true);

      final List<FileObject> files =
          await supabase.storage.from('medical_docs').list();

      if (files.isEmpty) {
        debugPrint("No files found in storage.");
        setState(() => isLoading = false);
        return;
      }

      final validFiles =
          files.where((file) => !file.name.startsWith('.')).toList();

      if (validFiles.isEmpty) {
        debugPrint("No valid files found in storage.");
        setState(() => isLoading = false);
        return;
      }

      List<String> fileUrls = validFiles.map((file) {
        return supabase.storage
            .from('medical_docs')
            .getPublicUrl(file.name)
            .split('?')[0];
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

  /// Opens files in the browser or in-app viewer
  void _openFile(String url, String extension) async {
    String cleanedUrl = url.trim();
    debugPrint("Opening File: $cleanedUrl");

    if (extension == 'pdf') {
      setState(() => isLoading = true);
      try {
        final response = await http.get(Uri.parse(cleanedUrl));
        final bytes = response.bodyBytes;
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/document.pdf');
        await file.writeAsBytes(bytes);

        setState(() => isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => _buildPDFViewer(file.path),
          ),
        );
      } catch (e) {
        setState(() => isLoading = false);
        debugPrint("PDF loading error: $e");
        _showErrorSnackBar("Failed to load PDF: $e");
      }
    } else {
      _showImageDialog(cleanedUrl);
    }
  }

  Widget _buildPDFViewer(String filePath) {
    return Scaffold(
      backgroundColor: AppPallete.backgroundColor,
      appBar: AppBar(
        title: Text(
          "PDF Document",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppPallete.gradient1, AppPallete.gradient2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PDFView(
        filePath: filePath,
        enableSwipe: true,
        swipeHorizontal: true,
        autoSpacing: false,
        pageFling: false,
        onError: (error) {
          debugPrint("PDF Error: $error");
          _showErrorSnackBar("Error loading PDF");
        },
      ),
    );
  }

  void _showImageDialog(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      LucideIcons.x,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ],
              ),
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Container(
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppPallete.gradient1,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 200,
                        child: Center(
                          child: Icon(
                            LucideIcons.imageOff,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(LucideIcons.checkCircle, color: Colors.white),
            SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(LucideIcons.alertCircle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.backgroundColor,
      appBar: AppBar(
        title: Text(
          "Medical Documents",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppPallete.gradient1, AppPallete.gradient2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: AppPallete.gradient1.withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              _buildHeaderSection(),
              SizedBox(height: 24),
              _buildUploadButton(),
              SizedBox(height: 24),
              Expanded(child: _buildDocumentsList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppPallete.gradient1.withOpacity(0.1),
            AppPallete.gradient2.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppPallete.gradient1.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppPallete.gradient1,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppPallete.gradient1.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              LucideIcons.fileText,
              color: Colors.white,
              size: 28,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Document Vault',
                  style: TextStyle(
                    color: AppPallete.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Store and manage your medical documents securely',
                  style: TextStyle(
                    color: AppPallete.textColor.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : _pickDocument,
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(LucideIcons.upload, color: Colors.white, size: 24),
        label: Text(
          isLoading ? "Uploading..." : "Upload Document",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPallete.gradient2,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ).copyWith(
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.disabled)) {
              return AppPallete.gradient1.withOpacity(0.6);
            }
            return null;
          }),
        ),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppPallete.gradient1, AppPallete.gradient2],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppPallete.gradient1.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsList() {
    if (isLoading && uploadedFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppPallete.gradient1),
            SizedBox(height: 16),
            Text(
              "Loading documents...",
              style: TextStyle(
                color: AppPallete.textColor.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (uploadedFiles.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.folder, color: AppPallete.gradient1, size: 20),
              SizedBox(width: 8),
              Text(
                'My Documents (${uploadedFiles.length})',
                style: TextStyle(
                  color: AppPallete.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchDocuments,
              color: AppPallete.gradient1,
              child: ListView.builder(
                physics: BouncingScrollPhysics(),
                itemCount: uploadedFiles.length,
                itemBuilder: (context, index) {
                  return TweenAnimationBuilder(
                    duration: Duration(milliseconds: 600 + (index * 100)),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, double value, child) {
                      return Transform.translate(
                        offset: Offset(0, 30 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: _buildDocumentCard(index),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(int index) {
    String fileUrl = uploadedFiles[index];
    String fileExtension = fileUrl.split('.').last.toLowerCase();
    bool isPdf = fileExtension == 'pdf';
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openFile(fileUrl, fileExtension),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isPdf 
                        ? Colors.red.withOpacity(0.1)
                        : AppPallete.gradient2.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isPdf ? LucideIcons.fileText : LucideIcons.image,
                    color: isPdf ? Colors.red : AppPallete.gradient2,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Document ${index + 1}",
                        style: TextStyle(
                          color: AppPallete.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        isPdf ? "PDF Document" : "Image Document",
                        style: TextStyle(
                          color: AppPallete.textColor.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppPallete.gradient1.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Tap to view",
                          style: TextStyle(
                            color: AppPallete.gradient1,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppPallete.gradient1.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    LucideIcons.chevronRight,
                    color: AppPallete.gradient1,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppPallete.gradient1.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              LucideIcons.folderOpen,
              size: 64,
              color: AppPallete.gradient1,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No Documents Yet',
            style: TextStyle(
              color: AppPallete.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Upload your first medical document\nto get started',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppPallete.textColor.withOpacity(0.6),
              fontSize: 16,
              height: 1.4,
            ),
          ),
          SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppPallete.gradient1.withOpacity(0.1),
                  AppPallete.gradient2.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton.icon(
              onPressed: _pickDocument,
              icon: Icon(LucideIcons.upload, color: AppPallete.gradient1),
              label: Text(
                "Upload Document",
                style: TextStyle(
                  color: AppPallete.gradient1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
