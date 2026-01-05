import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'providers/sensor_data_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/bluetooth_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Bildirim sistemini başlat
  await NotificationService.initialize();
  
  // Wake Lock'u aktif et
  await WakelockPlus.enable();
  debugPrint('✅ Wake Lock aktif - Uygulama uyku moduna geçmeyecek');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SensorDataProvider(),
      child: MaterialApp(
        title: 'Akıllı Güvenlik Sistemi',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/main': (context) => const MainScreen(),
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const BluetoothScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('Uygulama durumu: $state');
    
    if (state == AppLifecycleState.paused) {
      debugPrint('⚠️ Uygulama arka planda - Sensör takibi devam ediyor');
    } else if (state == AppLifecycleState.resumed) {
      debugPrint('✅ Uygulama ön planda');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Ana Sayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.bluetooth_outlined),
            selectedIcon: Icon(Icons.bluetooth),
            label: 'Bluetooth',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ayarlar',
          ),
        ],
      ),
      drawer: const AppDrawer(),
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade700,
              Colors.blue.shade50,
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.favorite,
                      size: 40,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Akıllı Güvenlik',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Sağlık & Güvenlik Takibi',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.dashboard_outlined,
              title: 'Ana Sayfa',
              subtitle: 'Anlık veriler',
              onTap: () => Navigator.pop(context),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.history_outlined,
              title: 'Geçmiş Veriler',
              subtitle: 'Analiz & raporlar',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HistoryScreen(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.person_outline,
              title: 'Profilim',
              subtitle: 'Kişisel bilgiler',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.bluetooth_outlined,
              title: 'Bluetooth',
              subtitle: 'Cihaz bağlantısı',
              onTap: () => Navigator.pop(context),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.settings_outlined,
              title: 'Ayarlar',
              subtitle: 'Uygulama tercihleri',
              onTap: () => Navigator.pop(context),
            ),
            const Divider(height: 32),
            _buildDrawerItem(
              context,
              icon: Icons.help_outline,
              title: 'Yardım & Destek',
              subtitle: 'SSS ve iletişim',
              onTap: () {
                Navigator.pop(context);
                _showHelpDialog(context);
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.info_outline,
              title: 'Hakkında',
              subtitle: 'Versiyon 1.0.0',
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.blue.shade700),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      onTap: onTap,
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue),
            SizedBox(width: 12),
            Text('Yardım & Destek'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sıkça Sorulan Sorular:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildHelpItem('Cihaz nasıl bağlanır?', 
                'Bluetooth menüsünden cihazınızı arayın ve bağlan butonuna tıklayın.'),
              _buildHelpItem('Alarm nasıl kapatılır?', 
                'Dashboard\'da "Alarmları Temizle" butonunu kullanın.'),
              _buildHelpItem('İletişim', 
                'destek@akilliguvenlik.com\n+90 555 000 0000'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '❓ $question',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Akıllı Güvenlik Sistemi',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.favorite,
          size: 40,
          color: Colors.red,
        ),
      ),
      children: [
        const SizedBox(height: 16),
        const Text(
          'Giyilebilir sensör tabanlı akıllı güvenlik ve sağlık takip sistemi.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Bu uygulama yaşlı ve hasta bireylerin güvenliğini sağlamak için geliştirilmiştir.',
        ),
        const SizedBox(height: 16),
        Text(
          '© 2026 Tüm hakları saklıdır.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}