import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';
import '../providers/sensor_data_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _minHeartRateController;
  late TextEditingController _maxHeartRateController;
  late TextEditingController _inactivityTimeController;
  late TextEditingController _caregiverNameController;
  late TextEditingController _caregiverPhoneController;

  // 🆕 DEBUG MODE
  bool _debugMode = false;
  Timer? _debugRefreshTimer;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<SensorDataProvider>(context, listen: false);
    
    _minHeartRateController = TextEditingController(
      text: provider.minHeartRate.toInt().toString(),
    );
    _maxHeartRateController = TextEditingController(
      text: provider.maxHeartRate.toInt().toString(),
    );
    _inactivityTimeController = TextEditingController(
      text: provider.inactivityTimeMinutes.toString(),
    );
    _caregiverNameController = TextEditingController();
    _caregiverPhoneController = TextEditingController();
  }

  @override
  void dispose() {
    _minHeartRateController.dispose();
    _maxHeartRateController.dispose();
    _inactivityTimeController.dispose();
    _caregiverNameController.dispose();
    _caregiverPhoneController.dispose();
    _debugRefreshTimer?.cancel();
    super.dispose();
  }

  void _saveSettings() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<SensorDataProvider>(context, listen: false);
      
      provider.updateThresholds(
        minHR: double.parse(_minHeartRateController.text),
        maxHR: double.parse(_maxHeartRateController.text),
        inactivityTime: int.parse(_inactivityTimeController.text),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Ayarlar kaydedildi!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        centerTitle: true,
        actions: [
          // 🆕 DEBUG MODE TOGGLE
          IconButton(
            icon: Icon(
              _debugMode ? Icons.bug_report : Icons.bug_report_outlined,
              color: _debugMode ? Colors.yellow : null,
            ),
            tooltip: 'Debug Modu',
            onPressed: () {
              setState(() {
                _debugMode = !_debugMode;
                if (_debugMode) {
                  // Debug modunda her 500ms'de güncelle
                  _debugRefreshTimer = Timer.periodic(
                    const Duration(milliseconds: 500),
                    (_) => setState(() {}),
                  );
                } else {
                  _debugRefreshTimer?.cancel();
                }
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🆕 DEBUG PANEL (EN ÜSTTE)
              if (_debugMode) _buildDebugPanel(),
              
              // 🆕 DÜŞME EŞİĞİ AYARI (SLIDER)
              _buildFallThresholdSection(),
              
              const SizedBox(height: 16),
              
              // Kalp Atışı Eşikleri
              _buildSectionTitle('Kalp Atışı Eşikleri'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _minHeartRateController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Minimum Nabız (bpm)',
                          prefixIcon: Icon(Icons.favorite_border),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Değer girin';
                          final n = int.tryParse(value);
                          if (n == null || n < 30 || n > 100) return '30-100 arası';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _maxHeartRateController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Maximum Nabız (bpm)',
                          prefixIcon: Icon(Icons.favorite),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Değer girin';
                          final n = int.tryParse(value);
                          if (n == null || n < 100 || n > 200) return '100-200 arası';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Hareketsizlik Ayarı
              _buildSectionTitle('Hareketsizlik Tespiti'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextFormField(
                    controller: _inactivityTimeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Hareketsizlik Süresi (dakika)',
                      prefixIcon: Icon(Icons.timer),
                      border: OutlineInputBorder(),
                      helperText: 'Bu süre hareketsizlik olursa alarm verilir',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Değer girin';
                      final n = int.tryParse(value);
                      if (n == null || n < 5 || n > 120) return '5-120 arası';
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Bakıcı Bilgileri
              _buildSectionTitle('Bakıcı/Acil Durum İletişim'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _caregiverNameController,
                        decoration: const InputDecoration(
                          labelText: 'Bakıcı Adı',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _caregiverPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Telefon Numarası',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                          helperText: 'Acil durumlarda aranacak',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Kaydet Butonu
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.save),
                  label: const Text('Ayarları Kaydet', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Test Butonu
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _startTestMode,
                  icon: const Icon(Icons.bug_report),
                  label: const Text('Test Modu Başlat'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // 🆕 DEBUG PANEL - CANLI SENSÖR DEĞERLERİ
  Widget _buildDebugPanel() {
    return Consumer<SensorDataProvider>(
      builder: (context, provider, child) {
        final total = provider.totalAcceleration;
        final threshold = provider.fallThreshold;
        final isOverThreshold = total > threshold;
        final lastUpdate = provider.lastDataTime;
        final timeSince = lastUpdate != null 
            ? DateTime.now().difference(lastUpdate).inSeconds 
            : -1;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOverThreshold ? Colors.red : Colors.green,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              // Başlık
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isOverThreshold ? Colors.red : Colors.green.shade700,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isOverThreshold ? Icons.warning : Icons.check_circle,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOverThreshold ? '⚠️ DÜŞME TESPİT!' : '✅ NORMAL',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        timeSince < 0 
                            ? '⚪ BEKLENİYOR' 
                            : timeSince < 3 
                                ? '🟢 CANLI' 
                                : '🟡 ${timeSince}s',
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Sensör değerleri
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _debugRow('KALP', '${provider.heartRate.toStringAsFixed(0)} bpm', Colors.red),
                    const SizedBox(height: 6),
                    _debugRow('ACC X', provider.accelerometerX.toStringAsFixed(3), Colors.orange),
                    _debugRow('ACC Y', provider.accelerometerY.toStringAsFixed(3), Colors.yellow),
                    _debugRow('ACC Z', provider.accelerometerZ.toStringAsFixed(3), Colors.cyan),
                    const Divider(color: Colors.grey, height: 20),
                    _debugRow(
                      'TOPLAM', 
                      '${total.toStringAsFixed(3)} G', 
                      isOverThreshold ? Colors.red : Colors.green,
                      bold: true,
                      large: true,
                    ),
                    _debugRow('EŞİK', '${threshold.toStringAsFixed(1)} G', Colors.purple),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _debugRow(String label, String value, Color color, {bool bold = false, bool large = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: large ? 20 : 14,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 DÜŞME EŞİĞİ SLIDER
  Widget _buildFallThresholdSection() {
    return Consumer<SensorDataProvider>(
      builder: (context, provider, child) {
        final currentAcc = provider.totalAcceleration;
        final threshold = provider.fallThreshold;
        final percentage = (currentAcc / threshold * 100).clamp(0, 150);
        
        return Card(
          color: Colors.purple.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.speed, color: Colors.purple.shade700, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Düşme Eşiği (Fall Threshold)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Mevcut değer gösterimi
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${threshold.toStringAsFixed(1)} G',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // İlerleme çubuğu
                      LinearProgressIndicator(
                        value: (percentage / 100).clamp(0.0, 1.0),
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(
                          percentage > 100 ? Colors.red : Colors.green,
                        ),
                        minHeight: 8,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Şu an: ${currentAcc.toStringAsFixed(2)} G (${percentage.toStringAsFixed(0)}%)',
                        style: TextStyle(
                          color: percentage > 100 ? Colors.red : Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Slider
                Row(
                  children: [
                    const Text('0.5', style: TextStyle(fontSize: 12)),
                    Expanded(
                      child: Slider(
                        value: threshold,
                        min: 0.5,
                        max: 5.0,
                        divisions: 18,
                        activeColor: Colors.purple,
                        label: '${threshold.toStringAsFixed(1)} G',
                        onChanged: (value) {
                          provider.setFallThreshold(value);
                        },
                      ),
                    ),
                    const Text('5.0', style: TextStyle(fontSize: 12)),
                  ],
                ),
                
                // Preset butonları
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _presetButton('Hassas\n1.5G', 1.5, provider),
                    _presetButton('Normal\n2.5G', 2.5, provider),
                    _presetButton('Düşük\n3.5G', 3.5, provider),
                  ],
                ),
                
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Colors.purple.shade700),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Düşük eşik = daha hassas (yanlış alarm riski)\n'
                          'Yüksek eşik = daha az hassas',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _presetButton(String label, double value, SensorDataProvider provider) {
    final isSelected = (provider.fallThreshold - value).abs() < 0.1;
    
    return ElevatedButton(
      onPressed: () => provider.setFallThreshold(value),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.purple : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.purple,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: BorderSide(color: Colors.purple.shade300),
      ),
      child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  void _startTestMode() {
    final provider = Provider.of<SensorDataProvider>(context, listen: false);
    
    // Debug modunu aç
    setState(() {
      _debugMode = true;
      _debugRefreshTimer = Timer.periodic(
        const Duration(milliseconds: 500),
        (_) => setState(() {}),
      );
    });
    
    // Rastgele veri üret
    int count = 0;
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || count >= 15) {
        timer.cancel();
        return;
      }
      
      // Rastgele değerler
      final random = Random();
      double hr = 60 + random.nextDouble() * 40; // 60-100
      double ax = -1 + random.nextDouble() * 2;  // -1 to 1
      double ay = -1 + random.nextDouble() * 2;
      double az = 0.5 + random.nextDouble() * 1; // 0.5 to 1.5 (yerçekimi)
      
      // Her 5. döngüde düşme simüle et
      if (count == 5 || count == 10) {
        ax = 2 + random.nextDouble() * 2; // 2-4 G
        ay = 1.5 + random.nextDouble();
        az = 2 + random.nextDouble();
      }
      
      provider.updateSensorData(
        heartRate: hr,
        accX: ax,
        accY: ay,
        accZ: az,
      );
      
      count++;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🧪 Test modu başlatıldı! 15 saniye veri üretilecek.'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}