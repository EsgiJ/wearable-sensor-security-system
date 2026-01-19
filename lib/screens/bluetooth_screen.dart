import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../providers/sensor_data_provider.dart';
import '../services/localization_service.dart';
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
  
  // 🆕 Characteristic subscription'ları takip et
  final List<StreamSubscription> _characteristicSubscriptions = [];
  
  // DEBUG bilgileri
  String _lastRawData = '';
  DateTime? _lastDataTime;
  String _parseStatus = '';
  int _dataCount = 0; // 🆕 Kaç veri geldiğini say

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    // 🆕 Tüm characteristic subscription'larını temizle
    for (var sub in _characteristicSubscriptions) {
      sub.cancel();
    }
    _characteristicSubscriptions.clear();
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
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final provider = Provider.of<SensorDataProvider>(context, listen: false);
    
    try {
      _showSnackBar(loc.t('connecting'), Colors.blue);
      
      setState(() {
        _connectedDevice = device;
        _dataCount = 0;
      });
      
      // 🆕 Provider'ı kullanarak bağlantıyı yönet
      await provider.connectToDevice(device);
      
      if (!mounted) return;
      
      _showSnackBar('${loc.t('connected_to')}: ${device.platformName}', Colors.green);
      
    } catch (e) {
      _showSnackBar('${loc.t('connection_error')}: $e', Colors.red);
    }
  }

  Future<void> _disconnect() async {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    
    if (_connectedDevice != null) {
      // 🆕 Cleanup sadece UI state'i için - gerçek Bluetooth yönetimi Provider'da
      _characteristicSubscriptions.clear();
      
      setState(() {
        _connectedDevice = null;
        _lastRawData = '';
        _lastDataTime = null;
        _parseStatus = '';
        _dataCount = 0;
      });
      
      _showSnackBar(loc.t('connection_lost'), Colors.orange);
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
    final loc = Provider.of<LocalizationService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('bluetooth_connection')),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Bağlı cihaz kartı
          if (_connectedDevice != null)
            _buildConnectedCard(loc),
          
          // DEBUG: Ham veri kutusu
          if (_connectedDevice != null)
            _buildDebugBox(loc),
          
          // Tarama butonu
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isScanning ? _stopScan : _startScan,
                icon: Icon(_isScanning ? Icons.stop : Icons.search),
                label: Text(_isScanning ? loc.t('stop_scanning') : loc.t('scan_devices')),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ),
          
          if (_isScanning)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 16),
                  Text(loc.t('scanning')),
                ],
              ),
            ),
          
          // Cihaz listesi
          Expanded(
            child: _scanResults.isEmpty
                ? _buildEmptyState(loc)
                : _buildDeviceList(loc),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedCard(LocalizationService loc) {
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
        title: Text(loc.t('connected'), 
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
  Widget _buildDebugBox(LocalizationService loc) {
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
              // 🆕 Toplam veri sayısı
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Toplam: $_dataCount',
                  style: const TextStyle(color: Colors.blue, fontSize: 11),
                ),
              ),
              const SizedBox(width: 8),
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

  Widget _buildEmptyState(LocalizationService loc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bluetooth_searching, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(loc.t('no_devices_found'),
            style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text(loc.t('tap_to_scan'),
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildDeviceList(LocalizationService loc) {
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
              // Cihaz ismi boşsa hem 'Bilinmeyen Cihaz' yaz hem de ID'yi göster
              device.platformName.isNotEmpty 
                  ? device.platformName 
                  : "${loc.t('unknown_device')} (${device.remoteId.str})",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // MAC Adresi (veya iOS için UUID) burada gösterilir
                Text("ID: ${device.remoteId.str}", 
                    style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                Text('${loc.t('signal')}: $rssi dBm'),
              ],
            ),
            isThreeLine: true, // Alt alta 3 satır için yer açar
            trailing: ElevatedButton(
              onPressed: isConnected ? _disconnect : () => _connectToDevice(device),
              style: ElevatedButton.styleFrom(
                backgroundColor: isConnected ? Colors.red : null,
              ),
              child: Text(isConnected ? loc.t('disconnect') : loc.t('connect')),
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