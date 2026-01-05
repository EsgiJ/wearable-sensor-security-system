import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/sensor_data_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _emergencyButtonController;
  late Animation<double> _emergencyButtonAnimation;

  @override
  void initState() {
    super.initState();
    _emergencyButtonController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _emergencyButtonAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _emergencyButtonController,
        curve: Curves.easeInOut,
      ),
    );
    _emergencyButtonController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _emergencyButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Consumer<SensorDataProvider>(
        builder: (context, provider, child) {
          return CustomScrollView(
            slivers: [
              // Modern App Bar
              _buildSliverAppBar(provider),
              
              // İçerik
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    
                    // Alarmlar (varsa)
                    if (_hasActiveAlarm(provider))
                      _buildAlarmSection(provider),
                    
                    // Manuel Acil Durum Butonu
                    _buildEmergencyButton(context, provider),
                    
                    // İstatistikler Grid
                    _buildStatsGrid(provider),
                    
                    // Kalp Atışı Grafiği
                    _buildHeartRateChart(provider),
                    
                    // İvmeölçer Kartı
                    _buildAccelerometerCard(provider),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(SensorDataProvider provider) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.blue,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Akıllı Güvenlik',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue,
                Colors.blue.shade700,
                Colors.blue.shade900,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 56),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const Text(
                        'Sistem Aktif',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  _buildConnectionBadge(provider),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'İyi Günler';
    return 'İyi Akşamlar';
  }

  Widget _buildConnectionBadge(SensorDataProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: provider.isConnected 
            ? Colors.green.withValues(alpha: 0.2)
            : Colors.red.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: provider.isConnected ? Colors.green : Colors.red,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: provider.isConnected ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            provider.isConnected ? 'Bağlı' : 'Bağlı Değil',
            style: TextStyle(
              color: provider.isConnected ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  bool _hasActiveAlarm(SensorDataProvider provider) {
    return provider.fallDetected || 
           provider.inactivityAlarm || 
           provider.heartRateAlarm ||
           provider.manualAlarm;
  }

  Widget _buildAlarmSection(SensorDataProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          if (provider.fallDetected)
            _buildAlarmCard(
              icon: Icons.warning_rounded,
              title: 'DÜŞME TESPİT EDİLDİ!',
              subtitle: 'Acil durum protokolü başlatıldı',
              color: Colors.red,
              urgent: true,
            ),
          if (provider.inactivityAlarm)
            _buildAlarmCard(
              icon: Icons.timer_off_rounded,
              title: 'Uzun Süreli Hareketsizlik',
              subtitle: '${provider.inactivityTimeMinutes} dakikadır hareket yok',
              color: Colors.orange,
            ),
          if (provider.heartRateAlarm)
            _buildAlarmCard(
              icon: Icons.favorite_rounded,
              title: 'Anormal Kalp Atışı',
              subtitle: 'Nabız: ${provider.heartRate.toInt()} bpm',
              color: Colors.red,
              urgent: true,
            ),
          if (provider.manualAlarm)
            _buildAlarmCard(
              icon: Icons.sos_rounded,
              title: 'MANUEL ACİL DURUM',
              subtitle: 'Kullanıcı yardım çağırdı',
              color: Colors.red,
              urgent: true,
            ),
          const SizedBox(height: 8),
          _buildClearAlarmsButton(provider),
        ],
      ),
    );
  }

  Widget _buildAlarmCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    bool urgent = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: urgent ? 16 : 15,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          if (urgent)
            Icon(Icons.emergency, color: color, size: 24),
        ],
      ),
    );
  }

  Widget _buildClearAlarmsButton(SensorDataProvider provider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: provider.resetAlarms,
        icon: const Icon(Icons.clear_all_rounded),
        label: const Text('Alarmları Temizle'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[300],
          foregroundColor: Colors.grey[800],
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyButton(BuildContext context, SensorDataProvider provider) {
    return AnimatedBuilder(
      animation: _emergencyButtonAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _emergencyButtonAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.red, Colors.redAccent],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _showEmergencyDialog(context, provider),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emergency, size: 40, color: Colors.white),
                    SizedBox(height: 8),
                    Text(
                      'ACİL DURUM',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEmergencyDialog(BuildContext context, SensorDataProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Acil Durum Çağrısı'),
          ],
        ),
        content: const Text(
          'Bakıcınıza ve acil servislere uyarı gönderilecek. Devam etmek istiyor musunuz?',
          style: TextStyle(fontSize: 15),
        ),
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
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 12),
                      Expanded(child: Text('Acil durum uyarısı gönderildi!')),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Evet, Gönder'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(SensorDataProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.favorite_rounded,
                  label: 'Kalp Atışı',
                  value: '${provider.heartRate.toInt()}',
                  unit: 'bpm',
                  color: _getHeartRateColor(provider),
                  trend: _getHeartRateTrend(provider),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: provider.isMoving ? Icons.directions_walk : Icons.bed,
                  label: 'Durum',
                  value: provider.isMoving ? 'Aktif' : 'Dinlenme',
                  unit: '',
                  color: provider.isMoving ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getHeartRateColor(SensorDataProvider provider) {
    if (provider.heartRate < provider.minHeartRate || 
        provider.heartRate > provider.maxHeartRate) {
      return Colors.red;
    }
    return Colors.green;
  }

  String? _getHeartRateTrend(SensorDataProvider provider) {
    if (provider.heartRateHistory.length < 2) return null;
    final last = provider.heartRateHistory.last.value;
    final previous = provider.heartRateHistory[provider.heartRateHistory.length - 2].value;
    if (last > previous + 5) return '↑';
    if (last < previous - 5) return '↓';
    return '→';
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
    String? trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              if (trend != null)
                Text(
                  trend,
                  style: TextStyle(fontSize: 24, color: color),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeartRateChart(SensorDataProvider provider) {
    if (provider.heartRateHistory.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.show_chart, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Veri bekleniyor...',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kalp Atışı Geçmişi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timeline, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 6),
                    Text(
                      'Canlı',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[200],
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
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
                borderData: FlBorderData(show: false),
                minY: 40,
                maxY: 140,
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
                    gradient: LinearGradient(
                      colors: [Colors.red.shade400, Colors.red.shade700],
                    ),
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.shade400.withValues(alpha: 0.3),
                          Colors.red.shade700.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccelerometerCard(SensorDataProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'İvmeölçer Verileri',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildAccelerometerRow('X Ekseni', provider.accelerometerX, Colors.red),
          const SizedBox(height: 12),
          _buildAccelerometerRow('Y Ekseni', provider.accelerometerY, Colors.green),
          const SizedBox(height: 12),
          _buildAccelerometerRow('Z Ekseni', provider.accelerometerZ, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildAccelerometerRow(String label, double value, Color color) {
    final normalizedValue = ((value + 2) / 4).clamp(0.0, 1.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              value.toStringAsFixed(2),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: normalizedValue,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.5), color],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}