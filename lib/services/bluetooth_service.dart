import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import 'dart:convert';

class WearableBluetoothService {
  BluetoothDevice? connectedDevice;
  StreamSubscription? dataSubscription;
  Function(Map<String, double>)? onDataReceived;
  
  // lowerCamelCase kullanımı
  static const String serviceUuid = "0000ffe0-0000-1000-8000-00805f9b34fb";
  static const String characteristicUuid = "0000ffe1-0000-1000-8000-00805f9b34fb";
  
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 15));
      connectedDevice = device;
      
      await _startListening();
      return true;
    } catch (e) {
      debugPrint('Bağlantı hatası: $e');
      return false;
    }
  }
  
  Future<void> _startListening() async {
    if (connectedDevice == null) return;
    
    try {
      // flutter_blue_plus'tan gelen BluetoothService için alias kullan
      List<BluetoothService> services = await connectedDevice!.discoverServices();
      
      for (var service in services) {
        debugPrint('Bulunan Servis: ${service.serviceUuid}');
        
        for (var characteristic in service.characteristics) {
          debugPrint('Bulunan Karakteristik: ${characteristic.characteristicUuid}');
          
          if (characteristic.properties.notify) {
            await characteristic.setNotifyValue(true);
            
            // lastValueStream kullan (value yerine)
            dataSubscription = characteristic.lastValueStream.listen((value) {
              _parseData(value);
            });
            
            debugPrint('Veri dinleme başlatıldı');
            return;
          }
          
          if (characteristic.properties.read) {
            Timer.periodic(const Duration(seconds: 1), (timer) async {
              if (connectedDevice == null) {
                timer.cancel();
                return;
              }
              try {
                var value = await characteristic.read();
                _parseData(value);
              } catch (e) {
                debugPrint('Okuma hatası: $e');
              }
            });
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Servis keşif hatası: $e');
    }
  }
  
  void _parseData(List<int> rawData) {
    try {
      String dataString = utf8.decode(rawData).trim();
      debugPrint('Gelen veri: $dataString');
      
      Map<String, double> parsedData = {};
      
      List<String> parts = dataString.split(',');
      
      for (var part in parts) {
        List<String> keyValue = part.split(':');
        if (keyValue.length == 2) {
          String key = keyValue[0].trim();
          double? value = double.tryParse(keyValue[1].trim());
          
          if (value != null) {
            parsedData[key] = value;
          }
        }
      }
      
      if (parsedData.isNotEmpty && onDataReceived != null) {
        onDataReceived!(parsedData);
      }
    } catch (e) {
      debugPrint('Veri parse hatası: $e');
    }
  }
  
  Future<void> disconnect() async {
    await dataSubscription?.cancel();
    await connectedDevice?.disconnect();
    connectedDevice = null;
    dataSubscription = null;
  }
  
  bool get isConnected => connectedDevice != null;
}