import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../providers/sensor_data_provider.dart';
import 'dart:async';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  BluetoothDevice? _connectedDevice;
  StreamSubscription? _scanSubscription;
  StreamSubscription? _stateSubscription;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _stateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    if (await Permission.bluetoothScan.isDenied) {
      await Permission.bluetoothScan.request();
    }
    if (await Permission.bluetoothConnect.isDenied) {
      await Permission.bluetoothConnect.request();
    }
    if (await Permission.location.isDenied) {
      await Permission.location.request();
    }
  }

  Future<void> _startScan() async {
    setState(() {
      _scanResults.clear();
      _isScanning = true;
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
      
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        setState(() {
          _scanResults = results;
        });
      });

      await Future.delayed(const Duration(seconds: 15));
      await _stopScan();
    } catch (e) {
      _showSnackBar('Tarama hatası: $e', Colors.red);
    }
  }

  Future<void> _stopScan() async {
    await FlutterBluePlus.stopScan();
    setState(() {
      _isScanning = false;
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      _showSnackBar('Bağlanıyor...', Colors.blue);
      
      await device.connect(timeout: const Duration(seconds: 15));
      
      setState(() {
        _connectedDevice = device;
      });
      
      if (!mounted) return;
      
      final provider = Provider.of<SensorDataProvider>(context, listen: false);
      provider.updateConnectionStatus(true, device.name);
      
      _showSnackBar('${device.name} cihazına bağlandı!', Colors.green);
      
      // Servisleri keşfet
      await _discoverServices(device);
      
    } catch (e) {
      _showSnackBar('Bağlantı hatası: $e', Colors.red);
    }
  }

  Future<void> _discoverServices(BluetoothDevice device) async {
    try {
      List<BluetoothService> services = await device.discoverServices();
      
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          // Notify özelliği varsa dinlemeye başla
          if (characteristic.properties.notify) {
            await characteristic.setNotifyValue(true);
            
            characteristic.value.listen((value) {
              _parseIncomingData(value);
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Servis keşfi hatası: $e');
    }
  }

  void _parseIncomingData(List<int> data) {
    // TODO: Giyilebilir cihazdan gelen veriyi parse et
    // Örnek format: [heartRate, accX, accY, accZ]
    // Bu kısım donanım ekibiyle koordineli şekilde ayarlanmalı
    
    if (data.length >= 4) {
      final provider = Provider.of<SensorDataProvider>(context, listen: false);
      
      double heartRate = data[0].toDouble();
      double accX = (data[1] - 128) / 64.0; // -2G to +2G arası normalize
      double accY = (data[2] - 128) / 64.0;
      double accZ = (data[3] - 128) / 64.0;
      
      provider.updateSensorData(
        heartRate: heartRate,
        accX: accX,
        accY: accY,
        accZ: accZ,
      );
    }
  }

  Future<void> _disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      
      setState(() {
        _connectedDevice = null;
      });
      
      if (!mounted) return;
      
      final provider = Provider.of<SensorDataProvider>(context, listen: false);
      provider.updateConnectionStatus(false, '');
      
      _showSnackBar('Bağlantı kesildi', Colors.orange);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Bağlantısı'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Bağlı cihaz kartı
          if (_connectedDevice != null)
            Card(
              margin: const EdgeInsets.all(16),
              color: Colors.green[50],
              child: ListTile(
                leading: const Icon(Icons.bluetooth_connected, 
                                   color: Colors.green, size: 32),
                title: Text(
                  _connectedDevice!.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Bağlı'),
                trailing: IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: _disconnect,
                ),
              ),
            ),
          
          // Tarama butonu
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isScanning ? _stopScan : _startScan,
                icon: Icon(_isScanning ? Icons.stop : Icons.search),
                label: Text(_isScanning ? 'Aramayı Durdur' : 'Cihaz Ara'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ),
          
          // Tarama durumu
          if (_isScanning)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Cihazlar aranıyor...'),
                ],
              ),
            ),
          
          // Bulunan cihazlar listesi
          Expanded(
            child: _scanResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bluetooth_searching, 
                             size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Henüz cihaz bulunamadı',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Yukarıdaki butona basarak arama yapın',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _scanResults.length,
                    itemBuilder: (context, index) {
                      final result = _scanResults[index];
                      final device = result.device;
                      final rssi = result.rssi;
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.bluetooth,
                            color: _getSignalColor(rssi),
                          ),
                          title: Text(
                            device.name.isEmpty 
                                ? 'Bilinmeyen Cihaz' 
                                : device.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${device.id}\nSinyal: $rssi dBm',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => _connectToDevice(device),
                            child: const Text('Bağlan'),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _getSignalColor(int rssi) {
    if (rssi > -60) return Colors.green;
    if (rssi > -80) return Colors.orange;
    return Colors.red;
  }
}