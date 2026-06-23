import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized || kIsWeb) return;

    try {
      // Initialize Timezones
      tz.initializeTimeZones();
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('Could not get local timezone: $e. Falling back to America/Lima.');
      try {
        tz.setLocalLocation(tz.getLocation('America/Lima'));
      } catch (_) {}
    }

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification clicked: ${details.payload}');
      },
    );

    _initialized = true;
    
    // Request Android 13+ permissions
    await requestPermissions();
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;
    
    final androidImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  Future<void> showInstant(int id, String title, String body) async {
    if (kIsWeb) return;
    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'agenda_notifications',
            'Agenda Reminders',
            channelDescription: 'Notifications for tasks, events and habits',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error showing instant notification: $e');
    }
  }

  Future<void> schedule(int id, String title, String body, DateTime date) async {
    if (kIsWeb) return;
    
    // If the date is in the past, do not schedule
    if (date.isBefore(DateTime.now())) return;

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(date, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'agenda_notifications',
            'Agenda Reminders',
            channelDescription: 'Notifications for tasks, events and habits',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  Future<void> cancel(int id) async {
    if (kIsWeb) return;
    try {
      await _notificationsPlugin.cancel(id);
    } catch (e) {
      debugPrint('Error canceling notification: $e');
    }
  }

  // --- Date Formatting Helper in Spanish ---
  static String formatNotificationDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final timeStr = DateFormat('h:mm a', 'es').format(dateTime);

    if (today == target) {
      // Replace time numbers in format to text if needed, but 9:00 PM is clear
      // We can also say "las 9 de la noche" like in the audio if we extract hour,
      // but standard time string like "9:00 PM" is universally clean.
      // Let's do a friendly converter for typical hours to sound conversational!
      return 'hoy a las ${_getFriendlyTime(dateTime)}';
    } else if (target == today.add(const Duration(days: 1))) {
      return 'mañana a las ${_getFriendlyTime(dateTime)}';
    } else {
      return 'el ${DateFormat('d de MMMM', 'es').format(dateTime)} a las ${_getFriendlyTime(dateTime)}';
    }
  }

  static String _getFriendlyTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final minuteStr = minute == 0 ? '' : ' y $minute';
    
    String period;
    int displayHour = hour;
    
    if (hour >= 12) {
      if (hour >= 19) {
        period = 'de la noche';
      } else {
        period = 'de la tarde';
      }
      if (hour > 12) displayHour = hour - 12;
    } else {
      if (hour >= 5) {
        period = 'de la mañana';
      } else {
        period = 'de la madrugada';
      }
      if (hour == 0) displayHour = 12;
    }

    final hourStr = displayHour == 1 ? 'la una' : 'las $displayHour';
    return '$hourStr$minuteStr $period';
  }
}
