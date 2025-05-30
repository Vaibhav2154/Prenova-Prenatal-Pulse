// lib/features/medicine_tracker/services/medication_storage_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/medication_model.dart';

class MedicationStorageService {
  static const String _medicationsKey = 'medications';
  static const String _logsKey = 'medication_logs';

  // Medications CRUD
  Future<void> saveMedications(List<Medication> medications) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = medications.map((med) => med.toJson()).toList();
    await prefs.setString(_medicationsKey, jsonEncode(jsonList));
  }

  Future<List<Medication>> getMedications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_medicationsKey);
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => Medication.fromJson(json)).toList();
  }

  Future<void> addMedication(Medication medication) async {
    final medications = await getMedications();
    medications.add(medication);
    await saveMedications(medications);
  }

  Future<void> updateMedication(Medication updatedMedication) async {
    final medications = await getMedications();
    final index = medications.indexWhere((med) => med.id == updatedMedication.id);
    if (index != -1) {
      medications[index] = updatedMedication;
      await saveMedications(medications);
    }
  }

  Future<void> deleteMedication(String medicationId) async {
    final medications = await getMedications();
    medications.removeWhere((med) => med.id == medicationId);
    await saveMedications(medications);
  }

  // Medication Logs CRUD
  Future<void> saveLogs(List<MedicationLog> logs) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = logs.map((log) => log.toJson()).toList();
    await prefs.setString(_logsKey, jsonEncode(jsonList));
  }

  Future<List<MedicationLog>> getLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_logsKey);
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => MedicationLog.fromJson(json)).toList();
  }

  Future<void> addLog(MedicationLog log) async {
    final logs = await getLogs();
    logs.add(log);
    await saveLogs(logs);
  }

  Future<List<MedicationLog>> getLogsForDate(DateTime date) async {
    final logs = await getLogs();
    return logs.where((log) {
      return log.scheduledTime.year == date.year &&
             log.scheduledTime.month == date.month &&
             log.scheduledTime.day == date.day;
    }).toList();
  }

  Future<List<MedicationLog>> getLogsForMedication(String medicationId) async {
    final logs = await getLogs();
    return logs.where((log) => log.medicationId == medicationId).toList();
  }
}