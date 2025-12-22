import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isInitialized = false;
  
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Bildirime tıklandı: ${details.payload}');
      },
    );
    
    const androidChannel = AndroidNotificationChannel(
      'emergency_channel',
      'Acil Durum Bildirimleri',
      description: 'Kritik acil durum uyarıları',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );
    
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
    
    _isInitialized = true;
    debugPrint('✅ Bildirim sistemi başlatıldı');
  }
  
  static Future<void> showFallAlert() async {
    await _showCriticalNotification(
      id: 1,
      title: '🚨 DÜŞME TESPİT EDİLDİ!',
      body: 'Acil durum protokolü başlatıldı. Hemen yardım çağırılıyor...',
      payload: 'fall_detected',
    );
    await _playAlarmSound();
  }
  
  static Future<void> showInactivityAlert(int minutes) async {
    await _showCriticalNotification(
      id: 2,
      title: '⚠️ Uzun Süreli Hareketsizlik',
      body: '$minutes dakikadır hareket tespit edilemedi. Kontrol ediniz.',
      payload: 'inactivity_detected',
    );
  }
  
  static Future<void> showHeartRateAlert(int bpm) async {
    await _showCriticalNotification(
      id: 3,
      title: '💔 Anormal Kalp Atışı',
      body: 'Nabız: $bpm bpm - Normal aralığın dışında!',
      payload: 'heart_rate_abnormal',
    );
    await _playAlarmSound();
  }
  
  static Future<void> showManualEmergency() async {
    await _showCriticalNotification(
      id: 4,
      title: '🆘 MANUEL ACİL DURUM',
      body: 'Kullanıcı yardım çağırdı! Acil müdahale gerekiyor.',
      payload: 'manual_emergency',
    );
    await _playAlarmSound();
  }
  
  static Future<void> _showCriticalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'emergency_channel',
      'Acil Durum Bildirimleri',
      channelDescription: 'Kritik acil durum uyarıları',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      color: Color(0xFFFF0000),
      ledColor: Color(0xFFFF0000),
      ledOnMs: 1000,
      ledOffMs: 500,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.show(id, title, body, details, payload: payload);
  }
  
  static Future<void> _playAlarmSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/alarm.mp3'));
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
    } catch (e) {
      debugPrint('Ses çalma hatası: $e');
    }
  }
  
  static Future<void> stopAlarm() async {
    await _audioPlayer.stop();
  }
  
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
    await stopAlarm();
  }
  
  static Future<bool> checkPermission() async {
    if (!_isInitialized) await initialize();
    
    final result = await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.areNotificationsEnabled();
    
    return result ?? false;
  }
  
  static Future<bool> requestPermission() async {
    if (!_isInitialized) await initialize();
    
    final android = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    final result = await android?.requestNotificationsPermission();
    return result ?? false;
  }
}