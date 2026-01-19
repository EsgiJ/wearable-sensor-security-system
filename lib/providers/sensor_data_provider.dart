import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:math';
import 'dart:convert';
import 'dart:async';
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
  
  // 🆕 Bluetooth cihaz ve subscription yönetimi
  BluetoothDevice? _connectedDevice;
  final List<StreamSubscription> _characteristicSubscriptions = [];
  
  // Sensör verileri
  double _heartRate = 0;
  double _accelerometerX = 0;
  double _accelerometerY = 0;
  double _accelerometerZ = 0;
  bool _isMoving = true;
  DateTime _lastMovementTime = DateTime.now();
  DateTime? _lastDataTime; // 🆕 Son veri zamanı
  
  // Alarm durumları
  bool _fallDetected = false;
  bool _inactivityAlarm = false;
  bool _heartRateAlarm = false;
  bool _manualAlarm = false;
  
  // Eşik değerleri
  double _minHeartRate = 40;
  double _maxHeartRate = 120;
  int _inactivityTimeMinutes = 30;
  double _fallThreshold = 2.5; // 🆕 ARTIK DEĞİŞTİRİLEBİLİR!
  
  // Grafik için geçmiş veriler
  final List<HeartRateData> _heartRateHistory = [];
  final int _maxHistoryLength = 50;
  
  // Gerçek veri kayıtları
  final List<SensorRecord> _sensorRecords = [];
  final List<AlarmRecord> _alarmRecords = [];
  DateTime? _lastSaveTime;
  final int _saveIntervalSeconds = 30;

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
  
  // 🆕 Fall threshold getter
  double get fallThreshold => _fallThreshold;
  
  // 🆕 Son veri zamanı getter
  DateTime? get lastDataTime => _lastDataTime;
  
  // 🆕 Toplam ivme hesaplama
  double get totalAcceleration => sqrt(
    _accelerometerX * _accelerometerX +
    _accelerometerY * _accelerometerY +
    _accelerometerZ * _accelerometerZ
  );
  
  // History getters
  List<SensorRecord> get sensorRecords => _sensorRecords;
  List<AlarmRecord> get alarmRecords => _alarmRecords;
  
  bool get hasActiveAlarm => 
      _fallDetected || _inactivityAlarm || _heartRateAlarm || _manualAlarm;
  
  // 🆕 Fall threshold setter
  void setFallThreshold(double value) {
    _fallThreshold = value;
    debugPrint('⚙️ Fall threshold değiştirildi: $value G');
    _saveHistoryData(); // Hemen kaydet
    notifyListeners();
  }
  
  // 🆕 Bluetooth bağlantısını kur (App-level)
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      debugPrint('🔗 Cihaza bağlanılıyor: ${device.platformName}');
      
      await device.connect(timeout: const Duration(seconds: 15));
      
      _connectedDevice = device;
      _isConnected = true;
      _deviceName = device.platformName;
      notifyListeners();
      
      debugPrint('✅ Cihaza başarıyla bağlandı: ${device.platformName}');
      
      await _discoverAndSubscribeToServices(device);
      
    } catch (e) {
      debugPrint('❌ Bağlantı hatası: $e');
      _isConnected = false;
      _connectedDevice = null;
      notifyListeners();
    }
  }
  
  // 🆕 Servisleri keşfet ve subscription'ları kur
  Future<void> _discoverAndSubscribeToServices(BluetoothDevice device) async {
    try {
      List<BluetoothService> services = await device.discoverServices();
      
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.notify) {
            await characteristic.setNotifyValue(true);
            
            final subscription = characteristic.onValueReceived.listen((value) {
              _parseBluetoothData(value);
            });
            _characteristicSubscriptions.add(subscription);
            
            debugPrint('✅ Notify aktif: ${characteristic.uuid}');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Servis keşfi hatası: $e');
    }
  }
  
  // 🆕 Bluetooth verisini parse et
  void _parseBluetoothData(List<int> rawData) {
    try {
      String dataString = utf8.decode(rawData).trim();
      
      debugPrint('📥 RAW DATA: "$dataString"');
      
      if (dataString.isEmpty) return;
      
      // Format: "HR:75,AX:-0.12,AY:0.98,AZ:0.05"
      Map<String, double> parsed = {};
      List<String> parts = dataString.split(',');
      
      for (var part in parts) {
        part = part.trim();
        if (part.isEmpty) continue;
        
        List<String> kv = part.split(':');
        if (kv.length == 2) {
          String key = kv[0].trim().toUpperCase();
          double? value = double.tryParse(kv[1].trim());
          
          if (value != null) {
            parsed[key] = value;
          }
        }
      }
      
      // Provider'a gönder
      if (parsed.isNotEmpty) {
        updateSensorData(
          heartRate: parsed['HR'],
          accX: parsed['AX'],
          accY: parsed['AY'],
          accZ: parsed['AZ'],
        );
      }
    } catch (e) {
      debugPrint('❌ Parse hatası: $e');
    }
  }
  
  // 🆕 Bluetooth bağlantısını kapat (App kapatılırken)
  Future<void> disconnectFromDevice() async {
    try {
      if (_connectedDevice != null) {
        debugPrint('🔌 Cihazdan ayrılıyor...');
        
        // Subscription'ları temizle
        for (var sub in _characteristicSubscriptions) {
          await sub.cancel();
        }
        _characteristicSubscriptions.clear();
        
        // Bağlantıyı kapat
        await _connectedDevice!.disconnect();
        
        _connectedDevice = null;
        _isConnected = false;
        _deviceName = '';
        notifyListeners();
        
        debugPrint('✅ Cihazdan ayrılındı');
      }
    } catch (e) {
      debugPrint('❌ Ayrılma hatası: $e');
    }
  }
  
  // 🆕 Provider dispose edilirken çağrılacak
  void disposeBluetoothConnection() {
    // Henüz ayrılmadıysa ayrıl
    if (_isConnected) {
      disconnectFromDevice();
    }
  }
  
  // Veri yükleme
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
      
      // 🆕 Fall threshold'u yükle
      final savedThreshold = prefs.getDouble('fall_threshold');
      if (savedThreshold != null) {
        _fallThreshold = savedThreshold;
      }
      
      debugPrint('✅ Veriler yüklendi: threshold=$_fallThreshold G');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Veri yükleme hatası: $e');
    }
  }
  
  // Veri kaydetme
  Future<void> _saveHistoryData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Son 7 günün verilerini sakla
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      _sensorRecords.removeWhere((r) => r.timestamp.isBefore(weekAgo));
      _alarmRecords.removeWhere((r) => r.timestamp.isBefore(weekAgo));
      
      await prefs.setString('sensor_records', 
        jsonEncode(_sensorRecords.map((e) => e.toJson()).toList()));
      await prefs.setString('alarm_records',
        jsonEncode(_alarmRecords.map((e) => e.toJson()).toList()));
      
      // 🆕 Fall threshold'u kaydet
      await prefs.setDouble('fall_threshold', _fallThreshold);
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
    // 🆕 Son veri zamanını güncelle
    _lastDataTime = DateTime.now();
    
    if (heartRate != null && heartRate > 0) {
      _heartRate = heartRate;
      _addHeartRateToHistory(heartRate);
      _checkHeartRateAlarm();
      debugPrint('❤️ HR=$heartRate');
    }
    
    if (accX != null) {
      _accelerometerX = accX;
    }
    if (accY != null) {
      _accelerometerY = accY;
    }
    if (accZ != null) {
      _accelerometerZ = accZ;
    }
    
    if (accX != null || accY != null || accZ != null) {
      debugPrint('📊 Acc X=$_accelerometerX Y=$_accelerometerY Z=$_accelerometerZ');
      _checkFallDetection();
      _checkMovement();
    }
    
    // 30 saniyede bir kaydet
    _autoSaveSensorData();
    
    notifyListeners();
  }
  
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
    double total = totalAcceleration;
    
    debugPrint('🔍 Düşme: ${total.toStringAsFixed(2)}G / Eşik: ${_fallThreshold}G');
    
    if (total > _fallThreshold && !_fallDetected) {
      _fallDetected = true;
      debugPrint('🚨 DÜŞME TESPİT! ${total.toStringAsFixed(2)} G');
      
      _saveAlarmRecord('fall', 'Düşme tespit edildi', 
        accelerometerTotal: total);
      
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
    
    if (minutesSinceLastMovement >= _inactivityTimeMinutes && !_inactivityAlarm) {
      _inactivityAlarm = true;
      
      _saveAlarmRecord('inactivity', 
        'Hareketsizlik: $minutesSinceLastMovement dk');
      
      _triggerAlarm('Uzun süreli hareketsizlik!', 'HAREKETSİZLİK');
    }
  }
  
  void _checkHeartRateAlarm() {
    if (_heartRate < _minHeartRate || _heartRate > _maxHeartRate) {
      if (!_heartRateAlarm) {
        _heartRateAlarm = true;
        
        _saveAlarmRecord('heart_rate', 'Anormal HR: $_heartRate bpm',
          heartRate: _heartRate);
        
        _triggerAlarm('Anormal kalp atışı: ${_heartRate.toInt()} bpm',
          'KALP ATIŞ ANOMALİSİ');
      }
    } else {
      _heartRateAlarm = false;
    }
  }
  
  void triggerManualAlarm() {
    _manualAlarm = true;
    _saveAlarmRecord('manual', 'Manuel acil durum');
    _triggerAlarm('Manuel acil durum!', 'MANUEL ACİL DURUM');
    notifyListeners();
  }
  
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
    } else if (message.contains('Hareketsizlik')) {
      NotificationService.showInactivityAlert(_inactivityTimeMinutes);
    } else if (message.contains('Kalp')) {
      NotificationService.showHeartRateAlert(_heartRate.toInt());
    } else if (message.contains('Manuel')) {
      NotificationService.showManualEmergency();
    }
  }
  
  void stopAlarm() {
    _fallDetected = false;
    _inactivityAlarm = false;
    _heartRateAlarm = false;
    _manualAlarm = false;
    NotificationService.stopAlarm();
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
  
  Future<void> clearHistory() async {
    _sensorRecords.clear();
    _alarmRecords.clear();
    await _saveHistoryData();
    notifyListeners();
  }
}

class HeartRateData {
  final DateTime time;
  final double value;
  
  HeartRateData(this.time, this.value);
}