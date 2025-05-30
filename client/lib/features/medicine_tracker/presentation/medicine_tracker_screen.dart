import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:prenova/core/theme/app_pallete.dart';
import 'package:prenova/features/medicine_tracker/models/medication_model.dart';
import 'package:prenova/features/medicine_tracker/presentation/add_medication_screen.dart';
import 'package:prenova/features/medicine_tracker/services/medication_storage_service.dart';

class MedicineTrackerScreen extends StatefulWidget {
  const MedicineTrackerScreen({super.key});

  @override
  State<MedicineTrackerScreen> createState() => _MedicineTrackerScreenState();
}

class _MedicineTrackerScreenState extends State<MedicineTrackerScreen>
    with TickerProviderStateMixin {
  final MedicationStorageService _storageService = MedicationStorageService();
  List<Medication> _medications = [];
  List<MedicationLog> _todayLogs = [];
  DateTime _selectedDate = DateTime.now();
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

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
    
    _loadData();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final medications = await _storageService.getMedications();
    final logs = await _storageService.getLogsForDate(_selectedDate);
    
    setState(() {
      _medications = medications.where((med) => med.isActive).toList();
      _todayLogs = logs;
    });
  }

  Future<void> _markAsTaken(String medicationId, DateTime scheduledTime) async {
    final log = MedicationLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      medicationId: medicationId,
      scheduledTime: scheduledTime,
      takenTime: DateTime.now(),
      isTaken: true,
    );
    
    await _storageService.addLog(log);
    _loadData();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(LucideIcons.check, color: Colors.white),
            SizedBox(width: 12),
            Text('Medicine marked as taken!'),
          ],
        ),
        backgroundColor: Colors.green,
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
          'Medicine Tracker',
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
        actions: [
          IconButton(
            icon: Icon(LucideIcons.plus, color: Colors.white),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddMedicationScreen()),
              );
              if (result == true) _loadData();
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              _buildTodayOverview(),
              SizedBox(height: 24),
              _buildMedicationList(),
              SizedBox(height: 24),
              _buildWeeklyProgress(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayOverview() {
    final totalDoses = _getTotalDosesForToday();
    final takenDoses = _todayLogs.where((log) => log.isTaken).length;
    final adherenceRate = totalDoses > 0 ? (takenDoses / totalDoses * 100) : 0.0;

    return Container(
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
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Today\'s Progress',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildOverviewStat('Taken', '$takenDoses', LucideIcons.check),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildOverviewStat('Total', '$totalDoses', LucideIcons.pill),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildOverviewStat('Rate', '${adherenceRate.toInt()}%', LucideIcons.target),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationList() {
    if (_medications.isEmpty) {
      return Container(
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(LucideIcons.pill, size: 48, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No medications added yet',
              style: TextStyle(
                color: AppPallete.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the + button to add your first medication',
              style: TextStyle(
                color: AppPallete.textColor.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Medications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppPallete.textColor,
          ),
        ),
        SizedBox(height: 16),
        ...(_medications.map((medication) => _buildMedicationCard(medication))),
      ],
    );
  }

  Widget _buildMedicationCard(Medication medication) {
    final todayDoses = _getTodayDosesForMedication(medication);
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
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
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(medication.category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(medication.category),
                    color: _getCategoryColor(medication.category),
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.name,
                        style: TextStyle(
                          color: AppPallete.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        medication.dosage,
                        style: TextStyle(
                          color: AppPallete.textColor.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        medication.frequency,
                        style: TextStyle(
                          color: AppPallete.gradient1,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (todayDoses.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppPallete.backgroundColor.withOpacity(0.5),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Column(
                children: todayDoses.map((dose) => _buildDoseItem(medication, dose)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDoseItem(Medication medication, DateTime doseTime) {
    final log = _todayLogs.firstWhere(
      (log) => log.medicationId == medication.id && 
               log.scheduledTime.hour == doseTime.hour &&
               log.scheduledTime.minute == doseTime.minute,
      orElse: () => MedicationLog(
        id: '',
        medicationId: medication.id,
        scheduledTime: doseTime,
      ),
    );

    final isOverdue = DateTime.now().isAfter(doseTime) && !log.isTaken;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: log.isTaken 
                  ? Colors.green 
                  : isOverdue 
                      ? Colors.red 
                      : AppPallete.gradient1,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(width: 12),
          Text(
            '${doseTime.hour.toString().padLeft(2, '0')}:${doseTime.minute.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: AppPallete.textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          Spacer(),
          if (log.isTaken)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Taken',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed: () => _markAsTaken(medication.id, doseTime),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPallete.gradient1,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Take',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgress() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.barChart3, color: AppPallete.gradient1, size: 20),
              SizedBox(width: 8),
              Text(
                'Weekly Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppPallete.textColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Progress chart coming soon...',
            style: TextStyle(
              color: AppPallete.textColor.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  int _getTotalDosesForToday() {
    int total = 0;
    for (var medication in _medications) {
      total += medication.times.length;
    }
    return total;
  }

  List<DateTime> _getTodayDosesForMedication(Medication medication) {
    final today = DateTime.now();
    return medication.times.map((timeString) {
      final parts = timeString.split(':');
      return DateTime(
        today.year,
        today.month,
        today.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    }).toList()..sort();
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Prenatal Vitamins':
        return AppPallete.gradient2;
      case 'Prescription':
        return AppPallete.gradient1;
      case 'Supplements':
        return AppPallete.gradient3;
      default:
        return AppPallete.gradient1;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Prenatal Vitamins':
        return Icons.food_bank;
      case 'Prescription':
        return LucideIcons.pill;
      case 'Supplements':
        return LucideIcons.leaf;
      default:
        return LucideIcons.pill;
    }
  }
}