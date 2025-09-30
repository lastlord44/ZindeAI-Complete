# ZindeAI - AI-Powered Fitness & Nutrition App

## 🎯 Proje Özeti

ZindeAI, yapay zeka destekli kişiselleştirilmiş fitness ve beslenme planları oluşturan Flutter uygulamasıdır. Kullanıcıların fiziksel özelliklerine, hedeflerine ve tercihlerine göre özel antrenman ve beslenme planları sunar.

## ✨ Özellikler

### 🏋️ Antrenman Planları
- **AI Destekli Plan Oluşturma**: Google Gemini 1.5 Flash modeli ile kişiselleştirilmiş antrenman planları
- **Split Mantığı**: Gün sayısına göre otomatik split seçimi (Full Body, Upper/Lower, Push/Pull/Legs)
- **Egzersiz Veritabanı**: Onaylı egzersiz listesi ile güvenli planlar
- **Detaylı Bilgiler**: Set, tekrar, dinlenme süreleri ve RPE değerleri

### 🍎 Beslenme Planları
- **AI Destekli Beslenme**: Google Gemini 1.5 Flash modeli ile detaylı beslenme planları
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

### Backend (Supabase)
- **Database**: PostgreSQL
- **Edge Functions**: Deno TypeScript
- **Authentication**: Supabase Auth
- **Storage**: Supabase Storage

### AI Entegrasyonu
- **Model**: Google Gemini 1.5 Flash
- **Platform**: Google AI Studio
- **Her iki plan türü için (antrenman ve beslenme)**

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

## 🚨 ACİL ÇÖZÜLMESİ GEREKEN HATALAR

### 1. 🔴 KRİTİK: Protein Önerisi Sorunu
**Sorun:** AI bazı günler 85 gram gibi düşük protein öneriyor, sütlaç ve pizza gibi sağlıksız yiyecekler öneriyor
**Lokasyon:** `supabase/functions/zindeai-router/index.ts` - AI prompt
**Sebep:** Prompt'ta sağlıklı beslenme kuralları yeterince vurgulanmamış
**Etki:** Kullanıcılar sağlıksız beslenme planları alıyor, protein hedefleri tutmuyor
**Durum:** ✅ ÇÖZÜLDÜ - Sağlıklı beslenme kuralları prompt'a eklendi

### 2. 🔴 KRİTİK: Profil Hedef Seçenekleri
**Sorun:** "Kas Kütlesini Korumak İstiyorum" seçeneği kaldırıldı, yeni hedef seçenekleri eklendi
**Lokasyon:** `lib/screens/profile_screen.dart` - Hedef dropdown
**Sebep:** Kullanıcı isteği doğrultusunda hedef seçenekleri güncellendi
**Etki:** Daha net hedef seçimi, kas + kilo alma/kazanma kombinasyonları
**Durum:** ✅ ÇÖZÜLDÜ - Yeni hedef seçenekleri eklendi

### 3. 🔴 KRİTİK: Alerjen Uyarıları
**Sorun:** Beslenme planlarında alerjen uyarıları gösterilmiyordu
**Lokasyon:** `lib/screens/meal_plan_display_screen.dart` - Malzemeler bölümü
**Sebep:** Alerjen uyarı sistemi kaldırılmıştı
**Etki:** Kullanıcılar alerjen riski konusunda bilgilendirilmiyor
**Durum:** ✅ ÇÖZÜLDÜ - Alerjen uyarıları geri eklendi

### 4. 🔴 KRİTİK: Antrenman Süresi Gösterimi
**Sorun:** "8 hafta" gibi süre gösterimi yerine takvim formatı isteniyordu
**Lokasyon:** `lib/screens/workout_plan_display_screen.dart` - Süre gösterimi
**Sebep:** Beslenme planındaki gibi takvim formatı daha kullanıcı dostu
**Etki:** Daha anlaşılır süre gösterimi
**Durum:** ✅ ÇÖZÜLDÜ - Takvim formatına çevrildi

## ✅ ÇÖZÜLEN HATALAR

### 1. JSON Parsing Hatası ✅ ÇÖZÜLDÜ
**Hata:** `NoSuchMethodError: Class 'String' has no instance getter 'keys'`
**Durum:** ✅ Çözüldü - Edge Function response format düzeltildi

### 2. UI Overflow Hatası ✅ ÇÖZÜLDÜ
**Hata:** `A RenderFlex overflowed by 5936 pixels on the bottom`
**Durum:** ✅ Çözüldü - Responsive layout eklendi

### 3. API Response Format Sorunu ✅ ÇÖZÜLDÜ
**Hata:** Edge Function `text/plain` döndürüyor, Flutter `application/json` bekliyor
**Durum:** ✅ Çözüldü - Content-Type düzeltildi

## 🔧 YAPILACAKLAR LİSTESİ

### Acil (Bugün)
1. **Kas Kütlesi Checkbox State Fix** - Profile screen'deki state management düzelt
2. **Edge Function API Format Fix** - Yeni prompt formatına uygun API çağrısı
3. **Meal Plan Display TypeError Fix** - firstWhere callback tip hatası
4. **Workout Plan Data Parse Fix** - Veri formatı uyumsuzluğu

### Önemli (Bu Hafta)
1. **Öğün Takip Butonları** - Visual feedback ve state management
2. **Takvim Günü Düzeltme** - Pazartesi başlangıç
3. **Protein Hesaplama Tutarlılığı** - Prompt'ta protein hedefi vurgulama
4. **Egzersiz Detayları** - Rest time, form tips, RPE değerleri

### İyileştirme (Gelecek)
1. **Error Boundary** - Graceful error handling
2. **Loading States** - Better UX during API calls
3. **Offline Mode** - Local data persistence
4. **Performance** - API response caching

## 📋 SON DURUM RAPORU (1 Ekim 2025)

### ✅ BAŞARILI DEĞİŞİKLİKLER
- **Edge Function:** Profesyonel diyetisyen ve antrenör prompt'ları eklendi
- **Validation:** Kalori/protein/yasak besin kontrolü eklendi
- **UI:** Bottom overflow hataları düzeltildi (SingleChildScrollView)
- **Prompt:** Temperature 0.1'e düşürüldü, System Instruction eklendi
- **Güvenlik:** Node.js bağımlılıkları kaldırıldı, sadece Supabase kullanılıyor

### 🔴 BİLİNEN SORUNLAR

#### 1. 🚨 KRİTİK: AI Kalori/Protein Hedeflerini Tutturmuyor
**Sorun:** Kullanıcı 2963 kcal için plan istese bile AI 1810 kcal öneriyor
**Sebep:** Gemini AI prompt'taki hedefleri göz ardı ediyor
**Durum:** Validation eklenmiş ama AI hala düşük değerler veriyor
**Çözüm Denemesi:** 
- ✅ Temperature 0.1'e düşürüldü
- ✅ System Instruction eklendi
- ✅ Prompt başına net uyarılar eklendi
- ✅ Validation kontrolü eklendi (hatalı planları reddeder)

#### 2. 🚨 KRİTİK: Yasak Besinler Öneriliyor
**Sorun:** AI simit, gözleme, börek gibi yasak besinler öneriyor
**Sebep:** Prompt'ta yasak listesi yeterince vurgulanmamış olabilir
**Durum:** Validation ile yakalanıyor ama AI hala önermeye çalışıyor
**Çözüm:** Yasak besin listesi tek tek eklendi, validation kontrolü aktif

#### 3. 🔴 ORTA: Antrenman Rest Günü Problemi
**Sorun:** 5 gün seçildiğinde AI "Perşembe Rest" günü ekliyor
**Sebep:** AI gün sayısını yanlış yorumluyor
**Durum:** Validation eklendi, Rest günü bulunursa plan reddediliyor
**Çözüm:** Prompt'a "Rest günü EKLEME!" talimatı eklendi

### 🎯 ÖNCELİK SIRASI (Sonraki Adımlar)
1. **Retry Mekanizması:** Validation başarısız olursa yeniden deneme
2. **Farklı AI Model:** Gemini-Pro veya Claude denemesi
3. **Manuel Override:** Kullanıcı manuel kalori/protein girebilsin
4. **Better Prompting:** Few-shot learning örnekleri ekle

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
