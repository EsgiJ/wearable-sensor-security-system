import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/sensor_data_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Akıllı Güvenlik Sistemi'),
        centerTitle: true,
      ),
      body: Consumer<SensorDataProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bağlantı Durumu
                _buildConnectionCard(provider),
                const SizedBox(height: 16),
                
                // Alarmlar
                if (_hasActiveAlarm(provider))
                  _buildAlarmSection(provider),
                
                // Manuel Acil Durum Butonu
                _buildEmergencyButton(context, provider),
                const SizedBox(height: 16),
                
                // Kalp Atışı Kartı
                _buildHeartRateCard(provider),
                const SizedBox(height: 16),
                
                // Kalp Atışı Grafiği
                _buildHeartRateChart(provider),
                const SizedBox(height: 16),
                
                // İvmeölçer Verileri
                _buildAccelerometerCard(provider),
                const SizedBox(height: 16),
                
                // Hareket Durumu
                _buildMovementCard(provider),
              ],
            ),
          );
        },
      ),
    );
  }
  
  bool _hasActiveAlarm(SensorDataProvider provider) {
    return provider.fallDetected || 
           provider.inactivityAlarm || 
           provider.heartRateAlarm ||
           provider.manualAlarm;
  }
  
  Widget _buildConnectionCard(SensorDataProvider provider) {
    return Card(
      child: ListTile(
        leading: Icon(
          provider.isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
          color: provider.isConnected ? Colors.green : Colors.grey,
          size: 32,
        ),
        title: Text(
          provider.isConnected ? 'Bağlı' : 'Bağlantı Yok',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          provider.isConnected ? provider.deviceName : 'Cihaza bağlanın',
        ),
      ),
    );
  }
  
  Widget _buildAlarmSection(SensorDataProvider provider) {
    List<Widget> alarms = [];
    
    if (provider.fallDetected) {
      alarms.add(_buildAlarmCard(
        '🚨 Düşme Tespit Edildi!',
        'Acil durum protokolü başlatıldı',
        Colors.red,
      ));
    }
    
    if (provider.inactivityAlarm) {
      alarms.add(_buildAlarmCard(
        '⚠️ Uzun Süreli Hareketsizlik',
        '${provider.inactivityTimeMinutes} dakikadır hareket yok',
        Colors.orange,
      ));
    }
    
    if (provider.heartRateAlarm) {
      alarms.add(_buildAlarmCard(
        '💔 Anormal Kalp Atışı',
        'Nabız: ${provider.heartRate.toInt()} bpm',
        Colors.red,
      ));
    }
    
    if (provider.manualAlarm) {
      alarms.add(_buildAlarmCard(
        '🆘 Manuel Acil Durum',
        'Kullanıcı yardım çağırdı',
        Colors.red,
      ));
    }
    
    return Column(
      children: [
        ...alarms,
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: provider.resetAlarms,
          icon: const Icon(Icons.clear),
          label: const Text('Alarmları Temizle'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[300],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
  
  Widget _buildAlarmCard(String title, String subtitle, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: ListTile(
        leading: Icon(Icons.warning, color: color, size: 32),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        subtitle: Text(subtitle),
      ),
    );
  }
  
  Widget _buildEmergencyButton(BuildContext context, SensorDataProvider provider) {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: ElevatedButton(
        onPressed: () {
          _showEmergencyDialog(context, provider);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emergency, size: 32),
            SizedBox(height: 4),
            Text(
              'ACİL DURUM',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showEmergencyDialog(BuildContext context, SensorDataProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Acil Durum Çağrısı'),
        content: const Text('Bakıcınıza ve acil servislere uyarı gönderilecek. Devam etmek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.triggerManualAlarm();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Acil durum uyarısı gönderildi!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Evet, Gönder'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeartRateCard(SensorDataProvider provider) {
    Color heartColor = Colors.green;
    if (provider.heartRate < provider.minHeartRate || 
        provider.heartRate > provider.maxHeartRate) {
      heartColor = Colors.red;
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.favorite, color: heartColor, size: 48),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kalp Atışı',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  Text(
                    '${provider.heartRate.toInt()} bpm',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: heartColor,
                    ),
                  ),
                  Text(
                    'Normal: ${provider.minHeartRate.toInt()}-${provider.maxHeartRate.toInt()} bpm',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeartRateChart(SensorDataProvider provider) {
    if (provider.heartRateHistory.isEmpty) {
      return Card(
        child: Container(
          height: 200,
          alignment: Alignment.center,
          child: const Text('Veri bekleniyor...'),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kalp Atışı Geçmişi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  minY: 0,
                  maxY: 200,
                  lineBarsData: [
                    LineChartBarData(
                      spots: provider.heartRateHistory
                          .asMap()
                          .entries
                          .map((e) => FlSpot(
                                e.key.toDouble(),
                                e.value.value,
                              ))
                          .toList(),
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAccelerometerCard(SensorDataProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'İvmeölçer Verileri',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildAccelerometerRow('X Ekseni', provider.accelerometerX, Colors.red),
            _buildAccelerometerRow('Y Ekseni', provider.accelerometerY, Colors.green),
            _buildAccelerometerRow('Z Ekseni', provider.accelerometerZ, Colors.blue),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAccelerometerRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: (value + 2) / 4,
              backgroundColor: Colors.grey[200],
              color: color,
              minHeight: 20,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Text(
              value.toStringAsFixed(2),
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMovementCard(SensorDataProvider provider) {
    return Card(
      color: provider.isMoving ? Colors.green[50] : Colors.orange[50],
      child: ListTile(
        leading: Icon(
          provider.isMoving ? Icons.directions_walk : Icons.not_interested,
          color: provider.isMoving ? Colors.green : Colors.orange,
          size: 32,
        ),
        title: Text(
          provider.isMoving ? 'Hareket Var' : 'Hareketsiz',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          provider.isMoving 
              ? 'Kullanıcı aktif' 
              : 'Hareketsizlik süresi izleniyor',
        ),
      ),
    );
  }
}