import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/sensor_data_provider.dart';
import '../services/localization_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedPeriod = 'today';

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SensorDataProvider>(context);
    final loc = Provider.of<LocalizationService>(context);
    
    // Seçili periyoda göre filtrele
    final filteredRecords = _filterRecords(provider.sensorRecords);
    final filteredAlarms = _filterAlarms(provider.alarmRecords);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('history')),
        actions: [
          // Temizle butonu
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showClearDialog(context, provider, loc),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Periyot seçici
            _buildPeriodSelector(loc),
            const SizedBox(height: 16),
            
            // İstatistik kartları
            _buildStatsCards(filteredRecords, loc),
            const SizedBox(height: 16),
            
            // Kalp atışı grafiği
            if (filteredRecords.isNotEmpty) ...[
              _buildSectionTitle(loc.t('heart_rate_chart'), loc),
              _buildHeartRateChart(filteredRecords),
              const SizedBox(height: 24),
            ],
            
            // Alarm listesi
            _buildSectionTitle(loc.t('alarm_history'), loc),
            if (filteredAlarms.isEmpty)
              _buildEmptyState(loc.t('no_alarms'))
            else
              ...filteredAlarms.map((alarm) => _buildAlarmCard(alarm, loc)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPeriodSelector(LocalizationService loc) {
    return Row(
      children: [
        Expanded(
          child: _periodButton('today', loc.t('today'), loc),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _periodButton('week', loc.t('this_week'), loc),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _periodButton('all', loc.t('all_time'), loc),
        ),
      ],
    );
  }
  
  Widget _periodButton(String value, String label, LocalizationService loc) {
    final isSelected = _selectedPeriod == value;
    return ElevatedButton(
      onPressed: () => setState(() => _selectedPeriod = value),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      child: Text(label),
    );
  }
  
  Widget _buildStatsCards(List records, LocalizationService loc) {
    if (records.isEmpty) {
      return _buildEmptyState(loc.t('no_data'));
    }
    
    // İstatistikleri hesapla
    final heartRates = records.map((r) => r.heartRate).toList();
    final avgHeartRate = heartRates.reduce((a, b) => a + b) / heartRates.length;
    final maxHeartRate = heartRates.reduce((a, b) => a > b ? a : b);
    final minHeartRate = heartRates.reduce((a, b) => a < b ? a : b);
    
    return Row(
      children: [
        Expanded(child: _buildStatCard('📊 ${loc.t('average')}', 
          '${avgHeartRate.toInt()} ${loc.t('bpm')}', Colors.blue)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard('📈 ${loc.t('maximum')}', 
          '${maxHeartRate.toInt()} ${loc.t('bpm')}', Colors.red)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard('📉 ${loc.t('minimum')}', 
          '${minHeartRate.toInt()} ${loc.t('bpm')}', Colors.green)),
      ],
    );
  }
  
  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Text(value, 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeartRateChart(List records) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10),
                    ),
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
              lineBarsData: [
                LineChartBarData(
                  spots: records.asMap().entries.map((e) => 
                    FlSpot(e.key.toDouble(), e.value.heartRate)).toList(),
                  isCurved: true,
                  color: Colors.red,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title, LocalizationService loc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
  
  Widget _buildAlarmCard(alarm, LocalizationService loc) {
    IconData icon;
    Color color;
    String localizedMessage;
    
    switch (alarm.type) {
      case 'fall':
        icon = Icons.warning;
        color = Colors.red;
        localizedMessage = loc.t('fall_detected');
        break;
      case 'heart_rate':
        icon = Icons.favorite;
        color = Colors.orange;
        localizedMessage = loc.t('abnormal_heart_rate');
        break;
      case 'inactivity':
        icon = Icons.airline_seat_recline_normal;
        color = Colors.amber;
        localizedMessage = loc.t('inactivity_detected');
        break;
      case 'manual':
        icon = Icons.emergency;
        color = Colors.red[900]!;
        localizedMessage = loc.t('manual_emergency');
        break;
      default:
        icon = Icons.info;
        color = Colors.blue;
        localizedMessage = alarm.message;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(localizedMessage, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(alarm.timestamp)),
        trailing: alarm.heartRate != null 
          ? Text('${alarm.heartRate!.toInt()} ${loc.t('bpm')}', 
              style: const TextStyle(fontWeight: FontWeight.bold))
          : null,
      ),
    );
  }
  
  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(message, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
  
  List _filterRecords(List records) {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'today':
        final today = DateTime(now.year, now.month, now.day);
        return records.where((r) => r.timestamp.isAfter(today)).toList();
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return records.where((r) => r.timestamp.isAfter(weekAgo)).toList();
      default:
        return records;
    }
  }
  
  List _filterAlarms(List alarms) {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'today':
        final today = DateTime(now.year, now.month, now.day);
        return alarms.where((a) => a.timestamp.isAfter(today)).toList();
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return alarms.where((a) => a.timestamp.isAfter(weekAgo)).toList();
      default:
        return alarms;
    }
  }
  
  void _showClearDialog(BuildContext context, SensorDataProvider provider, 
      LocalizationService loc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.t('clear_history')),
        content: Text(loc.t('clear_history_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              provider.clearHistory();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(loc.t('history_cleared'))),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(loc.t('clear')),
          ),
        ],
      ),
    );
  }
}