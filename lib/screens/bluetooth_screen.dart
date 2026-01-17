import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../providers/sensor_data_provider.dart';
import 'dart:async';
import 'dart:convert';

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
  
  // DEBUG bilgileri
  String _lastRawData = '';
  DateTime? _lastDataTime;
  String _parseStatus = '';

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  Future<void> _startScan() async {
    setState(() {
      _scanResults.clear();
      _isScanning = true;
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
      
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        if (mounted) {
          setState(() {
            _scanResults = results;
          });
        }
      });

      await Future.delayed(const Duration(seconds: 15));
      await _stopScan();
    } catch (e) {
      _showSnackBar('Tarama hatası: $e', Colors.red);
    }
  }

  Future<void> _stopScan() async {
    await FlutterBluePlus.stopScan();
    if (mounted) {
      setState(() {
        _isScanning = false;
      });
    }
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
      provider.updateConnectionStatus(true, device.platformName);
      
      _showSnackBar('Bağlandı: ${device.platformName}', Colors.green);
      
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
          if (characteristic.properties.notify) {
            await characteristic.setNotifyValue(true);
            
            // ✅ lastValueStream kullan
            characteristic.lastValueStream.listen((value) {
              _parseStringData(value);
            });
            
            debugPrint('✅ Notify aktif: ${characteristic.uuid}');
          }
        }
      }
    } catch (e) {
      debugPrint('Servis keşfi hatası: $e');
    }
  }

  // ✅ DÜZELTME: ESP32 STRING gönderiyor!
  // Format: "HR:75,AX:-0.12,AY:0.98,AZ:0.05"
  void _parseStringData(List<int> rawData) {
    try {
      // 1. Byte array'i UTF-8 string'e çevir
      String dataString = utf8.decode(rawData).trim();
      
      setState(() {
        _lastRawData = dataString;
        _lastDataTime = DateTime.now();
      });
      
      debugPrint('📥 RAW DATA: "$dataString"');
      
      // 2. Boş veri kontrolü
      if (dataString.isEmpty) {
        setState(() => _parseStatus = '⚠️ Boş veri');
        return;
      }
      
      // 3. Parse et: "HR:75,AX:-0.12,AY:0.98,AZ:0.05"
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
            debugPrint('  ✅ $key = $value');
          } else {
            debugPrint('  ❌ Parse edilemedi: $part');
          }
        }
      }
      
      // 4. Provider'a gönder
      if (parsed.isNotEmpty && mounted) {
        final provider = Provider.of<SensorDataProvider>(context, listen: false);
        
        provider.updateSensorData(
          heartRate: parsed['HR'],
          accX: parsed['AX'],
          accY: parsed['AY'],
          accZ: parsed['AZ'],
        );
        
        setState(() {
          _parseStatus = '✅ HR=${parsed['HR']?.toStringAsFixed(0) ?? "-"}, '
              'AX=${parsed['AX']?.toStringAsFixed(2) ?? "-"}, '
              'AY=${parsed['AY']?.toStringAsFixed(2) ?? "-"}, '
              'AZ=${parsed['AZ']?.toStringAsFixed(2) ?? "-"}';
        });
      } else {
        setState(() => _parseStatus = '⚠️ Parse sonucu boş');
      }
      
    } catch (e) {
      debugPrint('❌ Parse hatası: $e');
      setState(() => _parseStatus = '❌ Hata: $e');
    }
  }

  Future<void> _disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      
      setState(() {
        _connectedDevice = null;
        _lastRawData = '';
        _lastDataTime = null;
        _parseStatus = '';
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
            _buildConnectedCard(),
          
          // DEBUG: Ham veri kutusu
          if (_connectedDevice != null)
            _buildDebugBox(),
          
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
          
          // Cihaz listesi
          Expanded(
            child: _scanResults.isEmpty
                ? _buildEmptyState()
                : _buildDeviceList(),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.bluetooth_connected, color: Colors.white, size: 36),
        title: const Text('Bağlı', 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: Text(_connectedDevice!.platformName,
          style: const TextStyle(color: Colors.white70)),
        trailing: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _disconnect,
        ),
      ),
    );
  }

  // DEBUG kutusu - canlı veri gösterimi
  Widget _buildDebugBox() {
    final isLive = _lastDataTime != null && 
        DateTime.now().difference(_lastDataTime!).inSeconds < 3;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLive ? Colors.green : Colors.orange,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Durum satırı
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLive ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isLive ? '🟢 CANLI VERİ' : '🟡 VERİ BEKLENİYOR',
                style: TextStyle(
                  color: isLive ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (_lastDataTime != null)
                Text(
                  '${DateTime.now().difference(_lastDataTime!).inSeconds}s önce',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Ham veri
          const Text('RAW:', style: TextStyle(color: Colors.grey, fontSize: 10)),
          Text(
            _lastRawData.isEmpty ? '(veri yok)' : _lastRawData,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
              fontSize: 13,
            ),
          ),
          
          const SizedBox(height: 6),
          
          // Parse sonucu
          const Text('PARSE:', style: TextStyle(color: Colors.grey, fontSize: 10)),
          Text(
            _parseStatus.isEmpty ? '(bekleniyor)' : _parseStatus,
            style: TextStyle(
              color: _parseStatus.startsWith('✅') ? Colors.green : Colors.yellow,
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bluetooth_searching, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('Henüz cihaz bulunamadı',
            style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text('Yukarıdaki butona basarak arama yapın',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    return ListView.builder(
      itemCount: _scanResults.length,
      itemBuilder: (context, index) {
        final result = _scanResults[index];
        final device = result.device;
        final rssi = result.rssi;
        final isConnected = _connectedDevice?.remoteId == device.remoteId;
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: isConnected ? Colors.green.shade50 : null,
          child: ListTile(
            leading: Icon(
              isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
              color: isConnected ? Colors.green : _getSignalColor(rssi),
            ),
            title: Text(
              device.platformName.isEmpty ? 'Bilinmeyen Cihaz' : device.platformName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text('Sinyal: $rssi dBm'),
            trailing: ElevatedButton(
              onPressed: isConnected ? _disconnect : () => _connectToDevice(device),
              style: ElevatedButton.styleFrom(
                backgroundColor: isConnected ? Colors.red : null,
              ),
              child: Text(isConnected ? 'Kes' : 'Bağlan'),
            ),
          ),
        );
      },
    );
  }

  Color _getSignalColor(int rssi) {
    if (rssi > -60) return Colors.green;
    if (rssi > -80) return Colors.orange;
    return Colors.red;
  }
}