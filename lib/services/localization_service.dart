import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService extends ChangeNotifier {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  String _currentLanguage = 'en'; // Default: English
  
  String get currentLanguage => _currentLanguage;
  bool get isEnglish => _currentLanguage == 'en';
  bool get isTurkish => _currentLanguage == 'tr';

  // Dil değiştir
  Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);
    notifyListeners();
  }

  // Kaydedilmiş dili yükle
  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('language') ?? 'en'; // Default English
    notifyListeners();
  }

  // Dil toggle
  Future<void> toggleLanguage() async {
    await setLanguage(_currentLanguage == 'en' ? 'tr' : 'en');
  }

  // Çeviri al
  String translate(String key) {
    return _translations[_currentLanguage]?[key] ?? key;
  }

  // Kısa kullanım için
  String t(String key) => translate(key);
}

// Tüm çeviriler
final Map<String, Map<String, String>> _translations = {
  'en': {
    // App Title & General
    'app_title': 'Smart Security System',
    'app_subtitle': 'Wearable Sensor System',
    'system_starting': 'System starting...',
    'ok': 'OK',
    'cancel': 'Cancel',
    'save': 'Save',
    'delete': 'Delete',
    'yes': 'Yes',
    'no': 'No',
    'back': 'Back',
    'loading': 'Loading...',
    
    // Navigation
    'dashboard': 'Dashboard',
    'bluetooth': 'Bluetooth',
    'history': 'History',
    'profile': 'Profile',
    'settings': 'Settings',
    
    // Dashboard
    'good_morning': 'Good Morning',
    'good_afternoon': 'Good Afternoon',
    'good_evening': 'Good Evening',
    'good_night': 'Good Night',
    'heart_rate': 'Heart Rate',
    'accelerometer_data': 'Accelerometer Data',
    'movement_status': 'Movement Status',
    'emergency_button': 'EMERGENCY',
    'press_for_emergency': 'Press for emergency',
    'normal_range': 'Normal',
    'bpm': 'BPM',
    
    // Connection Status
    'connected': 'Connected',
    'disconnected': 'Disconnected',
    'not_connected': 'Not Connected',
    'connect_device': 'Connect Device',
    'device_name': 'Device Name',
    
    // Alarms
    'fall_detected': 'Fall Detected!',
    'fall_detected_desc': 'Emergency protocol initiated',
    'inactivity_detected': 'Prolonged Inactivity',
    'inactivity_detected_desc': 'No movement detected for',
    'minutes': 'minutes',
    'abnormal_heart_rate': 'Abnormal Heart Rate',
    'abnormal_hr_desc': 'Pulse',
    'outside_range': 'Outside normal range!',
    'manual_emergency': 'Manual Emergency',
    'manual_emergency_desc': 'User called for help',
    'clear_alarms': 'Clear Alarms',
    'stop_alarm': 'STOP ALARM',
    'alarm_stopped': 'Alarm stopped',
    
    // Movement
    'moving': 'Moving',
    'not_moving': 'Not Moving',
    'user_active': 'User is active',
    'monitoring_inactivity': 'Monitoring inactivity duration',
    
    // Bluetooth Screen
    'bluetooth_connection': 'Bluetooth Connection',
    'scan_devices': 'Scan Devices',
    'stop_scanning': 'Stop Scanning',
    'scanning': 'Scanning for devices...',
    'no_devices_found': 'No devices found yet',
    'tap_to_scan': 'Tap the button above to scan',
    'unknown_device': 'Unknown Device',
    'signal': 'Signal',
    'connect': 'Connect',
    'disconnect': 'Disconnect',
    'connecting': 'Connecting...',
    'connected_to': 'Connected to',
    'connection_lost': 'Connection lost',
    'connection_error': 'Connection error',
    
    // Settings Screen
    'heart_rate_thresholds': 'Heart Rate Thresholds',
    'minimum_heart_rate': 'Minimum Heart Rate (bpm)',
    'maximum_heart_rate': 'Maximum Heart Rate (bpm)',
    'inactivity_detection': 'Inactivity Detection',
    'inactivity_timeout': 'Inactivity Timeout (minutes)',
    'inactivity_timeout_help': 'Alarm will trigger after this duration',
    'emergency_contact': 'Emergency Contact',
    'caregiver_name': 'Caregiver Name',
    'phone_number': 'Phone Number',
    'phone_help': 'Phone number for emergencies',
    'notification_settings': 'Notification Settings',
    'fall_notifications': 'Fall Notifications',
    'fall_notif_desc': 'Notify when fall is detected',
    'inactivity_notifications': 'Inactivity Notifications',
    'inactivity_notif_desc': 'Notify when prolonged inactivity',
    'heart_rate_notifications': 'Heart Rate Notifications',
    'hr_notif_desc': 'Notify when abnormal pulse detected',
    'audio_alerts': 'Audio Alerts',
    'audio_alerts_desc': 'Play alarm sound during emergencies',
    'save_settings': 'Save Settings',
    'settings_saved': 'Settings saved!',
    'test_mode': 'Test Mode',
    'start_test_mode': 'Start Test Mode',
    'test_mode_started': 'Test mode started! Generating random data...',
    'test_mode_desc': 'Test mode: Generates random sensor data',
    'please_enter_value': 'Please enter a value',
    'enter_value_between': 'Enter value between',
    'enter_valid_phone': 'Enter a valid phone number',
    'language': 'Language',
    'english': 'English',
    'turkish': 'Turkish',
    
    // Settings Screen - Additional
    'system_settings': 'System Settings',
    'customize_preferences': 'Customize preferences',
    'important': 'IMPORTANT',
    'test_sms': 'Test SMS',
    'test_sms_send': 'Send Test SMS',
    'sending': 'Sending...',
    'first_enter_phone': 'First enter phone number',
    'test_sms_sent': 'Test SMS sent!',
    'test_sms_failed': 'Test SMS failed',
    'settings_saved_success': 'Settings saved successfully!',
    'test_mode_completed': 'Test mode completed',
    'hr_normal_info': 'Normal heart rate varies by age and physical activity. Consult your doctor to determine your personal values.',
    'emergency_warning': '⚠️ Emergency alarms will automatically send SMS to this number. Please enter a current number.',
    'test_mode_info': 'Test mode generates random sensor data. Use to test the system without a real device.',
    
    // History Screen
    'health_history': 'Health History',
    'average_heart_rate': 'Average Heart Rate',
    'active_time': 'Active Time',
    'movement_percentage': 'Movement %',
    'today': 'Today',
    'this_week': 'This Week',
    'this_month': 'This Month',
    'all_time': 'All Time',
    'heart_rate_trend': 'Heart Rate Trend',
    'heart_rate_chart': 'Heart Rate Chart',
    'hours': 'hours',
    'no_data': 'No data available',
    'recent_events': 'Recent Events',
    'alarm_history': 'Alarm History',
    'no_alarms': 'No alarms recorded',
    'average': 'Average',
    'maximum': 'Maximum',
    'minimum': 'Minimum',
    'clear_history': 'Clear History',
    'clear_history_confirm': 'Are you sure you want to delete all history?',
    'history_cleared': 'History cleared successfully',
    'clear': 'Clear',
    
    // Profile Screen
    'user_profile': 'User Profile',
    'personal_information': 'Personal Information',
    'full_name': 'Full Name',
    'date_of_birth': 'Date of Birth',
    'blood_type': 'Blood Type',
    'height': 'Height (cm)',
    'weight': 'Weight (kg)',
    'health_information': 'Health Information',
    'medications': 'Medications',
    'allergies': 'Allergies',
    'chronic_conditions': 'Chronic Conditions',
    'emergency_contacts': 'Emergency Contacts',
    'add_contact': 'Add Contact',
    'primary_contact': 'Primary Contact',
    'relationship': 'Relationship',
    'edit_profile': 'Edit Profile',
    'save_profile': 'Save Profile',
    
    // Emergency Dialog
    'emergency_call_title': 'Emergency Call',
    'emergency_call_message': 'Alert will be sent to your caregiver and emergency services. Continue?',
    'yes_send': 'Yes, Send',
    'emergency_sent': 'Emergency alert sent!',
    
    // SMS Messages (for emergency_service.dart)
    'sms_emergency_manual': 'EMERGENCY: Manual Emergency Call',
    'sms_emergency_fall': 'EMERGENCY: Fall Detected',
    'sms_emergency_hr': 'EMERGENCY: Abnormal Heart Rate',
    'sms_emergency_inactivity': 'EMERGENCY: Prolonged Inactivity',
    'sms_time': 'Time',
    'sms_location': 'Location',
    'sms_lat': 'Lat',
    'sms_long': 'Long',
    'sms_hr': 'Heart Rate',
    'sms_status': 'Status',
    'sms_need_help': 'Need immediate assistance!',
    
    // Errors
    'error': 'Error',
    'scan_error': 'Scan error',
    'permission_denied': 'Permission denied',
    'bluetooth_off': 'Bluetooth is off',
    'location_off': 'Location is off',
  },
  
  'tr': {
    // App Title & General
    'app_title': 'Akıllı Güvenlik Sistemi',
    'app_subtitle': 'Giyilebilir Sensör Sistemi',
    'system_starting': 'Sistem başlatılıyor...',
    'ok': 'Tamam',
    'cancel': 'İptal',
    'save': 'Kaydet',
    'delete': 'Sil',
    'yes': 'Evet',
    'no': 'Hayır',
    'back': 'Geri',
    'loading': 'Yükleniyor...',
    
    // Navigation
    'dashboard': 'Ana Sayfa',
    'bluetooth': 'Bluetooth',
    'history': 'Geçmiş',
    'profile': 'Profil',
    'settings': 'Ayarlar',
    
    // Dashboard
    'good_morning': 'Günaydın',
    'good_afternoon': 'İyi Günler',
    'good_evening': 'İyi Akşamlar',
    'good_night': 'İyi Geceler',
    'heart_rate': 'Kalp Atışı',
    'accelerometer_data': 'İvmeölçer Verileri',
    'movement_status': 'Hareket Durumu',
    'emergency_button': 'ACİL DURUM',
    'press_for_emergency': 'Acil durum için basın',
    'normal_range': 'Normal',
    'bpm': 'atım/dk',
    
    // Connection Status
    'connected': 'Bağlı',
    'disconnected': 'Bağlantı Kesildi',
    'not_connected': 'Bağlı Değil',
    'connect_device': 'Cihaza Bağlan',
    'device_name': 'Cihaz Adı',
    
    // Alarms
    'fall_detected': 'Düşme Tespit Edildi!',
    'fall_detected_desc': 'Acil durum protokolü başlatıldı',
    'inactivity_detected': 'Uzun Süreli Hareketsizlik',
    'inactivity_detected_desc': 'Hareket tespit edilemedi',
    'minutes': 'dakika',
    'abnormal_heart_rate': 'Anormal Kalp Atışı',
    'abnormal_hr_desc': 'Nabız',
    'outside_range': 'Normal aralığın dışında!',
    'manual_emergency': 'Manuel Acil Durum',
    'manual_emergency_desc': 'Kullanıcı yardım çağırdı',
    'clear_alarms': 'Alarmları Temizle',
    'stop_alarm': 'ALARMI DURDUR',
    'alarm_stopped': 'Alarm durduruldu',
    
    // Movement
    'moving': 'Hareket Var',
    'not_moving': 'Hareketsiz',
    'user_active': 'Kullanıcı aktif',
    'monitoring_inactivity': 'Hareketsizlik süresi izleniyor',
    
    // Bluetooth Screen
    'bluetooth_connection': 'Bluetooth Bağlantısı',
    'scan_devices': 'Cihaz Ara',
    'stop_scanning': 'Aramayı Durdur',
    'scanning': 'Cihazlar aranıyor...',
    'no_devices_found': 'Henüz cihaz bulunamadı',
    'tap_to_scan': 'Arama yapmak için yukarıdaki butona basın',
    'unknown_device': 'Bilinmeyen Cihaz',
    'signal': 'Sinyal',
    'connect': 'Bağlan',
    'disconnect': 'Bağlantıyı Kes',
    'connecting': 'Bağlanıyor...',
    'connected_to': 'Bağlandı',
    'connection_lost': 'Bağlantı kesildi',
    'connection_error': 'Bağlantı hatası',
    
    // Settings Screen
    'heart_rate_thresholds': 'Kalp Atışı Eşikleri',
    'minimum_heart_rate': 'Minimum Nabız (atım/dk)',
    'maximum_heart_rate': 'Maximum Nabız (atım/dk)',
    'inactivity_detection': 'Hareketsizlik Tespiti',
    'inactivity_timeout': 'Hareketsizlik Süresi (dakika)',
    'inactivity_timeout_help': 'Bu süre boyunca hareket yoksa alarm verilir',
    'emergency_contact': 'Acil Durum İletişim',
    'caregiver_name': 'Bakıcı Adı',
    'phone_number': 'Telefon Numarası',
    'phone_help': 'Acil durumlarda aranacak numara',
    'notification_settings': 'Bildirim Ayarları',
    'fall_notifications': 'Düşme Bildirimleri',
    'fall_notif_desc': 'Düşme tespit edildiğinde bildir',
    'inactivity_notifications': 'Hareketsizlik Bildirimleri',
    'inactivity_notif_desc': 'Uzun süre hareketsizlik tespit edildiğinde bildir',
    'heart_rate_notifications': 'Kalp Atışı Bildirimleri',
    'hr_notif_desc': 'Anormal nabız tespit edildiğinde bildir',
    'audio_alerts': 'Sesli Uyarılar',
    'audio_alerts_desc': 'Alarm durumlarında ses çal',
    'save_settings': 'Ayarları Kaydet',
    'settings_saved': 'Ayarlar kaydedildi!',
    'test_mode': 'Test Modu',
    'start_test_mode': 'Test Modu Başlat',
    'test_mode_started': 'Test modu başlatıldı! Rastgele veri üretiliyor...',
    'test_mode_desc': 'Test modu: Rastgele sensör verisi üretir',
    'please_enter_value': 'Lütfen bir değer girin',
    'enter_value_between': 'arası bir değer girin',
    'enter_valid_phone': 'Geçerli bir telefon numarası girin',
    'language': 'Dil',
    'english': 'İngilizce',
    'turkish': 'Türkçe',
    
    // Settings Screen - Additional
    'system_settings': 'Sistem Ayarları',
    'customize_preferences': 'Tercihleri özelleştirin',
    'important': 'ÖNEMLİ',
    'test_sms': 'Test SMS',
    'test_sms_send': 'Test SMS Gönder',
    'sending': 'Gönderiliyor...',
    'first_enter_phone': 'Önce telefon numarası girin',
    'test_sms_sent': 'Test SMS gönderildi!',
    'test_sms_failed': 'Test SMS gönderilemedi',
    'settings_saved_success': 'Ayarlar başarıyla kaydedildi!',
    'test_mode_completed': 'Test modu tamamlandı',
    'hr_normal_info': 'Normal kalp atışı yaşa ve fiziksel aktiviteye göre değişir. Kişisel değerlerinizi belirlemek için doktorunuza danışın.',
    'emergency_warning': '⚠️ Acil durum alarmları otomatik olarak bu numaraya SMS gönderecektir. Lütfen güncel bir numara girin.',
    'test_mode_info': 'Test modu rastgele sensör verisi üretir. Sistemi gerçek bir cihaz olmadan test etmek için kullanın.',
    
    // History Screen
    'health_history': 'Sağlık Geçmişi',
    'average_heart_rate': 'Ortalama Kalp Atışı',
    'active_time': 'Aktif Süre',
    'movement_percentage': 'Hareket %',
    'today': 'Bugün',
    'this_week': 'Bu Hafta',
    'this_month': 'Bu Ay',
    'all_time': 'Tümü',
    'heart_rate_trend': 'Kalp Atışı Trendi',
    'heart_rate_chart': 'Kalp Atışı Grafiği',
    'hours': 'saat',
    'no_data': 'Veri bulunamadı',
    'recent_events': 'Son Olaylar',
    'alarm_history': 'Alarm Geçmişi',
    'no_alarms': 'Alarm kaydı yok',
    'average': 'Ortalama',
    'maximum': 'Maksimum',
    'minimum': 'Minimum',
    'clear_history': 'Geçmişi Temizle',
    'clear_history_confirm': 'Tüm geçmişi silmek istediğinize emin misiniz?',
    'history_cleared': 'Geçmiş başarıyla temizlendi',
    'clear': 'Temizle',
    
    // Profile Screen
    'user_profile': 'Kullanıcı Profili',
    'personal_information': 'Kişisel Bilgiler',
    'full_name': 'Ad Soyad',
    'date_of_birth': 'Doğum Tarihi',
    'blood_type': 'Kan Grubu',
    'height': 'Boy (cm)',
    'weight': 'Kilo (kg)',
    'health_information': 'Sağlık Bilgileri',
    'medications': 'İlaçlar',
    'allergies': 'Alerjiler',
    'chronic_conditions': 'Kronik Hastalıklar',
    'emergency_contacts': 'Acil Durum Kişileri',
    'add_contact': 'Kişi Ekle',
    'primary_contact': 'Birincil Kişi',
    'relationship': 'Yakınlık',
    'edit_profile': 'Profili Düzenle',
    'save_profile': 'Profili Kaydet',
    
    // Emergency Dialog
    'emergency_call_title': 'Acil Durum Çağrısı',
    'emergency_call_message': 'Bakıcınıza ve acil servislere uyarı gönderilecek. Devam etmek istiyor musunuz?',
    'yes_send': 'Evet, Gönder',
    'emergency_sent': 'Acil durum uyarısı gönderildi!',
    
    // SMS Messages
    'sms_emergency_manual': 'ACİL DURUM: Manuel Acil Çağrı',
    'sms_emergency_fall': 'ACİL DURUM: Düşme Tespit Edildi',
    'sms_emergency_hr': 'ACİL DURUM: Anormal Kalp Atışı',
    'sms_emergency_inactivity': 'ACİL DURUM: Uzun Süreli Hareketsizlik',
    'sms_time': 'Zaman',
    'sms_location': 'Konum',
    'sms_lat': 'Enlem',
    'sms_long': 'Boylam',
    'sms_hr': 'Kalp Atışı',
    'sms_status': 'Durum',
    'sms_need_help': 'Acil yardım gerekiyor!',
    
    // Errors
    'error': 'Hata',
    'scan_error': 'Tarama hatası',
    'permission_denied': 'İzin reddedildi',
    'bluetooth_off': 'Bluetooth kapalı',
    'location_off': 'Konum kapalı',
  },
};