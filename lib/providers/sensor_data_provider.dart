import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:convert';
import '../services/notification_service.dart';
import '../services/emergency_service.dart';
import '../models/sensor_record.dart';

class SensorDataProvider extends ChangeNotifier {
  BuildContext? _context;
  
  void setContext(BuildContext context) {
    _context = context;
  }
  
  // Bluetooth bağlantı durumu
  bool _isConnected = false;
  String _deviceName = '';
  
  // Sensör verileri
  double _heartRate = 0;
  double _accelerometerX = 0;
  double _accelerometerY = 0;
  double _accelerometerZ = 0;
  bool _isMoving = true;
  DateTime _lastMovementTime = DateTime.now();
  
  // Alarm durumları
  bool _fallDetected = false;
  bool _inactivityAlarm = false;
  bool _heartRateAlarm = false;
  bool _manualAlarm = false;
  
  // Eşik değerleri
  double _minHeartRate = 40;
  double _maxHeartRate = 120;
  int _inactivityTimeMinutes = 30;
  final double _fallThreshold = 3.5;
  
  // Grafik için geçmiş veriler (anlık)
  final List<HeartRateData> _heartRateHistory = [];
  final int _maxHistoryLength = 50;
  
  // 🆕 GERÇEK VERİ KAYITLARI
  final List<SensorRecord> _sensorRecords = [];
  final List<AlarmRecord> _alarmRecords = [];
  DateTime? _lastSaveTime;
  final int _saveIntervalSeconds = 30; // 30 saniyede bir kaydet

  // Getters
  bool get isConnected => _isConnected;
  String get deviceName => _deviceName;
  double get heartRate => _heartRate;
  double get accelerometerX => _accelerometerX;
  double get accelerometerY => _accelerometerY;
  double get accelerometerZ => _accelerometerZ;
  bool get isMoving => _isMoving;
  bool get fallDetected => _fallDetected;
  bool get inactivityAlarm => _inactivityAlarm;
  bool get heartRateAlarm => _heartRateAlarm;
  bool get manualAlarm => _manualAlarm;
  double get minHeartRate => _minHeartRate;
  double get maxHeartRate => _maxHeartRate;
  int get inactivityTimeMinutes => _inactivityTimeMinutes;
  List<HeartRateData> get heartRateHistory => _heartRateHistory;
  
  // 🆕 History getters
  List<SensorRecord> get sensorRecords => _sensorRecords;
  List<AlarmRecord> get alarmRecords => _alarmRecords;
  
  bool get hasActiveAlarm => 
      _fallDetected || _inactivityAlarm || _heartRateAlarm || _manualAlarm;
  
  // 🆕 Veri yükleme (uygulama başlangıcında çağrılmalı)
  Future<void> loadHistoryData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Sensör kayıtlarını yükle
      final sensorJson = prefs.getString('sensor_records');
      if (sensorJson != null) {
        final List<dynamic> decoded = jsonDecode(sensorJson);
        _sensorRecords.clear();
        _sensorRecords.addAll(
          decoded.map((e) => SensorRecord.fromJson(e)).toList()
        );
      }
      
      // Alarm kayıtlarını yükle
      final alarmJson = prefs.getString('alarm_records');
      if (alarmJson != null) {
        final List<dynamic> decoded = jsonDecode(alarmJson);
        _alarmRecords.clear();
        _alarmRecords.addAll(
          decoded.map((e) => AlarmRecord.fromJson(e)).toList()
        );
      }
      
      debugPrint('✅ Geçmiş veriler yüklendi: ${_sensorRecords.length} sensör, ${_alarmRecords.length} alarm');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Veri yükleme hatası: $e');
    }
  }
  
  // 🆕 Veri kaydetme
  Future<void> _saveHistoryData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Son 7 günün verilerini sakla (performans için)
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      _sensorRecords.removeWhere((r) => r.timestamp.isBefore(weekAgo));
      _alarmRecords.removeWhere((r) => r.timestamp.isBefore(weekAgo));
      
      // JSON'a çevir ve kaydet
      await prefs.setString('sensor_records', 
        jsonEncode(_sensorRecords.map((e) => e.toJson()).toList()));
      await prefs.setString('alarm_records',
        jsonEncode(_alarmRecords.map((e) => e.toJson()).toList()));
      
      debugPrint('💾 Veriler kaydedildi: ${_sensorRecords.length} sensör, ${_alarmRecords.length} alarm');
    } catch (e) {
      debugPrint('❌ Veri kaydetme hatası: $e');
    }
  }
  
  void updateConnectionStatus(bool status, String name) {
    _isConnected = status;
    _deviceName = name;
    notifyListeners();
  }
  
  void updateSensorData({
    double? heartRate,
    double? accX,
    double? accY,
    double? accZ,
  }) {
    if (heartRate != null) {
      _heartRate = heartRate;
      _addHeartRateToHistory(heartRate);
      _checkHeartRateAlarm();
    }
    
    if (accX != null) _accelerometerX = accX;
    if (accY != null) _accelerometerY = accY;
    if (accZ != null) _accelerometerZ = accZ;
    
    if (accX != null || accY != null || accZ != null) {
      _checkFallDetection();
      _checkMovement();
    }
    
    // 🆕 30 saniyede bir kaydet
    _autoSaveSensorData();
    
    notifyListeners();
  }
  
  // 🆕 Otomatik kayıt (30 saniyede bir)
  void _autoSaveSensorData() {
    final now = DateTime.now();
    if (_lastSaveTime == null || 
        now.difference(_lastSaveTime!).inSeconds >= _saveIntervalSeconds) {
      
      _sensorRecords.add(SensorRecord(
        timestamp: now,
        heartRate: _heartRate,
        accelerometerX: _accelerometerX,
        accelerometerY: _accelerometerY,
        accelerometerZ: _accelerometerZ,
        isMoving: _isMoving,
      ));
      
      _lastSaveTime = now;
      _saveHistoryData();
    }
  }
  
  void _addHeartRateToHistory(double value) {
    _heartRateHistory.add(HeartRateData(DateTime.now(), value));
    if (_heartRateHistory.length > _maxHistoryLength) {
      _heartRateHistory.removeAt(0);
    }
  }
  
  void _checkFallDetection() {
    double totalAcceleration = sqrt(
        _accelerometerX * _accelerometerX +
        _accelerometerY * _accelerometerY +
        _accelerometerZ * _accelerometerZ
    );
    
    debugPrint('🔍 Düşme kontrolü: ${totalAcceleration.toStringAsFixed(2)} G (Eşik: $_fallThreshold G)');
    
    if (totalAcceleration > _fallThreshold) {
      _fallDetected = true;
      debugPrint('🚨 DÜŞME TESPİT EDİLDİ! İvme: ${totalAcceleration.toStringAsFixed(2)} G');
      
      // 🆕 Alarm kaydı ekle
      _saveAlarmRecord('fall', 'Düşme tespit edildi', 
        accelerometerTotal: totalAcceleration);
      
      _triggerAlarm('Düşme tespit edildi!', 'DÜŞME TESPİT EDİLDİ');
    }
  }
  
  void _checkMovement() {
    double movement = _accelerometerX.abs() + 
                      _accelerometerY.abs() + 
                      _accelerometerZ.abs();
    
    if (movement > 0.1) {
      _isMoving = true;
      _lastMovementTime = DateTime.now();
      _inactivityAlarm = false;
    } else {
      _isMoving = false;
      _checkInactivity();
    }
  }
  
  void _checkInactivity() {
    int minutesSinceLastMovement = 
        DateTime.now().difference(_lastMovementTime).inMinutes;
    
    if (minutesSinceLastMovement >= _inactivityTimeMinutes) {
      _inactivityAlarm = true;
      
      // 🆕 Alarm kaydı ekle
      _saveAlarmRecord('inactivity', 
        'Uzun süreli hareketsizlik: $minutesSinceLastMovement dakika');
      
      _triggerAlarm('Uzun süreli hareketsizlik tespit edildi!', 
        'HAREKETSİZLİK TESPİT EDİLDİ');
    }
  }
  
  void _checkHeartRateAlarm() {
    if (_heartRate < _minHeartRate || _heartRate > _maxHeartRate) {
      _heartRateAlarm = true;
      
      // 🆕 Alarm kaydı ekle
      _saveAlarmRecord('heart_rate', 'Anormal kalp atışı: $_heartRate bpm',
        heartRate: _heartRate);
      
      _triggerAlarm('Anormal kalp atışı: ${_heartRate.toInt()} bpm',
        'KALP ATIŞ ANOMALISI');
    } else {
      _heartRateAlarm = false;
    }
  }
  
  void triggerManualAlarm() {
    _manualAlarm = true;
    
    // 🆕 Alarm kaydı ekle
    _saveAlarmRecord('manual', 'Manuel acil durum çağrısı');
    
    _triggerAlarm('Manuel acil durum çağrısı!', 'MANUEL ACİL DURUM');
    notifyListeners();
  }
  
  // 🆕 Alarm kaydını ekle ve kaydet
  void _saveAlarmRecord(String type, String message, 
      {double? heartRate, double? accelerometerTotal}) {
    _alarmRecords.add(AlarmRecord(
      timestamp: DateTime.now(),
      type: type,
      message: message,
      heartRate: heartRate,
      accelerometerTotal: accelerometerTotal,
    ));
    _saveHistoryData();
  }
  
  void _triggerAlarm(String message, String title) {
    debugPrint('🚨 ALARM: $message');
    
    if (_context != null) {
      EmergencyService.triggerEmergency(
        emergencyType: title,
        context: _context!,
      );
    }
    
    if (message.contains('Düşme')) {
      NotificationService.showFallAlert();
    } else if (message.contains('Hareketsizlik') || message.contains('HAREKETSİZLİK')) {
      NotificationService.showInactivityAlert(_inactivityTimeMinutes);
    } else if (message.contains('Kalp') || message.contains('KALP')) {
      NotificationService.showHeartRateAlert(_heartRate.toInt());
    } else if (message.contains('Manuel') || message.contains('MANUEL')) {
      NotificationService.showManualEmergency();
    }
  }
  
  void stopAlarm() {
    _fallDetected = false;
    _inactivityAlarm = false;
    _heartRateAlarm = false;
    _manualAlarm = false;
    NotificationService.stopAlarm();
    debugPrint('⏹️ Alarm durduruldu');
    notifyListeners();
  }
  
  void resetAlarms() {
    stopAlarm();
  }
  
  void updateThresholds({
    double? minHR,
    double? maxHR,
    int? inactivityTime,
  }) {
    if (minHR != null) _minHeartRate = minHR;
    if (maxHR != null) _maxHeartRate = maxHR;
    if (inactivityTime != null) _inactivityTimeMinutes = inactivityTime;
    notifyListeners();
  }
  
  // 🆕 History temizleme
  Future<void> clearHistory() async {
    _sensorRecords.clear();
    _alarmRecords.clear();
    await _saveHistoryData();
    debugPrint('🗑️ Geçmiş veriler temizlendi');
    notifyListeners();
  }
}

class HeartRateData {
  final DateTime time;
  final double value;
  
  HeartRateData(this.time, this.value);
}