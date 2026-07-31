import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../db/database_service.dart';

const String _channelId = 'plant-reminders';
const String _channelName = 'Remindere plante';
const String _channelDescription = 'Notificări pentru udare, pulverizare și alte îngrijiri ale plantelor';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    tz.initializeTimeZones();
    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
    } catch (_) {
      // dacă fusul orar nu poate fi determinat, rămânem pe UTC (implicit)
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
        ));
  }

  Future<bool> requestPermissions() async {
    if (Platform.isIOS || Platform.isMacOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    if (Platform.isAndroid) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  Future<int> scheduleReminder({
    required String plantName,
    required String label,
    required int dueAtEpochMs,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch.remainder(1 << 31);
    final scheduledDate = tz.TZDateTime.fromMillisecondsSinceEpoch(tz.local, dueAtEpochMs);
    final safeDate = scheduledDate.isBefore(tz.TZDateTime.now(tz.local))
        ? tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5))
        : scheduledDate;

    await _plugin.zonedSchedule(
      id: id,
      title: '$label: $plantName',
      body: 'E timpul pentru "${label.toLowerCase()}" la planta ta.',
      scheduledDate: safeDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(_channelId, _channelName, channelDescription: _channelDescription),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    return id;
  }

  Future<void> cancel(int? notificationId) async {
    if (notificationId == null) return;
    await _plugin.cancel(id: notificationId);
  }

  /// Marchează reminderul ca "făcut" acum și reprogramează automat
  /// pentru data viitoare (now + intervalDays), inclusiv notificarea locală.
  Future<void> markReminderDoneAndReschedule(ReminderRow reminder, String plantName) async {
    await cancel(reminder.notificationId);

    final now = DateTime.now().millisecondsSinceEpoch;
    final nextDueAt = now + reminder.intervalDays * 24 * 60 * 60 * 1000;
    final newNotificationId = await scheduleReminder(
      plantName: plantName,
      label: reminder.label,
      dueAtEpochMs: nextDueAt,
    );

    await DatabaseService.instance.updateReminderSchedule(
      id: reminder.id,
      nextDueAt: nextDueAt,
      lastDoneAt: now,
      notificationId: newNotificationId,
    );
  }
}
