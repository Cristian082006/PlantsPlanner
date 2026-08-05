import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../data/care_info.dart';
import '../db/database_service.dart';
import 'weather_service.dart';

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
  /// Pentru remindere de udare, intervalul e recalculat din temperatura de
  /// afară și luna curentă, pornind mereu de la baza speciei (plant.wateringDays)
  /// ca să nu se acumuleze eroare de la o ajustare la alta.
  Future<void> markReminderDoneAndReschedule(ReminderRow reminder, String plantName) async {
    await cancel(reminder.notificationId);

    final now = DateTime.now().millisecondsSinceEpoch;
    var intervalDays = reminder.intervalDays;

    if (reminder.type == 'udare') {
      final plant = await DatabaseService.instance.getPlant(reminder.plantId);
      if (plant != null) {
        final outdoorTemp = await WeatherService.instance.getOutdoorTemperatureC();
        intervalDays = adjustedWateringDays(baseDays: plant.wateringDays, outdoorTempC: outdoorTemp);
      }
    }

    final nextDueAt = now + intervalDays * 24 * 60 * 60 * 1000;
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
      intervalDays: intervalDays,
    );
  }

  /// Re-syncs every already-scheduled watering reminder to the current
  /// outdoor temperature and month, without marking anything as "done" —
  /// the next-due date shifts earlier/later around its existing anchor
  /// (last watering, or plant creation if never watered yet).
  Future<int> recalculateAllWateringReminders() async {
    final outdoorTemp = await WeatherService.instance.getOutdoorTemperatureC();
    final plants = await DatabaseService.instance.getPlants();
    var updated = 0;

    for (final plant in plants) {
      final reminders = await DatabaseService.instance.getRemindersForPlant(plant.id);
      final newIntervalDays = adjustedWateringDays(baseDays: plant.wateringDays, outdoorTempC: outdoorTemp);

      for (final reminder in reminders) {
        if (reminder.type != 'udare') continue;

        final anchorMs = reminder.lastDoneAt ?? plant.createdAt;
        final nextDueAt = anchorMs + newIntervalDays * 24 * 60 * 60 * 1000;

        await cancel(reminder.notificationId);
        final newNotificationId = await scheduleReminder(
          plantName: plant.commonName,
          label: reminder.label,
          dueAtEpochMs: nextDueAt,
        );

        await DatabaseService.instance.updateReminderDueDate(
          id: reminder.id,
          nextDueAt: nextDueAt,
          intervalDays: newIntervalDays,
          notificationId: newNotificationId,
        );
        updated++;
      }
    }

    return updated;
  }
}
