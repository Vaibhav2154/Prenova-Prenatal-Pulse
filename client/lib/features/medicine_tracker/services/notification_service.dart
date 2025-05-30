// lib/features/medicine_tracker/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/medication_model.dart';

class MedicationNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(settings);
  }

  static Future<void> scheduleMedicationReminders(Medication medication) async {
    // Cancel existing notifications for this medication
    await cancelMedicationReminders(medication.id);

    for (String timeString in medication.times) {
      final time = _parseTime(timeString);
      final scheduledDate = _getNextScheduledDate(time);
      
      await _notifications.zonedSchedule(
        medication.id.hashCode + medication.times.indexOf(timeString),
        'Medicine Reminder',
        'Time to take ${medication.name} (${medication.dosage})',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'medication_channel',
            'Medication Reminders',
            channelDescription: 'Reminders for taking medications',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  static Future<void> cancelMedicationReminders(String medicationId) async {
    // Cancel all notifications for this medication
    await _notifications.cancel(medicationId.hashCode);
  }

  static DateTime _parseTime(String timeString) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  static tz.TZDateTime _getNextScheduledDate(DateTime time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }
}