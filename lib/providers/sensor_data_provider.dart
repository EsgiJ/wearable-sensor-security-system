import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';

class SensorDataProvider extends ChangeNotifier {
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
  final double _fallThreshold = 2.5; // G cinsinden - final olarak değiştirildi
  
  // Geçmiş veriler (grafik için)
  final List<HeartRateData> _heartRateHistory = [];
  final int _maxHistoryLength = 50;

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
  
  // Bağlantı durumunu güncelle
  void updateConnectionStatus(bool status, String name) {
    _isConnected = status;
    _deviceName = name;
    notifyListeners();
  }
  
  // Sensör verilerini güncelle
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
    
    notifyListeners();
  }
  
  // Kalp atışı geçmişine ekle
  void _addHeartRateToHistory(double value) {
    _heartRateHistory.add(HeartRateData(DateTime.now(), value));
    if (_heartRateHistory.length > _maxHistoryLength) {
      _heartRateHistory.removeAt(0);
    }
  }
  
  // Düşme tespiti
  void _checkFallDetection() {
    double totalAcceleration = 
        (_accelerometerX * _accelerometerX +
         _accelerometerY * _accelerometerY +
         _accelerometerZ * _accelerometerZ).abs();
    
    if (totalAcceleration > _fallThreshold) {
      _fallDetected = true;
      _triggerAlarm('Düşme tespit edildi!');
    }
  }
  
  // Hareket kontrolü
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
  
  // Hareketsizlik kontrolü
  void _checkInactivity() {
    int minutesSinceLastMovement = 
        DateTime.now().difference(_lastMovementTime).inMinutes;
    
    if (minutesSinceLastMovement >= _inactivityTimeMinutes) {
      _inactivityAlarm = true;
      _triggerAlarm('Uzun süreli hareketsizlik tespit edildi!');
    }
  }
  
  // Kalp atışı alarm kontrolü
  void _checkHeartRateAlarm() {
    if (_heartRate < _minHeartRate || _heartRate > _maxHeartRate) {
      _heartRateAlarm = true;
      _triggerAlarm('Anormal kalp atışı: ${_heartRate.toInt()} bpm');
    } else {
      _heartRateAlarm = false;
    }
  }
  
  // Manuel alarm
  void triggerManualAlarm() {
    _manualAlarm = true;
    _triggerAlarm('Manuel acil durum çağrısı!');
    notifyListeners();
  }
  
  // Alarm tetikleme
  void _triggerAlarm(String message) {
    debugPrint('🚨 ALARM: $message');
    
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
  
  // Alarmları sıfırla
  void resetAlarms() {
    _fallDetected = false;
    _inactivityAlarm = false;
    _heartRateAlarm = false;
    _manualAlarm = false;
    notifyListeners();
  }
  
  // Eşik değerlerini güncelle
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
}

// Kalp atışı veri modeli
class HeartRateData {
  final DateTime time;
  final double value;
  
  HeartRateData(this.time, this.value);
}