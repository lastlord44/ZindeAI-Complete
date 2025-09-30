# 🚀 ZindeAI Kurulum Rehberi

## ⚠️ ÖNEMLİ: API Key Kurulumu

### 1. Supabase Edge Functions Environment Variables

```bash
# Supabase functions klasörüne git
cd supabase/functions

# Environment dosyasını oluştur
cp env.example .env

# .env dosyasını düzenle
nano .env
```

### 2. .env Dosyasına Ekle

```env
# Gemini AI API Key
GEMINI_API_KEY=AIzaSyAhWAeJh5moGPPktIuKIGfgbZ12reNd-7k

# Supabase Configuration
SUPABASE_URL=https://uhibpbwgvnvasxlvcohr.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVoaWJwYndndm52YXN4bHZjb2hyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1Mjg2MDMsImV4cCI6MjA3NDEwNDYwM30.kZLLAiRyWuFsr-Lb8qzR7KXoSoH_7AVtgEkK9sZEGj8
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here
```

### 3. Supabase Functions Deploy

```bash
# Supabase functions'ları deploy et
npx supabase functions deploy

# Veya local development için
npx supabase functions serve
```

### 4. Flutter Uygulaması

```bash
# Ana dizine dön
cd ../..

# Dependencies yükle
flutter pub get

# Uygulamayı çalıştır
flutter run
```

## 🔒 Güvenlik

- ✅ API key'ler .env dosyasında
- ✅ .env dosyası .gitignore'da
- ✅ GitHub'a sensitive data push edilmez
- ✅ Production'da environment variables kullanılır

## 🐛 Sorun Giderme

### API Key Bulunamadı Hatası
```bash
# .env dosyasının var olduğunu kontrol et
ls -la supabase/functions/.env

# Environment variable'ları kontrol et
cat supabase/functions/.env
```

### Fallback Çalışıyor
- API key'in doğru olduğunu kontrol et
- Supabase functions'ın deploy edildiğini kontrol et
- Environment variable'ların yüklendiğini kontrol et














