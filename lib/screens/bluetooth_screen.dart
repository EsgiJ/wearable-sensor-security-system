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

class _BluetoothScreenState extends State<BluetoothScreen> 
    with SingleTickerProviderStateMixin {
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  BluetoothDevice? _connectedDevice;
  StreamSubscription? _scanSubscription;
  StreamSubscription? _stateSubscription;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    
    // Animasyon controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _stateSubscription?.cancel();
    _animationController.dispose();
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
      provider.updateConnectionStatus(true, device.platformName);
      
      _showSnackBar('${device.platformName} cihazına bağlandı!', Colors.green);
      
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
          if (characteristic.properties.notify) {
            await characteristic.setNotifyValue(true);
            
            characteristic.lastValueStream.listen((value) {
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
    if (data.length >= 4) {
      final provider = Provider.of<SensorDataProvider>(context, listen: false);
      
      double heartRate = data[0].toDouble();
      double accX = (data[1] - 128) / 64.0;
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
        content: Row(
          children: [
            Icon(
              color == Colors.green ? Icons.check_circle : 
              color == Colors.blue ? Icons.bluetooth_searching :
              Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  String _getDeviceName(BluetoothDevice device) {
    // Platform adını al, boşsa ID'yi göster
    String name = device.platformName;
    if (name.isEmpty) {
      name = device.remoteId.toString();
      // MAC adresini kısalt
      if (name.length > 17) {
        name = name.substring(name.length - 17);
      }
    }
    return name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Bluetooth Bağlantısı',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Gradient header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue, Colors.blue.shade700],
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Bağlı cihaz kartı veya arama ikonu
                if (_connectedDevice != null)
                  _buildConnectedDeviceCard()
                else
                  _buildBluetoothIcon(),
                
                const SizedBox(height: 20),
                
                // Tarama butonu
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildScanButton(),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
          
          // Tarama durumu
          if (_isScanning)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue[50],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Cihazlar aranıyor...',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 8),
          
          // Liste başlığı
          if (_scanResults.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.devices, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Bulunan Cihazlar (${_scanResults.length})',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          
          // Bulunan cihazlar listesi
          Expanded(
            child: _scanResults.isEmpty
                ? _buildEmptyState()
                : _buildDeviceList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBluetoothIcon() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isScanning ? _pulseAnimation.value : 1.0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isScanning ? Icons.bluetooth_searching : Icons.bluetooth,
              size: 60,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _buildConnectedDeviceCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bluetooth_connected,
              color: Colors.green.shade700,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDeviceName(_connectedDevice!),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Bağlı',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _disconnect,
            icon: const Icon(Icons.close),
            color: Colors.red,
            tooltip: 'Bağlantıyı Kes',
          ),
        ],
      ),
    );
  }

  Widget _buildScanButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isScanning ? _stopScan : _startScan,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue.shade700,
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isScanning ? Icons.stop : Icons.search,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              _isScanning ? 'Aramayı Durdur' : 'Cihaz Ara',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bluetooth_disabled,
              size: 80,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Henüz cihaz bulunamadı',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Giyilebilir cihazınızı açın ve "Cihaz Ara" butonuna basın',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 32),
          // İpuçları kartı
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'İpuçları',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTip('Cihazınızın Bluetooth\'unun açık olduğundan emin olun'),
                _buildTip('Cihazınız yakında olmalı (1-2 metre)'),
                _buildTip('İlk bağlantıda eşleştirme gerekebilir'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: Colors.blue.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _scanResults.length,
      itemBuilder: (context, index) {
        final result = _scanResults[index];
        final device = result.device;
        final rssi = result.rssi;
        final deviceName = _getDeviceName(device);
        
        return _buildDeviceCard(device, deviceName, rssi);
      },
    );
  }

  Widget _buildDeviceCard(BluetoothDevice device, String deviceName, int rssi) {
    final signalColor = _getSignalColor(rssi);
    final signalStrength = _getSignalStrength(rssi);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _connectToDevice(device),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Cihaz ikonu
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.watch,
                    color: Colors.blue.shade700,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Cihaz bilgileri
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deviceName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          // Sinyal gücü ikonu
                          Icon(
                            _getSignalIcon(rssi),
                            size: 16,
                            color: signalColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            signalStrength,
                            style: TextStyle(
                              fontSize: 13,
                              color: signalColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$rssi dBm',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Bağlan butonu
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Bağlan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getSignalColor(int rssi) {
    if (rssi > -60) return Colors.green;
    if (rssi > -70) return Colors.lightGreen;
    if (rssi > -80) return Colors.orange;
    return Colors.red;
  }

  String _getSignalStrength(int rssi) {
    if (rssi > -60) return 'Mükemmel';
    if (rssi > -70) return 'İyi';
    if (rssi > -80) return 'Orta';
    return 'Zayıf';
  }

  IconData _getSignalIcon(int rssi) {
    if (rssi > -60) return Icons.signal_cellular_4_bar;
    if (rssi > -70) return Icons.signal_cellular_alt;
    if (rssi > -80) return Icons.signal_cellular_alt_2_bar;
    return Icons.signal_cellular_alt_1_bar;
  }
}