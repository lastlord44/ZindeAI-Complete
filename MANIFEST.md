ZindeAI - AI-Powered Fitness & Nutrition App — Detaylı Manifest ve Proje Şablonu (GitHub İçin)
1. Proje Hedefi ve Özet
Kapsam:
Google Gemini AI ile Türk pazarı için AI temelli fitness/diyet uygulaması.
Felsefe:
$500 bütçe, free modeller, en hızlı MVP için "para bitene kadar ilerle" mantığı.
Platformlar:
Flutter (Android first) + Supabase Edge Functions backend + Google AI Studio.
Pricing:
Ücretsiz (günde 2 plan) + Premium (sınırsız, progression/gif rehberi, 89TL)

2. Proje Klasör Yapısı
text
ZindeAI_Projesi/
├─ README.md                # Kapsamlı proje dökümanı
├─ MANIFEST.md              # Ayrıntılı strateji ve roadmap (bu doküman)
├─ pubspec.yaml             # Flutter bağımlılıkları
├─ lib/                     # Flutter uygulama kodu
│  ├─ main.dart             # Ana uygulama dosyası
│  ├─ models/               # Veri modelleri
│  ├─ screens/              # UI ekranları
│  ├─ services/             # API servisleri
│  ├─ utils/                # Yardımcı fonksiyonlar
│  └─ widgets/              # UI bileşenleri
├─ supabase/                # Supabase backend
│  ├─ functions/            # Edge Functions
│  │  └─ zindeai-router/    # Ana AI router
│  └─ config.toml           # Supabase config
├─ android/                 # Android platform dosyaları
├─ ios/                     # iOS platform dosyaları
├─ docs/                    # Dokümantasyon
│  ├─ api.md                # API endpoint açıklamaları
│  ├─ deployment.md         # Kurulum ve deployment
│  └─ test_guide.md         # Test rehberi
└─ tests/                   # Test dosyaları
3. Teknik Özellikler & Strateji
🔄 AI Entegrasyonu
Google Gemini 1.5 Flash (Google AI Studio)
- API Key: Environment variable'dan alınır
- Project: Environment variable'dan alınır
- Doğrudan API kullanımı (Vertex AI değil)

Supabase Edge Functions
- Deno TypeScript runtime
- CORS desteği
- Authentication: API Key based
- Endpoint: /functions/v1/zindeai-router

Flutter Frontend
- Dio HTTP client
- Provider state management
- Material Design UI
- Cross-platform (Android/iOS)

💪 Fitness-Specific Features
Akıllı Split Mantığı: AI otomatik split seçimi (Full Body, Upper/Lower, Push/Pull/Legs)

Detaylı Egzersiz Planları: Set, tekrar, dinlenme süreleri, RPE değerleri

Periyodizasyon: Haftalık progression, aylık plan güncellemeleri

Yerelleştirilmiş planlar: Türk mutfağı + özel makro hedefleri

Detaylı Tarifler: Gramaj, pişirme yöntemi, süre, kalori bilgileri

Premium gating: Sınırsız AI, progresyon, detaylı rehberler

📊 API Endpointleri (docs/API.md)
POST /functions/v1/zindeai-router → AI plan oluşturma
- planType: "meal" → Beslenme planı
- planType: "workout" → Antrenman planı

GET /health → Sistem sağlık kontrolü

Flutter API Service
- SmartApiHandler: Supabase Edge Function iletişimi
- ApiService: Flutter uygulama API katmanı
- ValidationService: Input validation

🗃️ Supabase Mimarisi
Edge Functions: Deno TypeScript runtime ile serverless functions

Authentication: API Key based (anon key)

CORS: Cross-origin support for Flutter app

Environment Variables: GEMINI_API_KEY, VERTEX_PROJECT_ID

Monitoring: Supabase dashboard, Edge Function logs

Error Handling: Comprehensive error logging and user feedback

4. MVP ve Geliştirme Yol Haritası (docs/ROADMAP.md)
Hafta	Milestone	Hedef/Aksiyon
1–2	Core meal plan + AI integration	10 test kullanıcı, plan validasyonu
3–4	Workout logic, split önerisi	End-to-end çalışan prototip
5–6	Premium gating, ödeme metinleri	Canlı ödeme, ilk 5 kullanıcı
7–8	GIF entegrasyonu + feedback	20+ aktif, 8+ premium
Başarı Kriterleri
150 kullanıcı, %30 günlük aktif, %5 premium dönüşüm, 700 TL/ay gelir (Ay 1 hedef)

5. Pazarlama ve Gelir
$100 pazarlama: Google Ads + sosyal medya + mikro influencer

Referral/viral: 1 ay premium referral, progress paylaşım, local partnerships

6. Risk ve Yedek Planlar
Pivot triggers: Engagement <%20, dönüşüm <%2, teknik hata >%50, para <$100.

Fallback: Google AI Studio free tier, Supabase free tier, reklam modeli, organik büyüme.

Mevcut Hatalar:
- JSON Parsing: Edge Function string response, Flutter Map bekliyor
- UI Overflow: Uzun tarif metinleri UI'yi taşırıyor
- API Response Format: Content-Type text/plain, application/json bekleniyor

7. Kurulum Adımları (docs/DEPLOYMENT.md)
Flutter Kurulumu:
flutter pub get

Supabase Kurulumu:
npx supabase start

Environment Variables:
# supabase/.env
GEMINI_API_KEY=your_gemini_api_key_here
VERTEX_PROJECT_ID=your_project_id_here

Deploy:
supabase functions deploy zindeai-router

Flutter Run:
flutter run
8. Katkı ve Lisans
Fork → branch → commit → pull request süreci.

LISANS: Kendi ürünün için serbest; başka ürünlerde izinsiz kullanma.

9. Ekstra: Flutter Entegrasyon & JSON Şemalar
Sample API request/response ve Flutter tarafı için örnek integration kodu ile zinde, tekrar kullanılabilir bir sistem.

Flutter Models:
- MealPlan: Beslenme planı modeli
- WorkoutPlan: Antrenman planı modeli
- UserProfile: Kullanıcı profil modeli
- HealthStatus: Sağlık durumu modeli

10. Kaynak ve Yorumlar
Kaynak kodları parça parça açıklamalı şekilde dizine yayıldı.

Her dosyada, ilgili micro-strateji ve edge case notları ile dokümante edildi.

Türk pazarına optimize edilmiş, hızlı scale ve görece düşük harcama ile MVP odaklı net yol haritası içerir.

GitHub Repository: https://github.com/lastlord44/ZindeAI-Complete

