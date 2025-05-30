import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:prenova/core/theme/app_pallete.dart';
import 'package:prenova/features/medicine_tracker/models/medication_model.dart';
import 'package:prenova/features/medicine_tracker/services/medication_storage_service.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();
  final MedicationStorageService _storageService = MedicationStorageService();

  String _selectedCategory = 'Prenatal Vitamins';
  String _selectedFrequency = 'Once daily';
  List<TimeOfDay> _selectedTimes = [TimeOfDay(hour: 8, minute: 0)];
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<String> _categories = [
    'Prenatal Vitamins',
    'Prescription',
    'Supplements',
    'Pain Relief',
  ];

  final Map<String, List<TimeOfDay>> _frequencyTimes = {
    'Once daily': [TimeOfDay(hour: 8, minute: 0)],
    'Twice daily': [
      TimeOfDay(hour: 8, minute: 0),
      TimeOfDay(hour: 20, minute: 0),
    ],
    'Three times daily': [
      TimeOfDay(hour: 8, minute: 0),
      TimeOfDay(hour: 14, minute: 0),
      TimeOfDay(hour: 20, minute: 0),
    ],
    'Four times daily': [
      TimeOfDay(hour: 8, minute: 0),
      TimeOfDay(hour: 12, minute: 0),
      TimeOfDay(hour: 16, minute: 0),
      TimeOfDay(hour: 20, minute: 0),
    ],
  };

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _updateTimesForFrequency(String frequency) {
    setState(() {
      _selectedFrequency = frequency;
      _selectedTimes = List.from(_frequencyTimes[frequency] ?? []);
    });
  }

  Future<void> _selectTime(int index) async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: _selectedTimes[index],
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppPallete.gradient1,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() {
        _selectedTimes[index] = time;
      });
    }
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : (_endDate ?? DateTime.now()),
      firstDate: DateTime.now().subtract(Duration(days: 1)),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppPallete.gradient1,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        if (isStartDate) {
          _startDate = date;
        } else {
          _endDate = date;
        }
      });
    }
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) return;

    final medication = Medication(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      frequency: _selectedFrequency,
      times: _selectedTimes.map((time) => 
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
      ).toList(),
      startDate: _startDate,
      endDate: _endDate,
      notes: _notesController.text.trim(),
      category: _selectedCategory,
    );

    try {
      await _storageService.addMedication(medication);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(LucideIcons.check, color: Colors.white),
              SizedBox(width: 12),
              Text('Medication added successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(LucideIcons.alertCircle, color: Colors.white),
              SizedBox(width: 12),
              Text('Failed to add medication'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Add Medication',
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
          ),
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBasicInfoSection(),
                SizedBox(height: 24),
                _buildFrequencySection(),
                SizedBox(height: 24),
                _buildTimesSection(),
                SizedBox(height: 24),
                _buildDatesSection(),
                SizedBox(height: 24),
                _buildNotesSection(),
                SizedBox(height: 32),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppPallete.textColor,
            ),
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Medication Name',
              prefixIcon: Icon(LucideIcons.pill, color: Colors.blue[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue[600]!),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter medication name';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _dosageController,
            decoration: InputDecoration(
              labelText: 'Dosage (e.g., 500mg, 1 tablet)',
              prefixIcon: Icon(LucideIcons.activity, color: Colors.blue[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue[600]!),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter dosage';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: InputDecoration(
              labelText: 'Category',
              prefixIcon: Icon(LucideIcons.tag, color: Colors.blue[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue[600]!),
              ),
            ),
            items: _categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencySection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frequency',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppPallete.textColor,
            ),
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _frequencyTimes.keys.map((frequency) {
              final isSelected = _selectedFrequency == frequency;
              return GestureDetector(
                onTap: () => _updateTimesForFrequency(frequency),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue[600] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    frequency,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppPallete.textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimesSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Times',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppPallete.textColor,
            ),
          ),
          SizedBox(height: 16),
          ...(_selectedTimes.asMap().entries.map((entry) {
            final index = entry.key;
            final time = entry.value;
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => _selectTime(index),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.clock, color: Colors.blue[600], size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Dose ${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppPallete.textColor,
                        ),
                      ),
                      Spacer(),
                      Text(
                        time.format(context),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[600],
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(LucideIcons.chevronRight, color: Colors.grey[400], size: 16),
                    ],
                  ),
                ),
              ),
            );
          })),
        ],
      ),
    );
  }

  Widget _buildDatesSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Duration',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppPallete.textColor,
            ),
          ),
          SizedBox(height: 16),
          InkWell(
            onTap: () => _selectDate(true),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.calendar, color: Colors.blue[600], size: 20),
                  SizedBox(width: 12),
                  Text(
                    'Start Date',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppPallete.textColor,
                    ),
                  ),
                  Spacer(),
                  Text(
                    '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12),
          InkWell(
            onTap: () => _selectDate(false),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.calendar, color: Colors.grey[600], size: 20),
                  SizedBox(width: 12),
                  Text(
                    'End Date (Optional)',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppPallete.textColor,
                    ),
                  ),
                  Spacer(),
                  Text(
                    _endDate != null 
                        ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                        : 'Select date',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _endDate != null ? Colors.blue[600] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppPallete.textColor,
            ),
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add any additional notes or instructions...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue[600]!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _saveMedication,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPallete.gradient1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          'Add Medication',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}