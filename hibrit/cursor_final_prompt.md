# 🎯 CURSOR'A YAPIŞTIRACAĞIN PROMPT

```
Ben sana 3 artifact göndereceğim. Bunları projeye ekle:

1. hybrid_meal_ai.dart - Hibrit AI servisi (Gemini + Local DB)
2. meal_database.dart - 6180 öğün database (fonksiyonlar hazır, veri eklenecek)
3. fallback_banner.dart - Offline mod uyarı widget'ı

Sonra şu dosyaları güncelle:
- api_service.dart: HybridMealAI'yi import et ve kullan
- plan_selection_screen.dart: Fallback bilgisini ekrana gönder  
- meal_plan_display_screen.dart: FallbackBanner ekle

VERİ DOSYASI ÇOK BÜYÜK! (6180 öğün)
Ben sana veriyi Python scripti ile hazırladım.
Ama Cursor, sen meal_database.dart içindeki listeleri şöyle doldur:

ÖRNEK FORMAT:
```dart
static final _lunchMeals = [
  {'meal_id':'OGL-0001','name':'Mantarlı köfte + kepekli makarna (150 g) + ezme (2 yk)','category':'Öğle','calories':862,'protein':46,'carbs':72,'fat':36},
  {'meal_id':'OGL-0002','name':'Ekmek arası köfte + erişte (150 g) + cacık (1 kâse)','category':'Öğle','calories':956,'protein':60,'carbs':105,'fat':28},
  // ... 2998 tane daha
];
```

BANA EXCEL VE CSV DOSYALARI VAR. BEN SANA VERİYİ HAZIRLAYIP JSON OLARAK VERECEĞİM.

Adımlar:
1. lib/services/hybrid_meal_ai.dart oluştur (artifact 1)
2. lib/services/meal_database.dart oluştur (artifact 2 - içine ben veri ekleyeceğim)
3. lib/widgets/fallback_banner.dart oluştur (artifact 3)
4. api_service.dart'ı güncelle
5. plan_selection_screen.dart'ı güncelle
6. meal_plan_display_screen.dart'ı güncelle

ÖNEMLİ:
- meal_database.dart çok büyük olacak (~500KB), bu normal
- Tüm öğünler hard-coded Dart listesi
- Import etme, doğrudan aynı dosyada
- Random seçim için dart:math Random() kullanılıyor

SORU VAR MI?
```

---

# 📦 VERİYİ NASIL EKLEYECEKSİN

Ben sana 3 şey göndereceğim:

## 1. Artifacts (Kod Dosyaları)
- hybrid_meal_ai.dart ✅
- meal_database.dart ✅ (fonksiyonlar hazır, veri boş)
- fallback_banner.dart ✅

## 2. Veri Dosyası (Ayrı Mesaj)
Ben şimdi Excel + CSV'den veriyi çıkarıp sana **tek bir kopyalanabilir kod bloğu** olarak vereceğim.

Format:
```dart
// meal_database.dart içindeki boş listelere yapıştır

static final _lunchMeals = [
  // 3000 satır buraya gelecek
];

static final _dinnerMeals = [
  // 3000 satır buraya gelecek
];

static final _breakfastMeals = [
  // 100 satır buraya gelecek
];

static final _snackMeals = [
  // 80 satır buraya gelecek
];
```

## 3. Test Talimatları
Cursor'a diyeceksin ki:

```
Şimdi test et:

1. İnternete bağlıyken "Plan Oluştur" butonuna bas
   → Gemini'den plan gelmeli
   → Banner görünmemeli
   → Console: "✅ Gemini başarılı!"

2. İnterneti kapat veya Supabase URL'i boz
   → Plan yine gelmeli (local DB'den)
   → TURUNCU BANNER görünmeli
   → Console: "❌ Gemini API başarısız" → "🔄 Local database'e geçiliyor"

3. MealDatabase stats'ı yazdır:
   final db = MealDatabase();
   print(db.getStats());
   → totalMeals: 6180 görmeli
```

---

# ✅ BEN ŞİMDİ NE YAPACAĞIM

1. ✅ Artifacts hazır (3 dosya)
2. 🔄 Excel + CSV → Dart kod çıkarıyorum
3. 📤 Sana kopyalayıp yapıştıracağın Dart kodu göndereceğim

SEN ŞİMDİ NE YAPACAKSIN:
1. Cursor'a yukardaki prompt'u yapıştır
2. Artifacts'teki 3 dosyayı Cursor'a göster
3. Benim göndereceğim veri kodunu meal_database.dart içine yapıştır
4. Test et

HAZIR MISIN? 🚀
