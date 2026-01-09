import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/sensor_data_provider.dart';
import '../services/localization_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localization = LocalizationService();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localization.t('app_title')),
        centerTitle: true,
        actions: [
          // Dil değiştir butonu
          IconButton(
            icon: Icon(
              localization.isEnglish ? Icons.language : Icons.translate,
            ),
            tooltip: localization.isEnglish ? 'Türkçe' : 'English',
            onPressed: () async {
              await localization.toggleLanguage();
            },
          ),
        ],
      ),
      body: Consumer<SensorDataProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bağlantı Durumu - Üstte belirgin şekilde
                _buildConnectionCard(provider, localization),
                const SizedBox(height: 16),
                
                // ALARM DURDUR BUTONU (Aktif alarmlar varsa)
                if (provider.hasActiveAlarm)
                  _buildStopAlarmButton(context, provider, localization),
                
                // Alarmlar
                if (_hasActiveAlarm(provider))
                  _buildAlarmSection(provider, localization),
                
                // Manuel Acil Durum Butonu
                _buildEmergencyButton(context, provider, localization),
                const SizedBox(height: 16),
                
                // Kalp Atışı Kartı
                _buildHeartRateCard(provider, localization),
                const SizedBox(height: 16),
                
                // Kalp Atışı Grafiği
                _buildHeartRateChart(provider, localization),
                const SizedBox(height: 16),
                
                // İvmeölçer Verileri
                _buildAccelerometerCard(provider, localization),
                const SizedBox(height: 16),
                
                // Hareket Durumu
                _buildMovementCard(provider, localization),
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
  
  Widget _buildStopAlarmButton(
    BuildContext context, 
    SensorDataProvider provider,
    LocalizationService localization,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      height: 70,
      child: ElevatedButton.icon(
        onPressed: () {
          provider.stopAlarm();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localization.t('alarm_stopped')),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        icon: const Icon(Icons.volume_off, size: 32),
        label: Text(
          localization.t('stop_alarm'),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
  
  Widget _buildConnectionCard(SensorDataProvider provider, LocalizationService localization) {
    return Card(
      elevation: 4,
      color: provider.isConnected ? Colors.green[50] : Colors.grey[100],
      child: ListTile(
        leading: Icon(
          provider.isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
          color: provider.isConnected ? Colors.green : Colors.grey,
          size: 36,
        ),
        title: Text(
          provider.isConnected ? localization.t('connected') : localization.t('not_connected'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(
          provider.isConnected 
              ? '${localization.t('device_name')}: ${provider.deviceName}' 
              : localization.t('connect_device'),
          style: const TextStyle(fontSize: 14),
        ),
        trailing: provider.isConnected
            ? const Icon(Icons.check_circle, color: Colors.green, size: 32)
            : const Icon(Icons.error_outline, color: Colors.grey, size: 32),
      ),
    );
  }
  
  Widget _buildAlarmSection(SensorDataProvider provider, LocalizationService localization) {
    List<Widget> alarms = [];
    
    if (provider.fallDetected) {
      alarms.add(_buildAlarmCard(
        localization.t('fall_detected'),
        localization.t('fall_detected_desc'),
        Colors.red,
      ));
    }
    
    if (provider.inactivityAlarm) {
      alarms.add(_buildAlarmCard(
        localization.t('inactivity_detected'),
        '${provider.inactivityTimeMinutes} ${localization.t('minutes')} ${localization.t('inactivity_detected_desc')}',
        Colors.orange,
      ));
    }
    
    if (provider.heartRateAlarm) {
      alarms.add(_buildAlarmCard(
        localization.t('abnormal_heart_rate'),
        '${localization.t('abnormal_hr_desc')}: ${provider.heartRate.toInt()} ${localization.t('bpm')}',
        Colors.red,
      ));
    }
    
    if (provider.manualAlarm) {
      alarms.add(_buildAlarmCard(
        localization.t('manual_emergency'),
        localization.t('manual_emergency_desc'),
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
          label: Text(localization.t('clear_alarms')),
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
      color: color.withAlpha(25), // 0.1 opacity = 25/255
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.warning, color: color, size: 32),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 14)),
      ),
    );
  }
  
  Widget _buildEmergencyButton(
    BuildContext context, 
    SensorDataProvider provider,
    LocalizationService localization,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: ElevatedButton(
        onPressed: () {
          _showEmergencyDialog(context, provider, localization);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emergency, size: 32),
            const SizedBox(height: 4),
            Text(
              localization.t('emergency_button'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showEmergencyDialog(
    BuildContext context, 
    SensorDataProvider provider,
    LocalizationService localization,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localization.t('emergency_call_title')),
        content: Text(localization.t('emergency_call_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localization.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              provider.triggerManualAlarm();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(localization.t('emergency_sent')),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(localization.t('yes_send')),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeartRateCard(SensorDataProvider provider, LocalizationService localization) {
    Color heartColor = Colors.green;
    if (provider.heartRate < provider.minHeartRate || 
        provider.heartRate > provider.maxHeartRate) {
      heartColor = Colors.red;
    }
    
    return Card(
      elevation: 2,
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
                  Text(
                    localization.t('heart_rate'),
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  Text(
                    '${provider.heartRate.toInt()} ${localization.t('bpm')}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: heartColor,
                    ),
                  ),
                  Text(
                    '${localization.t('normal_range')}: ${provider.minHeartRate.toInt()}-${provider.maxHeartRate.toInt()} ${localization.t('bpm')}',
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
  
  Widget _buildHeartRateChart(SensorDataProvider provider, LocalizationService localization) {
    if (provider.heartRateHistory.isEmpty) {
      return Card(
        child: Container(
          height: 200,
          alignment: Alignment.center,
          child: Text(localization.t('no_data')),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localization.t('heart_rate_trend'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
  
  Widget _buildAccelerometerCard(SensorDataProvider provider, LocalizationService localization) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localization.t('accelerometer_data'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildAccelerometerRow('X', provider.accelerometerX, Colors.red),
            _buildAccelerometerRow('Y', provider.accelerometerY, Colors.green),
            _buildAccelerometerRow('Z', provider.accelerometerZ, Colors.blue),
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
            child: Text('$label:', style: const TextStyle(fontSize: 14)),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: (value + 2) / 4, // -2 to +2 range normalized to 0-1
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
  
  Widget _buildMovementCard(SensorDataProvider provider, LocalizationService localization) {
    return Card(
      color: provider.isMoving ? Colors.green[50] : Colors.orange[50],
      child: ListTile(
        leading: Icon(
          provider.isMoving ? Icons.directions_walk : Icons.not_interested,
          color: provider.isMoving ? Colors.green : Colors.orange,
          size: 32,
        ),
        title: Text(
          provider.isMoving ? localization.t('moving') : localization.t('not_moving'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          provider.isMoving 
              ? localization.t('user_active')
              : localization.t('monitoring_inactivity'),
        ),
      ),
    );
  }
}