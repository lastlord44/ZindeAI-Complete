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
- **Database**: Supabase Flutter

### Backend (Supabase)
- **Database**: PostgreSQL
- **Edge Functions**: Deno TypeScript
- **Authentication**: Supabase Auth
- **Storage**: Supabase Storage

### AI Entegrasyonu
- **Antrenman Planları**: Gemini 1.5 Flash
- **Beslenme Planları**: Google Gemini 1.5 Flash
- **JSON Temizleme**: Backend'de otomatik format düzeltme

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
- `POST /zindeai-router` - AI plan oluşturma
  - `requestType: "plan"` - Beslenme planı
  - `requestType: "antrenman"` - Antrenman planı

## 🐛 Bilinen Sorunlar

- [ ] GIF'lerin yüklenmemesi
- [ ] Profil ekranında yazı boyutu sorunları
- [ ] Offline mod desteği eksik

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
