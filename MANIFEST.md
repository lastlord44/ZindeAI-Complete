ZindeAI Router Worker — Detaylı Manifest ve Proje Şablonu (GitHub İçin)
1. Proje Hedefi ve Özet
Kapsam:
Gemini Flash AI ile Türk pazarı için AI temelli fitness/diyet backend.
Felsefe:
$500 bütçe, free modeller, en hızlı MVP için “para bitene kadar ilerle” mantığı.
Platformlar:
Flutter (Android first) + Cloudflare Worker backend + Cloud Storage GIF sistemi.
Pricing:
Ücretsiz (günde 2 plan) + Premium (sınırsız, progression/gif rehberi, 89TL)

2. Proje Klasör Yapısı
text
zindeai-router-worker/
├─ README.md                # Kapsamlı proje dökümanı
├─ MANIFEST.md              # Ayrıntılı strateji ve roadmap (bu doküman)
├─ wrangler.toml            # Cloudflare Worker config (KV, secret, vars)
├─ package.json             # NPM bağımlılıkları
├─ tsconfig.json            # TypeScript config
├─ src/
│  └─ index.ts              # Ana Worker kodu
├─ docs/
│  ├─ API.md                # Endpoint açıklamaları
│  ├─ DEPLOYMENT.md         # Kurulum ve Deployment adımları
│  ├─ ARCHITECTURE.md       # Detaylı teknik mimari
│  └─ ROADMAP.md            # 8 haftalık milestone ve hedefler
├─ scripts/
│  ├─ setup.sh              # Hızlı kurulum scripti
│  └─ deploy.sh             # Production deployment scripti
└─ examples/
   ├─ meal_plan_request.json # Örnek API isteği
   ├─ workout_request.json   # Örnek API isteği
   └─ flutter_integration.dart # Flutter entegrasyon örneği[1]
3. Teknik Özellikler & Strateji
🔄 Akıllı Fallback Chain
Gemini 1.5 Flash (hız + yüksek kota, ilk deneme)

Gemini 2.5 Flash (free tier)

HuggingFace (yedek, düşük maliyet)

Degrade Mode (offline deterministic JSON plan)

Limit/Hata tabanlı geçiş:
%90 kota dolduysa veya 429/5xx hata aldıysa sıradaki LLM, hepsi dolarsa degrade (network/kullanıcıyı asla üzmez).

💪 Fitness-Specific Features
Akıllı Split Mantığı: 1–2 gün full body, üstü için opsiyonlar, 6+ ay deneyim gerekir koşulu.

GIF-destekli Egzersizler: Google Cloud Storage’tan proxy + local cache, fallback: metin rehber.

Periyodizasyon: Haftalık (+1 tekrar/+2.5kg), aylık (değişim/yenileme), 3 aylık (hedef review)

Yerelleştirilmiş planlar: Türk mutfağı + özel makro hedefleri.

Premium gating: Sınırsız AI, progresyon, GIF rehberi, push nudge.

📊 API Endpointleri (docs/API.md)
POST /plan → Yemek planı üretimi (AI rotası: fallback zinciri otomatik)

POST /antrenman → Egzersiz/antrenman planı (AI + GIF)

GET /health → Sistem sağlık, provider/kota canlılığı

GET /gif/{exercise_id} → GIF proxy endpoint

🗃️ Cloudflare Mimarisi
Rate Limiting: KV Namespace üzerinde günlük kota ve request sayaçları (her provider ayrık, gemini RPD PST bazlı sayılır)

Circuit Breaker: Son 60 sn’de ≥5 hata → 2dk Soğuma (otomatik re-enable)

Caching: Plan ve gif cache

Monitoring: Header üzerinden x-ratelimit ve hata yönetimi, canlı provider health

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

Fallback: HuggingFace, Supabase free fallback, reklam modeli, organik büyüme.

7. Kurulum Adımları (docs/DEPLOYMENT.md)
Wrangler yükle:
npm install -g wrangler

Secret’ları gir:

text
wrangler secret put GEMINI_API_KEY
wrangler secret put GEMINI_API_KEY
wrangler secret put HF_TOKEN
KV namespace oluştur ve wrangler.toml’a ID’leri ekle

Deploy:

text
npm install
wrangler dev           # Lokal test
wrangler deploy        # Production’a gönder
Ortam değişkenleri (örnek wrangler.toml)
text
[vars]
ROUTER_ORDER_TEXT = "gemini_flash"
SAFETY_PCT = "0.10"
GEMINI_RPD = "1000000"
HF_RPD = "1000"
GCS_BUCKET_URL = "https://storage.googleapis.com/zindeai-gifler"
8. Katkı ve Lisans
Fork → branch → commit → pull request süreci.

LISANS: Kendi ürünün için serbest; başka ürünlerde izinsiz kullanma.

9. Ekstra: Flutter Entegrasyon & JSON Şemalar (examples/)
Sample API request/response ve Flutter tarafı için örnek integration kodu ile zinde, tekrar kullanılabilir bir sistem.

10. Kaynak ve Yorumlar
Kaynak kodları parça parça açıklamalı şekilde dizine yayıldı.

Her dosyada, ilgili micro-strateji ve edge case notları ile dokümante edildi.

Türk pazarına optimize edilmiş, hızlı scale ve görece düşük harcama ile MVP odaklı net yol haritası içerir.

