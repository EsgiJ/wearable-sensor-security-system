import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telephony/telephony.dart';

class EmergencyService {
  static final Telephony _telephony = Telephony.instance;
  
  // Bakıcı bilgilerini kaydet
  static Future<void> saveCaregiverInfo({
    required String name,
    required String phone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('caregiver_name', name);
    await prefs.setString('caregiver_phone', phone);
    debugPrint('✅ Bakıcı bilgileri kaydedildi: $name - $phone');
  }
  
  // Bakıcı bilgilerini al
  static Future<Map<String, String>> getCaregiverInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('caregiver_name') ?? '',
      'phone': prefs.getString('caregiver_phone') ?? '',
    };
  }
  
  // Konum izni kontrolü ve alma
  static Future<Position?> getCurrentLocation() async {
    try {
      // Konum servisinin açık olup olmadığını kontrol et
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ Konum servisi kapalı');
        return null;
      }

      // Konum iznini kontrol et
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('❌ Konum izni reddedildi');
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ Konum izni kalıcı olarak reddedildi');
        return null;
      }

      // Konumu al
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      
      debugPrint('✅ Konum alındı: ${position.latitude}, ${position.longitude}');
      return position;
      
    } catch (e) {
      debugPrint('❌ Konum alma hatası: $e');
      return null;
    }
  }
  
  // Google Maps linki oluştur
  static String getGoogleMapsLink(Position position) {
    return 'https://www.google.com/maps?q=${position.latitude},${position.longitude}';
  }
  
  // 🆕 SMS izni kontrolü
  static Future<bool> requestSmsPermission() async {
    try {
      final bool? result = await _telephony.requestPhoneAndSmsPermissions;
      return result ?? false;
    } catch (e) {
      debugPrint('❌ SMS izni hatası: $e');
      return false;
    }
  }
  
  // 🆕 Otomatik SMS gönder (Gelişmiş Arka Plan Gönderimi)
  static Future<bool> sendEmergencySMS({
    required String emergencyType,
    Position? location,
  }) async {
    try {
      final caregiverInfo = await getCaregiverInfo();
      final phone = caregiverInfo['phone'] ?? '';
      if (phone.isEmpty) return false;

      String googleMapsLink = location != null 
          ? "https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}"
          : "Konum alinmadi";

      String message = 'ACIL DURUM: $emergencyType\nKonum: $googleMapsLink';

      // ÖNEMLİ: İzinleri al ve sonucun gelmesini bekle
      bool? permissionsGranted = await _telephony.requestPhoneAndSmsPermissions;
      
      // Eğer izin verilmişse (true) DOĞRUDAN göndermeyi dene
      if (permissionsGranted == true) {
        debugPrint('🚀 ARKA PLAN GÖNDERİMİ BAŞLADI...');
        
        await _telephony.sendSms(
          to: phone,
          message: message,
          // StatusListener'ı siliyoruz çünkü bazen akışı bekletip hataya düşürebilir
        );
        
        debugPrint('✅ ARKA PLAN SMS KOMUTU GİTTİ!');
        return true; 
      }

      // Eğer yukarıdaki blok çalışmazsa (yani izin verilmemişse) SMS uygulaması açılır
      debugPrint('⚠️ Arka plan izni yok, manuel ekran açılıyor...');
      final Uri smsUri = Uri(scheme: 'sms', path: phone, queryParameters: {'body': message});
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ SMS Hatası: $e');
      return false;
    }
  }
  
  // Bakıcıyı ara
  static Future<bool> callCaregiver() async {
    try {
      final caregiverInfo = await getCaregiverInfo();
      final phone = caregiverInfo['phone'] ?? '';
      
      if (phone.isEmpty) {
        debugPrint('❌ Bakıcı telefon numarası kayıtlı değil');
        return false;
      }
      
      final Uri phoneUri = Uri(scheme: 'tel', path: phone);
      
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        debugPrint('✅ Arama başlatıldı: $phone');
        return true;
      } else {
        debugPrint('❌ Arama başlatılamadı');
        return false;
      }
      
    } catch (e) {
      debugPrint('❌ Arama hatası: $e');
      return false;
    }
  }
  
  // Komple acil durum işlemi
  static Future<void> triggerEmergency({
    required String emergencyType,
    required BuildContext context,
  }) async {
    debugPrint('🚨 ACİL DURUM TETİKLENDİ: $emergencyType');
    
    // Bakıcı bilgilerini kontrol et
    final caregiverInfo = await getCaregiverInfo();
    if (caregiverInfo['phone']?.isEmpty ?? true) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Bakıcı telefon numarası kayıtlı değil! Lütfen ayarlardan ekleyin.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }
    
    // Konumu al
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              SizedBox(width: 16),
              Text('Konum alınıyor...'),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    }
    
    Position? location = await getCurrentLocation();
    
    // SMS gönder
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              SizedBox(width: 16),
              Text('SMS gönderiliyor...'),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
    
    bool smsSent = await sendEmergencySMS(
      emergencyType: emergencyType,
      location: location,
    );
    
    // Sonuç bildir
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                smsSent ? Icons.check_circle : Icons.error,
                color: Colors.white,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  smsSent 
                    ? '✅ Acil durum SMS\'i gönderildi!\nBakıcı: ${caregiverInfo['name']}'
                    : '❌ SMS gönderilemedi. Lütfen manuel olarak arayın.',
                ),
              ),
            ],
          ),
          backgroundColor: smsSent ? Colors.green : Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'ARA',
            textColor: Colors.white,
            onPressed: () {
              callCaregiver();
            },
          ),
        ),
      );
    }
  }
  
  // Bakıcıyı test et (ayarlar ekranı için)
  static Future<void> testCaregiverContact(BuildContext context) async {
    final caregiverInfo = await getCaregiverInfo();
    
    if (caregiverInfo['phone']?.isEmpty ?? true) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Lütfen önce bakıcı telefon numarasını kaydedin'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    
    // Test SMS'i gönder
    Position? location = await getCurrentLocation();
    bool success = await sendEmergencySMS(
      emergencyType: 'TEST MESAJI',
      location: location,
    );
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
              ? '✅ Test mesajı gönderildi!' 
              : '❌ Test mesajı gönderilemedi',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}