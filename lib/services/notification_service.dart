import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:io';

class NotificationService {
  NotificationService._privateConstructor();
  static final NotificationService instance =
      NotificationService._privateConstructor();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    try {
      final dynamic tzData = await FlutterTimezone.getLocalTimezone();
      // flutter_timezone v2+ mengembalikan objek TimezoneInfo, v1 mengembalikan String
      final String currentTimeZone = tzData is String
          ? tzData
          : tzData.name.toString();
      tz.setLocalLocation(tz.getLocation(currentTimeZone));
      debugPrint('✅ Timezone otomatis: $currentTimeZone');
    } catch (e) {
      // Fallback cerdas: Coba gunakan timezone yang paling umum di Indonesia jika otomatis gagal
      try {
        // Kita bisa mencoba mendapatkan offset jam untuk menentukan apakah WIT, WITA, atau WIB
        final int offsetHours = DateTime.now().timeZoneOffset.inHours;
        if (offsetHours == 9) {
          tz.setLocalLocation(tz.getLocation('Asia/Jayapura')); // WIT (Papua)
          debugPrint('⚠️ Fallback ke Asia/Jayapura (WIT)');
        } else if (offsetHours == 8) {
          tz.setLocalLocation(tz.getLocation('Asia/Makassar')); // WITA
          debugPrint('⚠️ Fallback ke Asia/Makassar (WITA)');
        } else {
          tz.setLocalLocation(tz.getLocation('Asia/Jakarta')); // WIB
          debugPrint('⚠️ Fallback ke Asia/Jakarta (WIB)');
        }
      } catch (e2) {
        tz.setLocalLocation(tz.getLocation('UTC'));
        debugPrint('⚠️ Timezone fallback ke UTC');
      }
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('🔔 Notifikasi diklik: ${details.payload}');
      },
    );

    _isInitialized = true;
    debugPrint('✅ NotificationService berhasil diinisialisasi');
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      // Izin notifikasi dasar (Android 13+)
      await androidImplementation?.requestNotificationsPermission();

      // Izin alarm tepat (Exact Alarm) untuk Android 12+
      // Catatan: Ini biasanya otomatis diizinkan jika dideklarasikan di manifest,
      // tapi untuk beberapa perangkat perlu dicek.
      debugPrint('ℹ️ Meminta izin Notifikasi & Exact Alarm');
    } else if (Platform.isIOS) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    if (!_isInitialized) await init();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'medicine_reminder_channel',
          'Pengingat Obat',
          channelDescription: 'Notifikasi untuk jadwal minum obat Anda',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
          icon: 'ic_launcher',
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('🕒 Notifikasi dijadwalkan: $id pada $scheduledDate');
    } catch (e) {
      debugPrint('❌ Gagal menjadwalkan notifikasi: $e');
    }
  }

  // Alias untuk kompatibilitas dengan kode lama
  Future<void> scheduleNotificationFromAppTime({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) => scheduleNotification(
    id: id,
    title: title,
    body: body,
    hour: hour,
    minute: minute,
  );

  Future<void> cancel(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
