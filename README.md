# Giyilebilir Sensör Tabanlı Akıllı Güvenlik Sistemi

Yaşlı ve hasta bireylerin güvenliğini sağlamak için geliştirilmiş Flutter tabanlı mobil uygulama.

## 🎯 Özellikler

- 📡 **Bluetooth Bağlantısı**: Giyilebilir sensörlerle kablosuz bağlantı
- ❤️ **Kalp Atışı Takibi**: Gerçek zamanlı nabız monitörleme
- 📊 **Veri Görselleştirme**: Canlı grafikler ve istatistikler
- 🚨 **Düşme Tespiti**: İvmeölçer ile otomatik düşme algılama
- ⏰ **Hareketsizlik Alarmı**: Uzun süreli hareketsizlik uyarısı
- 🆘 **Acil Durum Butonu**: Manuel yardım çağırma
- ⚙️ **Özelleştirilebilir Ayarlar**: Eşik değerleri ve bildirim tercihleri

## 📱 Ekran Görüntüleri

_(Buraya ekran görüntüleri eklenecek)_

## 🛠️ Teknolojiler

- **Flutter** - Çapraz platform mobil geliştirme
- **Dart** - Programlama dili
- **Provider** - State management
- **flutter_blue_plus** - Bluetooth bağlantısı
- **fl_chart** - Grafik görselleştirme
- **permission_handler** - İzin yönetimi

## 📋 Gereksinimler

- Flutter SDK (3.0.0 veya üzeri)
- Dart SDK
- Android Studio / VS Code
- Android SDK (API 21+)
- Bluetooth özellikli cihaz

## 🚀 Kurulum

### 1. Projeyi klonlayın
```bash
git clone https://github.com/KULLANICI_ADINIZ/wearable-sensor-security-system.git
cd wearable-sensor-security-system
```

### 2. Bağımlılıkları yükleyin
```bash
flutter pub get
```

### 3. Android SDK yolunu ayarlayın
`android/local.properties` dosyası oluşturun:
```properties
sdk.dir=C:\\Android\\Sdk
flutter.sdk=C:\\flutter
```

### 4. Uygulamayı çalıştırın
```bash
flutter run
```

## 📦 Bağımlılıklar
```yaml
dependencies:
  flutter_blue_plus: ^1.31.15
  permission_handler: ^11.0.1
  fl_chart: ^0.65.0
  provider: ^6.1.1
  cupertino_icons: ^1.0.2
```

## 🔧 Yapılandırma

### Android İzinleri
`android/app/src/main/AndroidManifest.xml` dosyasında gerekli izinler:
- Bluetooth
- Konum (Bluetooth tarama için gerekli)

### Ayarlar
Uygulama içinden aşağıdaki değerler özelleştirilebilir:
- Minimum kalp atışı (varsayılan: 40 bpm)
- Maximum kalp atışı (varsayılan: 120 bpm)
- Hareketsizlik süresi (varsayılan: 30 dakika)
- Düşme eşiği (varsayılan: 2.5 G)

## 📖 Kullanım

1. **Bluetooth Bağlantısı**
   - "Bluetooth" sekmesine gidin
   - "Cihaz Ara" butonuna basın
   - Giyilebilir cihazınızı seçin ve "Bağlan"

2. **İzleme**
   - Ana sayfada gerçek zamanlı verileri görüntüleyin
   - Grafiklerde kalp atışı geçmişini takip edin

3. **Acil Durum**
   - Kırmızı "ACİL DURUM" butonuna basın
   - Onaylayın - bakıcı ve acil servisler bilgilendirilir

## 🏗️ Proje Yapısı
```
lib/
├── main.dart                 # Uygulama giriş noktası
├── providers/
│   └── sensor_data_provider.dart  # State management
└── screens/
    ├── dashboard_screen.dart      # Ana ekran
    ├── bluetooth_screen.dart      # Bluetooth yönetimi
    └── settings_screen.dart       # Ayarlar
