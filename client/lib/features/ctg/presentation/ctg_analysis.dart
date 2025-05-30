import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:prenova/core/constants/api_contants.dart';
import 'package:prenova/core/utils/loader.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:prenova/core/theme/app_pallete.dart';
import 'dart:convert';
import 'package:prenova/features/auth/auth_service.dart';

class CTGAnalysisScreen extends StatefulWidget {
  @override
  _CTGAnalysisScreenState createState() => _CTGAnalysisScreenState();
}

class _CTGAnalysisScreenState extends State<CTGAnalysisScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();

  // CTG feature controllers
  final TextEditingController baselineValueController = TextEditingController();
  final TextEditingController accelerationsController = TextEditingController();
  final TextEditingController fetalMovementController = TextEditingController();
  final TextEditingController uterineContractionsController = TextEditingController();
  final TextEditingController lightDecelerationsController = TextEditingController();
  final TextEditingController severeDecelerationsController = TextEditingController();
  final TextEditingController prolongedDecelerationsController = TextEditingController();
  final TextEditingController abnormalShortTermController = TextEditingController();
  final TextEditingController meanShortTermController = TextEditingController();
  final TextEditingController abnormalLongTermController = TextEditingController();
  final TextEditingController meanLongTermController = TextEditingController();
  final TextEditingController histogramWidthController = TextEditingController();
  final TextEditingController histogramMinController = TextEditingController();
  final TextEditingController histogramMaxController = TextEditingController();
  final TextEditingController histogramPeaksController = TextEditingController();

  String _prediction = "";
  bool _isLoading = false;
  late Future<List<Map<String, dynamic>>> _previousSubmissions;

  // CTG feature data
  final List<Map<String, dynamic>> ctgFeatures = [
    {
      'label': 'Baseline Value',
      'controller': null,
      'icon': Icons.timeline,
      'hint': 'Normal: 110-160',
      'suffix': 'bpm',
    },
    {
      'label': 'Accelerations',
      'controller': null,
      'icon': Icons.trending_up,
      'hint': 'Count per hour',
      'suffix': '/hr',
    },
    {
      'label': 'Fetal Movement',
      'controller': null,
      'icon': Icons.child_care,
      'hint': 'Movement count',
      'suffix': 'count',
    },
    {
      'label': 'Uterine Contractions',
      'controller': null,
      'icon': Icons.compress,
      'hint': 'Contractions per hour',
      'suffix': '/hr',
    },
    {
      'label': 'Light Decelerations',
      'controller': null,
      'icon': Icons.trending_down,
      'hint': 'Count',
      'suffix': 'count',
    },
    {
      'label': 'Severe Decelerations',
      'controller': null,
      'icon': Icons.warning,
      'hint': 'Count',
      'suffix': 'count',
    },
    {
      'label': 'Prolonged Decelerations',
      'controller': null,
      'icon': Icons.hourglass_bottom,
      'hint': 'Count',
      'suffix': 'count',
    },
    {
      'label': 'Abnormal Short Term Variability',
      'controller': null,
      'icon': Icons.scatter_plot,
      'hint': 'Percentage',
      'suffix': '%',
    },
    {
      'label': 'Mean Short Term Variability',
      'controller': null,
      'icon': Icons.show_chart,
      'hint': 'Mean value',
      'suffix': 'ms',
    },
    {
      'label': 'Abnormal Long Term Variability',
      'controller': null,
      'icon': Icons.timeline,
      'hint': 'Percentage',
      'suffix': '%',
    },
    {
      'label': 'Mean Long Term Variability',
      'controller': null,
      'icon': Icons.analytics,
      'hint': 'Mean value',
      'suffix': 'ms',
    },
    {
      'label': 'Histogram Width',
      'controller': null,
      'icon': Icons.bar_chart,
      'hint': 'Width value',
      'suffix': 'bpm',
    },
    {
      'label': 'Histogram Min',
      'controller': null,
      'icon': Icons.south,
      'hint': 'Minimum value',
      'suffix': 'bpm',
    },
    {
      'label': 'Histogram Max',
      'controller': null,
      'icon': Icons.north,
      'hint': 'Maximum value',
      'suffix': 'bpm',
    },
    {
      'label': 'Histogram Number of Peaks',
      'controller': null,
      'icon': Icons.signal_cellular_alt,
      'hint': 'Peak count',
      'suffix': 'count',
    },
  ];

  List<TextEditingController> controllers = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _previousSubmissions = _fetchPreviousSubmissions();
  }

  void _initializeControllers() {
    controllers = [
      baselineValueController,
      accelerationsController,
      fetalMovementController,
      uterineContractionsController,
      lightDecelerationsController,
      severeDecelerationsController,
      prolongedDecelerationsController,
      abnormalShortTermController,
      meanShortTermController,
      abnormalLongTermController,
      meanLongTermController,
      histogramWidthController,
      histogramMinController,
      histogramMaxController,
      histogramPeaksController,
    ];

    // Assign controllers to feature data
    for (int i = 0; i < ctgFeatures.length; i++) {
      ctgFeatures[i]['controller'] = controllers[i];
    }
  }

  Future<void> _predictAndSave() async {
    if (!_validateInputs()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _prediction = "";
    });

    const int maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        final url = Uri.parse('${ApiContants.baseUrl}/predict_fetal');
        final session = _authService.currentSession;
        final token = session?.accessToken;

        final List<double> features = controllers
            .map((controller) => double.tryParse(controller.text) ?? 0.0)
            .toList();

        final response = await http
            .post(
              url,
              headers: {
                "Content-Type": "application/json",
                'Authorization': 'Bearer $token',
                'Connection': 'keep-alive',
              },
              body: jsonEncode({
                "features": features,
              }),
            )
            .timeout(Duration(seconds: 30));
        
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          
          log('CTG API Response: ${response.body}');
          log('Prediction: ${data['prediction']}');
          
          if (data.containsKey('prediction') && data.containsKey('status')) {
            int prediction = data['prediction'];
            String status = data['status'];
            
            setState(() {
              _prediction = "Fetal Health Status: $status";
              _previousSubmissions = _fetchPreviousSubmissions();
              _isLoading = false;
            });
            return;
          } else {
            
            setState(() {
              _prediction = "Error: Invalid response format";
              _isLoading = false;
            });
            return;
          }
        } else {
          log(response.body.toString());
          setState(() {
            _prediction = "Error: ${response.statusCode}";
            _isLoading = false;
          });
          return;
        }
      } on http.ClientException catch (e) {
        retryCount++;
        log('Connection error (attempt $retryCount/$maxRetries): ${e.message}');

        if (retryCount >= maxRetries) {
          setState(() {
            _prediction = "Connection failed. Please check your network and try again.";
            _isLoading = false;
          });
          return;
        }

        await Future.delayed(Duration(seconds: 2 * retryCount));
      } catch (e) {
        setState(() {
          _prediction = "Network error. Please check your connection and try again.";
          _isLoading = false;
        });
        log('Unexpected error: ${e.toString()}');
        return;
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  bool _validateInputs() {
    for (int i = 0; i < controllers.length; i++) {
      if (controllers[i].text.isEmpty) {
        _showValidationError('Please fill all fields');
        return false;
      }
    }

    // Additional validation for CTG ranges
    double? baseline = double.tryParse(baselineValueController.text);
    if (baseline == null || baseline < 50 || baseline > 200) {
      _showValidationError('Baseline value should be between 50-200 bpm');
      return false;
    }

    return true;
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchPreviousSubmissions() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) {
      return [];
    }

    final response = await supabase
        .from('ctg')
        .select("*")
        .eq('UID', userId)
        .order('created_at', ascending: false);

    return response.map<Map<String, dynamic>>((data) => data).toList();
  }

  String formatDate(String dateString) {
    DateTime dateTime = DateTime.parse(dateString);
    return "${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required String suffix,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: TextStyle(
          color: AppPallete.textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(
            color: AppPallete.textColor.withOpacity(0.8),
            fontSize: 14,
          ),
          hintStyle: TextStyle(
            color: AppPallete.textColor.withOpacity(0.5),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.pinkAccent,
            size: 20,
          ),
          suffixText: suffix,
          suffixStyle: TextStyle(
            color: AppPallete.textColor.withOpacity(0.7),
            fontSize: 12,
          ),
          filled: true,
          fillColor: AppPallete.backgroundColor.withOpacity(0.8),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.grey.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.pinkAccent,
              width: 2.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.red,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTable(List<Map<String, dynamic>> ctgData) {
    // CORRECTED MAPPING
    Map<int, String> healthMapping = {
      0: "Normal",      // Changed from 1 to 0
      1: "Suspect",     // Changed from 2 to 1  
      2: "Pathological" // Changed from 3 to 2
    };

    Map<int, Color> healthColors = {
      0: Colors.green,   // Changed from 1 to 0
      1: Colors.orange,  // Changed from 2 to 1
      2: Colors.red,     // Changed from 3 to 2
    };

    if (ctgData.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppPallete.backgroundColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(Icons.history, color: Colors.grey, size: 48),
            SizedBox(height: 12),
            Text(
              'No previous CTG analyses found',
              style: TextStyle(
                color: AppPallete.textColor.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            Text(
              'Your fetal health assessments will appear here',
              style: TextStyle(
                color: AppPallete.textColor.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(Colors.pinkAccent.withOpacity(0.1)),
            dataRowColor: MaterialStateProperty.resolveWith((states) {
              return Colors.white;
            }),
            columnSpacing: 16,
            horizontalMargin: 16,
            columns: [
              DataColumn(
                label: Text(
                  'Date',
                  style: TextStyle(
                    color: Colors.pinkAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Baseline\n(bpm)',
                  style: TextStyle(
                    color: Colors.pinkAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              DataColumn(
                label: Text(
                  'Accelerations\n(/hr)',
                  style: TextStyle(
                    color: Colors.pinkAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              DataColumn(
                label: Text(
                  'Movements\n(count)',
                  style: TextStyle(
                    color: Colors.pinkAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              DataColumn(
                label: Text(
                  'Health Status',
                  style: TextStyle(
                    color: Colors.pinkAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            rows: ctgData.take(10).map((data) {
              int prediction = data['prediction'] ?? 1;
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      formatDate(data['created_at'].toString()),
                      style: TextStyle(color: Colors.black87, fontSize: 11),
                    ),
                  ),
                  DataCell(
                    Text(
                      data['baseline_value']?.toString() ?? 'N/A',
                      style: TextStyle(color: Colors.black87, fontSize: 12),
                    ),
                  ),
                  DataCell(
                    Text(
                      data['accelerations']?.toString() ?? 'N/A',
                      style: TextStyle(color: Colors.black87, fontSize: 12),
                    ),
                  ),
                  DataCell(
                    Text(
                      data['fetal_movement']?.toString() ?? 'N/A',
                      style: TextStyle(color: Colors.black87, fontSize: 12),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: healthColors[prediction]?.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: healthColors[prediction] ?? Colors.grey,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        healthMapping[prediction] ?? data['prediction'].toString(),
                        style: TextStyle(
                          color: healthColors[prediction] ?? Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.backgroundColor,
      appBar: AppBar(
        title: Text(
          'CTG Analysis',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.pinkAccent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _previousSubmissions = _fetchPreviousSubmissions();
          });
          return Future<void>.value();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.pinkAccent.withOpacity(0.1), Colors.blue.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.pinkAccent.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.monitor_heart, color: Colors.pinkAccent, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fetal CTG Analysis',
                            style: TextStyle(
                              color: AppPallete.textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Enter CTG measurements for fetal health assessment',
                            style: TextStyle(
                              color: AppPallete.textColor.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Input fields
              ...ctgFeatures.map((feature) => _buildTextField(
                    label: feature['label'],
                    controller: feature['controller'],
                    icon: feature['icon'],
                    hint: feature['hint'],
                    suffix: feature['suffix'],
                  )),

              SizedBox(height: 32),

              // Analyze button
              Container(
                width: double.infinity,
                height: 56,
                child: _isLoading
                    ? Container(
                        
                        child: CircularProgressIndicator(
                          // size: 30,
                          // message: "Analyzing CTG data...",
                          color: Colors.white,
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: _predictAndSave,
                        icon: Icon(Icons.analytics, color: Colors.white),
                        label: Text(
                          'Analyze Fetal Health',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ).copyWith(
                          backgroundColor: MaterialStateProperty.all(Colors.transparent),
                        ),
                      ),
                decoration: BoxDecoration(
                  color: Colors.pinkAccent,
                  // gradient: LinearGradient(
                  //   colors: [Colors.pinkAccent, Colors.blue.shade400],
                  //   begin: Alignment.topLeft,
                  //   end: Alignment.bottomRight,
                  // ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pinkAccent.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Prediction result
              if (_prediction.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _prediction.contains('Normal') 
                        ? Colors.green.withOpacity(0.1)
                        : _prediction.contains('Suspect')
                            ? Colors.orange.withOpacity(0.1)
                            : _prediction.contains('Error')
                                ? Colors.red.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1), // For Pathological
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _prediction.contains('Normal')
                          ? Colors.green
                          : _prediction.contains('Suspect')
                              ? Colors.orange
                              : _prediction.contains('Error')
                                  ? Colors.red
                                  : Colors.red, // For Pathological
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _prediction.contains('Normal')
                            ? Icons.check_circle
                            : _prediction.contains('Suspect')
                                ? Icons.warning
                                : Icons.error,
                        color: _prediction.contains('Normal')
                            ? Colors.green
                            : _prediction.contains('Suspect')
                                ? Colors.orange
                                : Colors.red,
                        size: 32,
                      ),
                      SizedBox(height: 8),
                      Text(
                        _prediction,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppPallete.textColor,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 40),

              // Previous submissions header
              Row(
                children: [
                  Icon(Icons.history, color: Colors.pinkAccent),
                  SizedBox(width: 8),
                  Text(
                    'Previous CTG Analyses',
                    style: TextStyle(
                      color: AppPallete.textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Previous submissions table
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _previousSubmissions,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      height: 200,
                      child: Center(
                        child: SimpleCustomLoader(
                          size: 40,
                          message: "Loading previous analyses...",
                          color: AppPallete.gradient1,
                        ),
                      ),
                    );
                  }
                  return _buildTable(snapshot.data ?? []);
                },
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