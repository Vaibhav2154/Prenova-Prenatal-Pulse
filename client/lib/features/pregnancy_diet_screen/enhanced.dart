import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:prenova/core/constants/api_contants.dart';
import 'package:prenova/core/theme/app_pallete.dart';
import 'package:prenova/features/auth/auth_service.dart';
import 'package:lucide_icons/lucide_icons.dart';

class DietPlan {
  final String id;
  final String title;
  final String trimester;
  final String weight;
  final String healthConditions;
  final String dietaryPreference;
  final Map<String, dynamic> dietPlan;
  final DateTime createdAt;

  DietPlan({
    required this.id,
    required this.title,
    required this.trimester,
    required this.weight,
    required this.healthConditions,
    required this.dietaryPreference,
    required this.dietPlan,
    required this.createdAt,
  });

  factory DietPlan.fromJson(Map<String, dynamic> json) {
    try {
      return DietPlan(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? 'Diet Plan',
        trimester: json['trimester']?.toString() ?? '',
        weight: json['weight']?.toString() ?? '',
        healthConditions: json['health_conditions']?.toString() ?? '',
        dietaryPreference: json['dietary_preference']?.toString() ?? '',
        dietPlan: json['diet_plan'] is String 
            ? jsonDecode(json['diet_plan']) 
            : json['diet_plan'] ?? {},
        createdAt: json['created_at'] != null 
            ? DateTime.parse(json['created_at']) 
            : DateTime.now(),
      );
    } catch (e) {
      log('Error parsing DietPlan from JSON: $e');
      log('JSON data: ${json.toString()}');
      throw Exception('Failed to parse diet plan data');
    }
  }
}

class EnhancedPregnancyDietScreen extends StatefulWidget {
  @override
  _EnhancedPregnancyDietScreenState createState() => _EnhancedPregnancyDietScreenState();
}

class _EnhancedPregnancyDietScreenState extends State<EnhancedPregnancyDietScreen> with TickerProviderStateMixin {
  final TextEditingController weightController = TextEditingController();
  final TextEditingController healthController = TextEditingController();
  final TextEditingController dietController = TextEditingController();
  final AuthService _authService = AuthService();
  
  String trimester = "First";
  List<DietPlan> dietSessions = [];
  DietPlan? currentDietPlan;
  bool isLoading = false;
  bool isLoadingSessions = false;
  int selectedMealPlan = 0;
  
  late TabController _tabController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize animations like chat screen
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    
    loadDietSessions();
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    weightController.dispose();
    healthController.dispose();
    dietController.dispose();
    super.dispose();
  }

  Future<void> loadDietSessions() async {
    log('📥 Loading diet sessions...');
    setState(() {
      isLoadingSessions = true;
    });

    try {
      final session = _authService.currentSession;
      if (session == null) {
        log('❌ No active session found');
        _showErrorSnackBar('Please log in to view diet plans');
        return;
      }

      final token = session.accessToken;
      log('🔑 Using token: ${token.substring(0, 20)}...');

      final response = await http.get(
        Uri.parse("${ApiContants.baseUrl}/diet/sessions"),
        headers: {
          'Authorization': 'Bearer $token', // This was missing before
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 30));

      log('📡 Response status: ${response.statusCode}');
      log('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> sessionsData = jsonDecode(response.body);
        log('✅ Successfully loaded ${sessionsData.length} diet sessions');
        
        setState(() {
          dietSessions = sessionsData.map((data) {
            try {
              return DietPlan.fromJson(data);
            } catch (e) {
              log('⚠️ Error parsing session: $e');
              return null;
            }
          }).where((plan) => plan != null).cast<DietPlan>().toList();
        });
      } else if (response.statusCode == 401) {
        log('🔒 Authentication failed');
        _showErrorSnackBar('Session expired. Please log in again.');
      } else {
        log('❌ Failed to load sessions: ${response.statusCode} - ${response.body}');
        _showErrorSnackBar('Failed to load diet sessions');
      }
    } on http.ClientException catch (e) {
      log('🌐 Network error loading sessions: $e');
      _showErrorSnackBar('Network error. Please check your connection.');
    } catch (e) {
      log('💥 Unexpected error loading sessions: $e');
      _showErrorSnackBar('Error loading sessions: ${e.toString()}');
    } finally {
      setState(() {
        isLoadingSessions = false;
      });
    }
  }

  Future<void> createNewDietPlan() async {
    log('🍽️ Creating new diet plan...');
    
    if (weightController.text.trim().isEmpty) {
      log('⚠️ Weight field is empty');
      _showErrorSnackBar('Please enter your weight');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final session = _authService.currentSession;
      if (session == null) {
        log('❌ No active session for diet plan creation');
        _showErrorSnackBar('Please log in to create diet plans');
        return;
      }

      final token = session.accessToken;
      log('🔑 Creating diet plan with token: ${token.substring(0, 20)}...');

      final requestBody = {
        "trimester": trimester,
        "weight": weightController.text.trim(),
        "health_conditions": healthController.text.trim(),
        "dietary_preference": dietController.text.trim(),
      };
      
      log('📤 Request body: $requestBody');

      final response = await http.post(
        Uri.parse("${ApiContants.baseUrl}/diet/sessions"),
        headers: {
          "Content-Type": "application/json", 
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(requestBody),
      ).timeout(Duration(seconds: 60)); // Longer timeout for AI generation

      log('📡 Diet creation response status: ${response.statusCode}');
      log('📡 Diet creation response body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final newSession = DietPlan.fromJson(responseData);
        
        log('✅ Diet plan created successfully: ${newSession.id}');
        
        // Check if the diet plan actually has content
        final dietPlan = newSession.dietPlan;
        final mealPlans = dietPlan['meal_plans'] as List?;
        final tips = dietPlan['tips'] as List?;
        final supplements = dietPlan['supplements'] as List?;
        
        bool hasContent = (mealPlans?.isNotEmpty ?? false) || 
                         (tips?.isNotEmpty ?? false) || 
                         (supplements?.isNotEmpty ?? false);
        
        setState(() {
          currentDietPlan = newSession;
          dietSessions.insert(0, newSession);
        });
        
        _tabController.animateTo(1);
        
        if (hasContent) {
          _showSuccessSnackBar('Diet plan generated successfully!');
        } else {
          _showWarningSnackBar('Diet plan created but content generation is still in progress. Please try refreshing or contact support.');
        }
        
        // Clear form
        weightController.clear();
        healthController.clear();
        dietController.clear();
      } else if (response.statusCode == 401) {
        log('🔒 Authentication failed during diet plan creation');
        _showErrorSnackBar('Session expired. Please log in again.');
      } else {
        log('❌ Failed to create diet plan: ${response.statusCode} - ${response.body}');
        _showErrorSnackBar('Failed to generate diet plan. Please try again.');
      }
    } on http.ClientException catch (e) {
      log('🌐 Network error creating diet plan: $e');
      _showErrorSnackBar('Network error. Please check your connection.');
    } catch (e) {
      log('💥 Unexpected error creating diet plan: $e');
      _showErrorSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteDietSession(String sessionId) async {
    log('🗑️ Deleting diet session: $sessionId');
    
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[850],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Delete Diet Plan', style: TextStyle(color: Colors.white)),
          content: Text('Are you sure you want to delete this diet plan?', 
                      style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      log('🚫 Diet session deletion cancelled');
      return;
    }

    try {
      final session = _authService.currentSession;
      if (session == null) {
        log('❌ No active session for deletion');
        _showErrorSnackBar('Please log in to delete diet plans');
        return;
      }

      final token = session.accessToken;
      log('🔑 Deleting with token: ${token.substring(0, 20)}...');

      final response = await http.delete(
        Uri.parse("${ApiContants.baseUrl}/diet/sessions/$sessionId"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 30));

      log('📡 Delete response status: ${response.statusCode}');
      log('📡 Delete response body: ${response.body}');

      if (response.statusCode == 200) {
        log('✅ Diet session deleted successfully');
        setState(() {
          dietSessions.removeWhere((session) => session.id == sessionId);
          if (currentDietPlan?.id == sessionId) {
            currentDietPlan = null;
          }
        });
        _showSuccessSnackBar('Diet plan deleted successfully');
      } else {
        log('❌ Failed to delete session: ${response.statusCode} - ${response.body}');
        _showErrorSnackBar('Failed to delete diet plan');
      }
    } on http.ClientException catch (e) {
      log('🌐 Network error deleting session: $e');
      _showErrorSnackBar('Network error. Please check your connection.');
    } catch (e) {
      log('💥 Unexpected error deleting session: $e');
      _showErrorSnackBar('Error deleting session: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    log('🔴 Showing error: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(LucideIcons.alertCircle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppPallete.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    log('🟢 Showing success: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(LucideIcons.checkCircle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  void _showWarningSnackBar(String message) {
    log('🟡 Showing warning: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 5),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppPallete.backgroundColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPallete.gradient1.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: trimester,
          isExpanded: true,
          dropdownColor: AppPallete.backgroundColor,
          style: TextStyle(color: AppPallete.textColor, fontSize: 16),
          icon: Icon(LucideIcons.chevronDown, color: AppPallete.gradient1),
          items: ["First", "Second", "Third"].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text("$value Trimester"),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                trimester = newValue;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label, 
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.w600, 
              color: AppPallete.textColor
            )
          ),
          SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppPallete.gradient1.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              style: TextStyle(color: AppPallete.textColor, fontSize: 16),
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: AppPallete.gradient1),
                hintText: "Enter ${label.toLowerCase()}",
                hintStyle: TextStyle(
                  color: AppPallete.textColor.withOpacity(0.5),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: AppPallete.backgroundColor.withOpacity(0.8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppPallete.gradient1, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputTab() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Container(
                padding: EdgeInsets.all(24),
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
                  border: Border.all(color: AppPallete.gradient1.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.utensils,
                      size: 48,
                      color: AppPallete.gradient1,
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Create Your Personalized Diet Plan",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppPallete.textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Get AI-powered nutrition recommendations tailored to your pregnancy journey",
                      style: TextStyle(
                        fontSize: 14,
                        color: AppPallete.textColor.withOpacity(0.7),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 32),
              
              Text("Select Trimester:", 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppPallete.textColor)),
              SizedBox(height: 8),
              _buildDropdown(),
              SizedBox(height: 24),

              _buildTextField("Weight (kg) *", weightController, LucideIcons.scale),
              _buildTextField("Health Conditions (if any)", healthController, LucideIcons.heart),
              _buildTextField("Dietary Preferences", dietController, LucideIcons.leaf),

              SizedBox(height: 32),

              // Create button with loading state
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Container(
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
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isLoading ? null : createNewDietPlan,
                      borderRadius: BorderRadius.circular(16),
                      child: Center(
                        child: isLoading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Text(
                                    "Generating Diet Plan...",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.sparkles, color: Colors.white),
                                  SizedBox(width: 12),
                                  Text(
                                    "Generate Diet Plan",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 32),
              
              // Sessions list header
              if (dietSessions.isNotEmpty || isLoadingSessions) ...[
                Row(
                  children: [
                    Icon(LucideIcons.history, color: AppPallete.gradient1),
                    SizedBox(width: 12),
                    Text(
                      "Previous Diet Plans",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppPallete.textColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
              ],
              
              if (isLoadingSessions)
                Container(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppPallete.gradient1),
                        SizedBox(height: 16),
                        Text(
                          "Loading diet plans...",
                          style: TextStyle(
                            color: AppPallete.textColor.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (dietSessions.isNotEmpty) ...[
                ...dietSessions.map((session) => _buildSessionCard(session)).toList(),
              ] else ...[
                Container(
                  padding: EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.utensils,
                        size: 48,
                        color: AppPallete.textColor.withOpacity(0.3),
                      ),
                      SizedBox(height: 16),
                      Text(
                        "No diet plans yet",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppPallete.textColor.withOpacity(0.7),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Create your first personalized diet plan above",
                        style: TextStyle(
                          fontSize: 14,
                          color: AppPallete.textColor.withOpacity(0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCard(DietPlan session) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPallete.gradient1.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              currentDietPlan = session;
            });
            _tabController.animateTo(1);
          },
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppPallete.gradient1, AppPallete.gradient2],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    session.trimester[0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.title,
                        style: TextStyle(
                          color: AppPallete.textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "${session.trimester} Trimester • ${session.weight}kg",
                        style: TextStyle(
                          color: AppPallete.textColor.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Created: ${session.createdAt.day}/${session.createdAt.month}/${session.createdAt.year}",
                        style: TextStyle(
                          color: AppPallete.textColor.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(LucideIcons.moreVertical, color: AppPallete.textColor.withOpacity(0.7)),
                  color: AppPallete.backgroundColor,
                  onSelected: (value) {
                    if (value == 'delete') {
                      deleteDietSession(session.id);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsTab() {
    if (currentDietPlan == null) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppPallete.gradient1.withOpacity(0.1),
                      AppPallete.gradient2.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  LucideIcons.utensils,
                  size: 80,
                  color: AppPallete.gradient1,
                ),
              ),
              SizedBox(height: 24),
              Text(
                "No Diet Plan Selected",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppPallete.textColor,
                ),
              ),
              SizedBox(height: 12),
              Text(
                "Create a new diet plan or select from your previous plans",
                style: TextStyle(
                  fontSize: 16,
                  color: AppPallete.textColor.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(0),
                icon: Icon(LucideIcons.plus),
                label: Text("Create Diet Plan"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPallete.gradient1,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final plan = currentDietPlan!;
    final overview = plan.dietPlan['overview'] as Map<String, dynamic>?;
    final mealPlans = plan.dietPlan['meal_plans'] as List<dynamic>?;
    final tips = plan.dietPlan['tips'] as List<dynamic>?;
    final supplements = plan.dietPlan['supplements'] as List<dynamic>?;

    // Check if the plan has actual content
    bool hasContent = (mealPlans?.isNotEmpty ?? false) || 
                     (tips?.isNotEmpty ?? false) || 
                     (supplements?.isNotEmpty ?? false);

    if (!hasContent) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.withOpacity(0.1),
                      Colors.orange.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  LucideIcons.clock,
                  size: 80,
                  color: Colors.orange,
                ),
              ),
              SizedBox(height: 24),
              Text(
                "Diet Plan Processing",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppPallete.textColor,
                ),
              ),
              SizedBox(height: 12),
              Text(
                "Your diet plan was created but the AI content generation appears to be incomplete. Please contact support or try creating a new plan.",
                style: TextStyle(
                  fontSize: 16,
                  color: AppPallete.textColor.withOpacity(0.7),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: loadDietSessions,
                    icon: Icon(LucideIcons.refreshCw),
                    label: Text("Refresh"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPallete.gradient1,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _tabController.animateTo(0),
                    icon: Icon(LucideIcons.plus),
                    label: Text("New Plan"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppPallete.gradient1, AppPallete.gradient2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppPallete.gradient1.withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(LucideIcons.utensils, color: Colors.white, size: 32),
                  SizedBox(height: 12),
                  Text(
                    plan.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    "${plan.trimester} Trimester • ${plan.weight}kg",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Overview
            if (overview != null) _buildOverviewCard(overview),

            SizedBox(height: 24),

            // Meal Plans
            if (mealPlans != null && mealPlans.isNotEmpty) ...[
              Text(
                'Meal Plans',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppPallete.textColor,
                ),
              ),
              SizedBox(height: 16),
              
              // Meal Plan Selector
              Container(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: mealPlans.length,
                  itemBuilder: (context, index) {
                    final isSelected = selectedMealPlan == index;
                    return GestureDetector(
                      onTap: () => setState(() => selectedMealPlan = index),
                      child: Container(
                        margin: EdgeInsets.only(right: 12),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(colors: [AppPallete.gradient1, AppPallete.gradient2])
                              : null,
                          color: isSelected ? null : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: isSelected ? Colors.transparent : AppPallete.gradient1.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          mealPlans[index]['type'] ?? 'Plan ${index + 1}',
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppPallete.textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 16),

              _buildMealPlanCard(mealPlans[selectedMealPlan]),
            ],

            SizedBox(height: 24),

            // Tips
            if (tips != null && tips.isNotEmpty) _buildTipsCard(tips),

            SizedBox(height: 24),

            // Supplements
            if (supplements != null && supplements.isNotEmpty) _buildSupplementsCard(supplements),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(Map<String, dynamic> overview) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPallete.gradient1.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.info, color: AppPallete.gradient1),
              SizedBox(width: 12),
              Text(
                "Nutrition Overview",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppPallete.textColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          _buildInfoRow("Daily Calories", overview['calories_per_day']?.toString() ?? 'N/A'),
          
          if (overview['key_nutrients'] != null) ...[
            SizedBox(height: 12),
            Text("Key Nutrients:", style: TextStyle(fontWeight: FontWeight.w600, color: AppPallete.textColor)),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (overview['key_nutrients'] as List).map((nutrient) => 
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppPallete.gradient1.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppPallete.gradient1.withOpacity(0.3)),
                  ),
                  child: Text(
                    nutrient.toString(),
                    style: TextStyle(color: AppPallete.gradient1, fontSize: 12),
                  ),
                ),
              ).toList(),
            ),
          ],

          if (overview['foods_to_avoid'] != null) ...[
            SizedBox(height: 16),
            Text("Foods to Avoid:", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red[300])),
            SizedBox(height: 8),
            ...((overview['foods_to_avoid'] as List).map((food) => 
              Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(LucideIcons.x, size: 16, color: Colors.red[300]),
                    SizedBox(width: 8),
                    Expanded(child: Text(food.toString(), style: TextStyle(color: Colors.red[300]))),
                  ],
                ),
              ),
            )).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: AppPallete.textColor)),
          Text(value, style: TextStyle(color: AppPallete.textColor.withOpacity(0.8))),
        ],
      ),
    );
  }

  Widget _buildMealPlanCard(Map<String, dynamic> mealPlan) {
    final meals = mealPlan['meals'] as Map<String, dynamic>?;
    if (meals == null) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPallete.gradient1.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${mealPlan['type']} Plan",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppPallete.textColor),
          ),
          SizedBox(height: 16),
          
          ...meals.entries.where((entry) => entry.key != 'snacks').map((entry) {
            final mealType = entry.key;
            final mealData = entry.value as Map<String, dynamic>;
            return _buildMealCard(mealType, mealData);
          }).toList(),

          // Snacks
          if (meals['snacks'] != null) _buildSnacksCard(meals['snacks'] as List),
        ],
      ),
    );
  }

  Widget _buildMealCard(String mealType, Map<String, dynamic> mealData) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPallete.backgroundColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPallete.gradient1.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                mealType.toUpperCase(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppPallete.gradient1,
                ),
              ),
              if (mealData['calories'] != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppPallete.gradient1.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${mealData['calories']} cal",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppPallete.gradient1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8),
          if (mealData['name'] != null)
            Text(
              mealData['name'].toString(),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppPallete.textColor,
              ),
            ),
          if (mealData['items'] != null) ...[
            SizedBox(height: 8),
            ...(mealData['items'] as List).map((item) => 
              Padding(
                padding: EdgeInsets.only(left: 16, bottom: 4),
                child: Row(
                  children: [
                    Icon(LucideIcons.dot, size: 16, color: AppPallete.textColor.withOpacity(0.7)),
                    SizedBox(width: 8),
                    Expanded(child: Text(item.toString(), style: TextStyle(color: AppPallete.textColor.withOpacity(0.8)))),
                  ],
                ),
              ),
            ).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildSnacksCard(List snacks) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPallete.backgroundColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPallete.gradient1.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "SNACKS",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppPallete.gradient1,
            ),
          ),
          SizedBox(height: 8),
          ...snacks.map((snack) {
            if (snack is Map<String, dynamic>) {
              return Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (snack['name'] != null)
                      Text(snack['name'].toString(), style: TextStyle(color: AppPallete.textColor, fontWeight: FontWeight.w600)),
                    if (snack['items'] != null)
                      ...((snack['items'] as List).map((item) => 
                        Padding(
                          padding: EdgeInsets.only(left: 16, top: 4),
                          child: Text("• ${item.toString()}", style: TextStyle(color: AppPallete.textColor.withOpacity(0.8))),
                        ),
                      )).toList(),
                  ],
                ),
              );
            }
            return Text(snack.toString(), style: TextStyle(color: AppPallete.textColor.withOpacity(0.8)));
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTipsCard(List tips) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPallete.gradient1.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.lightbulb, color: AppPallete.gradient1),
              SizedBox(width: 12),
              Text(
                "Helpful Tips",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppPallete.textColor),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...tips.map((tip) => 
            Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppPallete.gradient1,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(child: Text(tip.toString(), style: TextStyle(color: AppPallete.textColor.withOpacity(0.8), height: 1.5))),
                ],
              ),
            ),
          ).toList(),
        ],
      ),
    );
  }

  Widget _buildSupplementsCard(List supplements) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPallete.gradient1.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.pill, color: AppPallete.gradient1),
              SizedBox(width: 12),
              Text(
                "Recommended Supplements",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppPallete.textColor),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...supplements.map((supplement) {
            if (supplement is Map<String, dynamic>) {
              return Container(
                margin: EdgeInsets.only(bottom: 16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppPallete.backgroundColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppPallete.gradient1.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (supplement['name'] != null)
                      Text(supplement['name'].toString(), style: TextStyle(color: AppPallete.textColor, fontWeight: FontWeight.w600, fontSize: 16)),
                    if (supplement['dosage'] != null) ...[
                      SizedBox(height: 4),
                      Text("Dosage: ${supplement['dosage']}", style: TextStyle(color: AppPallete.gradient1, fontSize: 14)),
                    ],
                    if (supplement['reason'] != null) ...[
                      SizedBox(height: 4),
                      Text(supplement['reason'].toString(), style: TextStyle(color: AppPallete.textColor.withOpacity(0.8), fontSize: 14)),
                    ],
                  ],
                ),
              );
            }
            return Text(supplement.toString(), style: TextStyle(color: AppPallete.textColor.withOpacity(0.8)));
          }).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.backgroundColor,
      appBar: AppBar(
        title: Text('Pregnancy Diet Plans', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        iconTheme: IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Create Plan', icon: Icon(LucideIcons.plus)),
            Tab(text: 'View Plan', icon: Icon(LucideIcons.utensils)),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          indicatorColor: Colors.white,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppPallete.backgroundColor,
              AppPallete.gradient1.withOpacity(0.03),
              AppPallete.backgroundColor,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildInputTab(),
            _buildResultsTab(),
          ],
        ),
      ),
    );
  }
}