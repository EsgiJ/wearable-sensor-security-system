import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'providers/sensor_data_provider.dart';
import 'services/localization_service.dart';
import 'screens/splash_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/bluetooth_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/history_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🌍 Dil ayarını yükle
  await LocalizationService().loadLanguage();
  debugPrint('✅ Dil sistemi başlatıldı');
  
  // Bildirim sistemini başlat
  await NotificationService.initialize();
  
  // Wake Lock'u aktif et
  await WakelockPlus.enable();
  debugPrint('✅ Wake Lock aktif');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SensorDataProvider()),
        ChangeNotifierProvider(create: (_) => LocalizationService()),
      ],
      child: Consumer<LocalizationService>(
        builder: (context, localization, child) {
          return MaterialApp(
            title: localization.t('app_title'), // 🌍 Dinamik başlık
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.light,
              ),
            ),
            initialRoute: '/splash',
            routes: {
              '/splash': (context) => const SplashScreen(),
              '/main': (context) => const MainScreen(),
            },
          );
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
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SensorDataProvider>(context, listen: false);
      provider.setContext(context);
      
      // 🆕 Geçmiş verileri yükle
      provider.loadHistoryData();
    });
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
    // 🌍 Localization servisi ile navigation label'ları dinamik
    final loc = Provider.of<LocalizationService>(context);
    
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: loc.t('dashboard'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.bluetooth_outlined),
            selectedIcon: const Icon(Icons.bluetooth),
            label: loc.t('bluetooth'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history),
            label: loc.t('history'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: loc.t('settings'),
          ),
        ],
      ),
    );
  }
}