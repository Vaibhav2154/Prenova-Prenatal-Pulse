// lib/features/medicine_tracker/models/medication_model.dart
class Medication {
  final String id;
  final String name;
  final String dosage;
  final String frequency; // "Daily", "Twice daily", "Three times daily", etc.
  final List<String> times; // ["08:00", "20:00"]
  final DateTime startDate;
  final DateTime? endDate;
  final String notes;
  final bool isActive;
  final String category; // "Prenatal Vitamins", "Prescription", "Supplements"

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.times,
    required this.startDate,
    this.endDate,
    this.notes = '',
    this.isActive = true,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'dosage': dosage,
    'frequency': frequency,
    'times': times,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'notes': notes,
    'isActive': isActive,
    'category': category,
  };

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
    id: json['id'],
    name: json['name'],
    dosage: json['dosage'],
    frequency: json['frequency'],
    times: List<String>.from(json['times']),
    startDate: DateTime.parse(json['startDate']),
    endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
    notes: json['notes'] ?? '',
    isActive: json['isActive'] ?? true,
    category: json['category'],
  );
}

class MedicationLog {
  final String id;
  final String medicationId;
  final DateTime scheduledTime;
  final DateTime? takenTime;
  final bool isTaken;
  final bool isMissed;
  final String notes;

  MedicationLog({
    required this.id,
    required this.medicationId,
    required this.scheduledTime,
    this.takenTime,
    this.isTaken = false,
    this.isMissed = false,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'medicationId': medicationId,
    'scheduledTime': scheduledTime.toIso8601String(),
    'takenTime': takenTime?.toIso8601String(),
    'isTaken': isTaken,
    'isMissed': isMissed,
    'notes': notes,
  };

  factory MedicationLog.fromJson(Map<String, dynamic> json) => MedicationLog(
    id: json['id'],
    medicationId: json['medicationId'],
    scheduledTime: DateTime.parse(json['scheduledTime']),
    takenTime: json['takenTime'] != null ? DateTime.parse(json['takenTime']) : null,
    isTaken: json['isTaken'] ?? false,
    isMissed: json['isMissed'] ?? false,
    notes: json['notes'] ?? '',
  );
}