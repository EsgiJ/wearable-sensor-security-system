// Sensör kaydı modeli
class SensorRecord {
  final DateTime timestamp;
  final double heartRate;
  final double accelerometerX;
  final double accelerometerY;
  final double accelerometerZ;
  final bool isMoving;
  
  SensorRecord({
    required this.timestamp,
    required this.heartRate,
    required this.accelerometerX,
    required this.accelerometerY,
    required this.accelerometerZ,
    required this.isMoving,
  });
  
  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'heartRate': heartRate,
    'accelerometerX': accelerometerX,
    'accelerometerY': accelerometerY,
    'accelerometerZ': accelerometerZ,
    'isMoving': isMoving,
  };
  
  factory SensorRecord.fromJson(Map<String, dynamic> json) => SensorRecord(
    timestamp: DateTime.parse(json['timestamp']),
    heartRate: json['heartRate'],
    accelerometerX: json['accelerometerX'],
    accelerometerY: json['accelerometerY'],
    accelerometerZ: json['accelerometerZ'],
    isMoving: json['isMoving'],
  );
}

// Alarm kaydı modeli
class AlarmRecord {
  final DateTime timestamp;
  final String type;
  final String message;
  final double? heartRate;
  final double? accelerometerTotal;
  
  AlarmRecord({
    required this.timestamp,
    required this.type,
    required this.message,
    this.heartRate,
    this.accelerometerTotal,
  });
  
  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'type': type,
    'message': message,
    'heartRate': heartRate,
    'accelerometerTotal': accelerometerTotal,
  };
  
  factory AlarmRecord.fromJson(Map<String, dynamic> json) => AlarmRecord(
    timestamp: DateTime.parse(json['timestamp']),
    type: json['type'],
    message: json['message'],
    heartRate: json['heartRate'],
    accelerometerTotal: json['accelerometerTotal'],
  );
}