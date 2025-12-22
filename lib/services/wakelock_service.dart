import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class WakeLockService {
  static bool _isEnabled = false;
  
  static Future<void> enable() async {
    try {
      await WakelockPlus.enable();
      _isEnabled = true;
      debugPrint('✅ Wake Lock aktif - Ekran sürekli açık kalacak');
    } catch (e) {
      debugPrint('❌ Wake Lock hatası: $e');
    }
  }
  
  static Future<void> disable() async {
    try {
      await WakelockPlus.disable();
      _isEnabled = false;
      debugPrint('⏸️ Wake Lock devre dışı - Normal uyku modu');
    } catch (e) {
      debugPrint('❌ Wake Lock devre dışı bırakma hatası: $e');
    }
  }
  
  static Future<bool> isEnabled() async {
    try {
      return await WakelockPlus.enabled;
    } catch (e) {
      return _isEnabled;
    }
  }
  
  static Future<void> toggle() async {
    if (await isEnabled()) {
      await disable();
    } else {
      await enable();
    }
  }
}