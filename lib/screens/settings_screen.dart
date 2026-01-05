import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';  
import '../providers/sensor_data_provider.dart';
import '../services/emergency_service.dart';

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
  
  bool _isLoading = true;

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
    
    _loadCaregiverInfo();
  }

  Future<void> _loadCaregiverInfo() async {
    final info = await EmergencyService.getCaregiverInfo();
    setState(() {
      _caregiverNameController.text = info['name'] ?? '';
      _caregiverPhoneController.text = info['phone'] ?? '';
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _minHeartRateController.dispose();
    _maxHeartRateController.dispose();
    _inactivityTimeController.dispose();
    _caregiverNameController.dispose();
    _caregiverPhoneController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<SensorDataProvider>(context, listen: false);
      
      // Eşik değerlerini kaydet
      provider.updateThresholds(
        minHR: double.parse(_minHeartRateController.text),
        maxHR: double.parse(_maxHeartRateController.text),
        inactivityTime: int.parse(_inactivityTimeController.text),
      );
      
      // Bakıcı bilgilerini kaydet
      if (_caregiverNameController.text.isNotEmpty && 
          _caregiverPhoneController.text.isNotEmpty) {
        await EmergencyService.saveCaregiverInfo(
          name: _caregiverNameController.text,
          phone: _caregiverPhoneController.text,
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Ayarlar kaydedildi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                          if (value == null || value.isEmpty) {
                            return 'Lütfen bir değer girin';
                          }
                          final number = int.tryParse(value);
                          if (number == null || number < 30 || number > 100) {
                            return '30-100 arası bir değer girin';
                          }
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
                          if (value == null || value.isEmpty) {
                            return 'Lütfen bir değer girin';
                          }
                          final number = int.tryParse(value);
                          if (number == null || number < 100 || number > 200) {
                            return '100-200 arası bir değer girin';
                          }
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
                      helperText: 'Bu süre boyunca hareket yoksa alarm verilir',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen bir değer girin';
                      }
                      final number = int.tryParse(value);
                      if (number == null || number < 5 || number > 120) {
                        return '5-120 arası bir değer girin';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // 🆕 Bakıcı Bilgileri - Güncellenmiş
              _buildSectionTitle('🚨 Acil Durum İletişim'),
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Acil durumlarda SMS ve konum bilgisi gönderilecek kişi',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _caregiverNameController,
                        decoration: const InputDecoration(
                          labelText: 'Bakıcı / Yakın Adı',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen isim girin';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _caregiverPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Telefon Numarası',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                          helperText: 'Acil durumlarda SMS gönderilecek numara',
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen telefon numarası girin';
                          }
                          if (value.length < 10) {
                            return 'Geçerli bir telefon numarası girin';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Test Butonu
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            if (_caregiverPhoneController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('⚠️ Lütfen önce telefon numarasını kaydedin'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }
                            
                            // Önce kaydet
                            await EmergencyService.saveCaregiverInfo(
                              name: _caregiverNameController.text,
                              phone: _caregiverPhoneController.text,
                            );
                            
                            // Sonra test et
                            if (mounted) {
                              await EmergencyService.testCaregiverContact(context);
                            }
                          },
                          icon: const Icon(Icons.send),
                          label: const Text('Test SMS Gönder'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '💡 Test SMS\'i konum bilgisi ile birlikte gönderilecektir',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Bildirim Ayarları
              _buildSectionTitle('Bildirim Ayarları'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Düşme Bildirimleri'),
                      subtitle: const Text('Düşme tespit edildiğinde bildir'),
                      value: true,
                      onChanged: (value) {},
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Hareketsizlik Bildirimleri'),
                      subtitle: const Text('Uzun süre hareketsizlik tespit edildiğinde bildir'),
                      value: true,
                      onChanged: (value) {},
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Kalp Atışı Bildirimleri'),
                      subtitle: const Text('Anormal nabız tespit edildiğinde bildir'),
                      value: true,
                      onChanged: (value) {},
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Sesli Uyarılar'),
                      subtitle: const Text('Alarm durumlarında ses çal'),
                      value: true,
                      onChanged: (value) {},
                    ),
                  ],
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
                  label: const Text(
                    'Ayarları Kaydet',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Test Modu Butonu (Geliştirme amaçlı)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _startTestMode,
                  icon: const Icon(Icons.bug_report),
                  label: const Text('Test Modu Başlat'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Test modu: Rastgele sensör verisi üretir',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
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
    
    // Test için rastgele veri üret
    Future.delayed(Duration.zero, () {
      _generateTestData(provider);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test modu başlatıldı! Rastgele veri üretiliyor...'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _generateTestData(SensorDataProvider provider) {
    // Her 2 saniyede bir rastgele veri üret
    int count = 0;
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted || count >= 10) {
        timer.cancel();
        return;
      }
      
      // Rastgele kalp atışı (60-100 arası normal)
      double heartRate = 60 + (40 * (0.5 + 0.5 * (count % 10) / 10));
      
      // Rastgele ivmeölçer verileri
      double accX = -1 + 2 * ((count * 13) % 100) / 100;
      double accY = -1 + 2 * ((count * 17) % 100) / 100;
      double accZ = -1 + 2 * ((count * 19) % 100) / 100;
      
      provider.updateSensorData(
        heartRate: heartRate,
        accX: accX,
        accY: accY,
        accZ: accZ,
      );
      
      count++;
    });
  }
}