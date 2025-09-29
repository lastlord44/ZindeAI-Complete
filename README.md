# ZindeAI - AI-Powered Fitness & Nutrition App

## 🎯 Proje Özeti

ZindeAI, yapay zeka destekli kişiselleştirilmiş fitness ve beslenme planları oluşturan Flutter uygulamasıdır. Kullanıcıların fiziksel özelliklerine, hedeflerine ve tercihlerine göre özel antrenman ve beslenme planları sunar.

## ✨ Özellikler

### 🏋️ Antrenman Planları
- **AI Destekli Plan Oluşturma**: Gemini AI modeli ile kişiselleştirilmiş antrenman planları
- **Split Mantığı**: Gün sayısına göre otomatik split seçimi (Full Body, Upper/Lower, Push/Pull/Legs)
- **Egzersiz Veritabanı**: Onaylı egzersiz listesi ile güvenli planlar
- **Detaylı Bilgiler**: Set, tekrar, dinlenme süreleri ve RPE değerleri

### 🍎 Beslenme Planları
- **AI Destekli Beslenme**: Gemini modeli ile detaylı beslenme planları
- **Makro Hesaplama**: Kalori, protein, karbonhidrat, yağ hesaplamaları
- **Malzeme Detayları**: Her öğün için detaylı malzeme listesi
- **Haftalık Planlar**: 7 günlük kapsamlı beslenme programları

### 👤 Profil Yönetimi
- **Kişisel Bilgiler**: Yaş, boy, kilo, cinsiyet
- **Fitness Seviyesi**: Başlangıç, orta, ileri seviye
- **Hedef Belirleme**: Kilo alma, kilo verme, bakım
- **Tercihler**: Diyet türü, egzersiz sıklığı

## 🏗️ Teknik Mimari

### Frontend (Flutter)
- **Framework**: Flutter 3.x
- **State Management**: Provider
- **HTTP Client**: Dio
- **UI Components**: Material Design
- **Media**: Cached Network Image, Video Player
- **Utilities**: Flutter Toast, Shimmer, URL Launcher, Shared Preferences

### Backend (Supabase Edge Functions)
- **Runtime**: Deno TypeScript
- **AI Integration**: Google Vertex AI (Gemini 2.0 Flash)
- **Authentication**: API Key based
- **CORS**: Cross-origin support

### AI Entegrasyonu
- **Model**: Google Gemini 2.0 Flash
- **Platform**: Google Vertex AI
- **Location**: us-central1
- **Project**: august-journey-473119-t2
- **Authentication**: Service Account JWT

## 🚀 Kurulum

### Gereksinimler
- Flutter SDK 3.x
- Dart SDK 3.x
- Android Studio / VS Code
- Supabase CLI

### Adımlar

1. **Repository'yi klonlayın**
```bash
git clone https://github.com/lastlord44/ZindeAI.git
cd ZindeAI
```

2. **Bağımlılıkları yükleyin**
```bash
flutter pub get
```

3. **Supabase'i başlatın**
```bash
npx supabase start
```

4. **Environment değişkenlerini ayarlayın**
```bash
# supabase/.env dosyasına API anahtarlarını ekleyin
GEMINI_API_KEY=your_gemini_key
GEMINI_API_KEY=your_gemini_key
```

5. **Uygulamayı çalıştırın**
```bash
flutter run
```

## 📱 Kullanım

1. **Profil Oluşturma**: Kişisel bilgilerinizi girin
2. **Hedef Belirleme**: Fitness hedefinizi seçin
3. **Plan Oluşturma**: AI destekli planlarınızı oluşturun
4. **Takip Etme**: Günlük ilerlemenizi takip edin

## 🔧 Geliştirme

### Proje Yapısı
```
lib/
├── models/          # Veri modelleri
├── screens/         # UI ekranları
├── services/        # API servisleri
├── utils/           # Yardımcı fonksiyonlar
└── main.dart        # Ana dosya

supabase/
├── functions/       # Edge Functions
├── migrations/      # Veritabanı migrasyonları
└── schema.sql       # Veritabanı şeması
```

### API Endpoints
- `POST /functions/v1/zindeai-router` - AI plan oluşturma
  - `planType: "meal"` - Beslenme planı
  - `planType: "workout"` - Antrenman planı

## ✅ Çözülen Sorunlar

- [x] 401 Authentication Error - Supabase Edge Function auth gereksinimleri kaldırıldı
- [x] Meal Plan Fixed Examples - "Balık akşamı" gibi sabit örnekler kaldırıldı
- [x] Workout Plan Fixed Examples - Sabit egzersiz örnekleri kaldırıldı
- [x] Detailed Recipe Requirements - Gramaj, pişirme yöntemi, süre bilgileri eklendi
- [x] UI Improvements - Meal consumption tracking, workout day selection düzeltildi
- [x] Security - Service account credentials environment variables'a taşındı
- [x] 500 Internal Server Error - Vertex AI JWT authentication sorunu çözüldü
- [x] API Timeout Issues - 60 saniye timeout sorunu çözüldü
- [x] Build Errors - Meal model recipe alanı eklendi
- [x] JSON Parsing - String response handling eklendi
- [x] UI Overflow - maxLines ve ellipsis eklendi

## ❌ Mevcut Hatalar

### 1. JSON Parsing Hatası ✅ ÇÖZÜLDÜ
**Hata:** `NoSuchMethodError: Class 'String' has no instance getter 'keys'`
**Lokasyon:** `lib/services/smart_api_handler.dart:302`
**Sebep:** Edge Function JSON string döndürüyor, Flutter Map bekliyor
**Durum:** ✅ Çözüldü - Edge Function response format düzeltildi, Flutter JSON parsing güncellendi

### 2. UI Overflow Hatası ✅ ÇÖZÜLDÜ
**Hata:** `A RenderFlex overflowed by 5936 pixels on the bottom`
**Lokasyon:** `lib/screens/meal_plan_display_screen.dart`
**Sebep:** Uzun tarif metinleri UI'yi taşırıyor
**Durum:** ✅ Çözüldü - maxHeight constraints ve SingleChildScrollView eklendi

### 3. API Response Format Sorunu ✅ ÇÖZÜLDÜ
**Hata:** Edge Function `text/plain` döndürüyor, Flutter `application/json` bekliyor
**Content-Type:** `text/plain;charset=UTF-8`
**Beklenen:** `application/json`
**Durum:** ✅ Çözüldü - Content-Type: application/json; charset=utf-8 ayarlandı

### 4. Yeni Tespit Edilen Sorunlar

#### 4.1. Kas Kütlesi Hedefi İletilmiyor
**Sorun:** "Hedeflerinizdeki kas kütlesi kazanmak/korumak istiyorum" kutusu Gemini'ye iletilmiyor
**Lokasyon:** `lib/screens/profile_screen.dart` - Hedef seçimi
**Sebep:** Profile screen'deki hedef seçimi prompt'a dahil edilmiyor
**Durum:** 🔴 Düzeltilmeli

#### 4.2. Egzersiz Detayları Eksik
**Sorun:** Hareketler için beklenme süresi, doğru form, dikkat edilecek noktalar belirtilmiyor
**Lokasyon:** `supabase/functions/zindeai-router/index.ts` - Workout prompt
**Sebep:** Prompt'ta egzersiz detayları yeterince spesifik değil
**Durum:** 🔴 Düzeltilmeli

#### 4.3. Protein Miktarı Tutarsızlığı
**Sorun:** Bazı günler az protein öneriyor, tutarlı protein dağılımı yok
**Lokasyon:** `supabase/functions/zindeai-router/index.ts` - Meal prompt
**Sebep:** Protein hedefi prompt'ta yeterince vurgulanmıyor
**Durum:** 🔴 Düzeltilmeli

## 🔧 Yapılan Değişiklikler

### Edge Function (supabase/functions/zindeai-router/index.ts)
- JWT authentication kaldırıldı
- Gemini API doğrudan kullanımı
- API Key: `AIzaSyDBKGbsPR3LRs7dRYqkn4_QXEMmUvv8wE0`
- CORS headers güncellendi
- Temiz kod yapısı

### Flutter (lib/services/smart_api_handler.dart)
- String response handling eklendi
- JSON parsing güncellendi
- Error handling iyileştirildi

### Flutter (lib/models/meal_plan.dart)
- Recipe alanı eklendi
- JSON parsing güncellendi
- Tüm öğünler için recipe parsing

### Flutter (lib/screens/meal_plan_display_screen.dart)
- ListView kullanımı
- maxLines: 10 eklendi
- TextOverflow.ellipsis eklendi
- Recipe container eklendi

## 🚨 Acil Çözüm Gerekenler

### ✅ Çözülenler
1. **Edge Function Response Format:** JSON string yerine proper JSON object döndürmeli ✅
2. **Content-Type Header:** `application/json` olmalı ✅
3. **UI Layout:** Overflow için daha iyi layout çözümü ✅
4. **Error Handling:** JSON parsing için daha robust error handling ✅

### 🔴 Yeni Acil Çözüm Gerekenler
1. **Kas Kütlesi Hedefi:** Profile screen'deki hedef seçimi prompt'a dahil edilmeli
2. **Egzersiz Detayları:** Workout prompt'ına beklenme süresi, form, dikkat noktaları eklenmeli
3. **Protein Tutarlılığı:** Meal prompt'ında protein hedefi daha spesifik belirtilmeli
4. **Prompt Güncellemeleri:** Tüm prompt'lar kullanıcı hedeflerini daha iyi yansıtmalı

## 🤝 Katkıda Bulunma

1. Fork yapın
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Commit yapın (`git commit -m 'Add amazing feature'`)
4. Push yapın (`git push origin feature/amazing-feature`)
5. Pull Request oluşturun

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır. Detaylar için `LICENSE` dosyasına bakın.

## 📞 İletişim

- **Proje Sahibi**: [lastlord44](https://github.com/lastlord44)
- **GitHub**: [@lastlord44](https://github.com/lastlord44)

## 🙏 Teşekkürler

- [Flutter](https://flutter.dev/) - UI Framework
- [Supabase](https://supabase.com/) - Backend as a Service
- [Google AI Studio](https://aistudio.google.com/) - Gemini API
- [Google Gemini](https://ai.google.dev/) - AI Model API
