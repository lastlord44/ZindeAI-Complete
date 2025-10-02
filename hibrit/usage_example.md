# 🔥 ZindeAI Hibrit Sistem - Kullanım Kılavuzu

## 📦 Kurulum Adımları

### 1. Dosyaları Projeye Ekle

```
lib/
├── services/
│   ├── hybrid_meal_ai.dart  ✅ YENİ
│   └── meal_database.dart   ✅ YENİ
└── widgets/
    └── fallback_banner.dart ✅ YENİ
```

### 2. Excel'i JSON'a Çevir

Excel dosyasını (`wger_ogle_aksam_6000.xlsx`) JavaScript ile JSON'a çevir:

```javascript
// Tarayıcı konsolunda çalıştır
import * as XLSX from 'xlsx';

const response = await window.fs.readFile('wger_ogle_aksam_6000.xlsx');
const workbook = XLSX.read(response);

const lunchSheet = workbook.Sheets['Öğle 3000'];
const dinnerSheet = workbook.Sheets['Akşam 3000'];

const lunchData = XLSX.utils.sheet_to_json(lunchSheet);
const dinnerData = XLSX.utils.sheet_to_json(dinnerSheet);

const json = {
  lunch: lunchData.map(row => ({
    meal_id: row.meal_id,
    name: row.meal_name,
    category: 'Öğle',
    calories: row.calorie,
    protein: row.protein_g,
    carbs: row.carb_g,
    fat: row.fat_g
  })),
  dinner: dinnerData.map(row => ({
    meal_id: row.meal_id,
    name: row.meal_name,
    category: 'Akşam',
    calories: row.calorie,
    protein: row.protein_g,
    carbs: row.carb_g,
    fat: row.fat_g
  }))
};

// JSON'u indir
const blob = new Blob([JSON.stringify(json, null, 2)], { type: 'application/json' });
const a = document.createElement('a');
a.href = URL.createObjectURL(blob);
a.download = 'meals_database.json';
a.click();
```

### 3. JSON'u meal_database.dart'a Kopyala

İndirdiğin JSON'daki verileri `meal_database.dart` dosyasındaki `_lunchMeals` ve `_dinnerMeals` listelerine yapıştır.

---

## 🚀 API Service'i Güncelle

Mevcut `api_service.dart` dosyanı güncelle:

```dart
import 'package:dio/dio.dart';
import 'hybrid_meal_ai.dart'; // EKLE

class ApiService {
  final Dio _dio;
  final String _supabaseUrl;
  late final HybridMealAI _hybridAI; // EKLE
  
  ApiService({required String supabaseUrl})
      : _supabaseUrl = supabaseUrl,
        _dio = Dio() {
    // Hibrit AI'yi başlat
    _hybridAI = HybridMealAI(
      dio: _dio,
      supabaseUrl: _supabaseUrl,
    );
  }

  // ESKİ fonksiyonu DEĞİŞTİR
  Future<Map<String, dynamic>> generateMealPlan(
    Map<String, dynamic> userProfile,
  ) async {
    // Hibrit sistemi kullan
    return await _hybridAI.generateMealPlan(
      userProfile: userProfile,
    );
  }
  
  // Fallback durumunu kontrol et
  bool get isUsingFallback => _hybridAI.isUsingFallback;
}
```

---

## 🎨 UI'da Fallback Banner Göster

### plan_selection_screen.dart'ta

```dart
// generateMealPlan çağrısından sonra:
final mealPlanResult = await apiService.generateMealPlan({...});

// Sonucu kontrol et
final bool isFallback = mealPlanResult['fallback'] ?? false;
final String? fallbackMessage = mealPlanResult['fallback_message'];
final Map<String, dynamic> plan = mealPlanResult['plan'];

// Navigate ederken fallback bilgisini de gönder
await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => MealPlanDisplayScreen(
      mealPlan: plan,
      userProfile: userProfile,
      isFallback: isFallback,        // EKLE
      fallbackMessage: fallbackMessage, // EKLE
    ),
  ),
);
```

### meal_plan_display_screen.dart'ta

Widget'ın başına ekle:

```dart
class MealPlanDisplayScreen extends StatelessWidget {
  final Map<String, dynamic> mealPlan;
  final Map<String, dynamic>? userProfile;
  final bool isFallback;              // YENİ
  final String? fallbackMessage;      // YENİ

  const MealPlanDisplayScreen({
    Key? key,
    required this.mealPlan,
    this.userProfile,
    this.isFallback = false,          // YENİ
    this.fallbackMessage,             // YENİ
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(...),
      body: Column(
        children: [
          // BANNER EKLE
          if (isFallback && fallbackMessage != null)
            FallbackBanner(
              message: fallbackMessage!,
              onRetry: () async {
                // Tekrar API'yi dene
                Navigator.pop(context); // Geri dön
                // Plan selection'a geri dön, tekrar denesin
              },
            ),
          
          // Mevcut plan görünümü
          Expanded(
            child: ListView(...),
          ),
        ],
      ),
    );
  }
}
```

---

## 🧪 Test Senaryoları

### Test 1: Gemini Çalışıyor
```
✅ Gemini API'den plan gelir
✅ Banner gösterilmez
✅ source: "gemini"
```

### Test 2: Gemini Çalışmıyor (Internet yok / API down)
```
✅ Local database'den plan gelir
✅ Turuncu banner gösterilir
✅ source: "local_database"
✅ Kullanıcı profili (kalori, protein) korunur
```

### Test 3: "Tekrar Dene" Butonu
```
✅ Banner'daki butona tıkla
✅ Gemini'yi tekrar dene
✅ Başarılıysa banner kaybolur
```

---

## 📊 Database İstatistikleri

Local database'in istatistiklerini görmek için:

```dart
final stats = MealDatabase().getStats();
print(stats);
// {
//   'lunchMeals': 3000,
//   'dinnerMeals': 3000,
//   'totalMeals': 6000,
//   'calorieRange': {'min': 441, 'max': 1245, 'avg': 750},
//   'proteinRange': {'min': 15, 'max': 60, 'avg': 35}
// }
```

---

## 🎯 Çalışma Mantığı

```
Kullanıcı "Plan Oluştur" butonuna basıyor
              ↓
    HybridMealAI başlatılıyor
              ↓
         ┌─────────┐
         │ Gemini? │
         └─────────┘
         ↙        ↘
      Evet       Hayır
        ↓          ↓
   Gemini'den   Local DB'den
   plan gelir   plan gelir
        ↓          ↓
   Banner YOK   Banner VAR
        ↓          ↓
     UI'da göster (her ikisi de aynı formatta)
```

---

## 🔥 Önemli Notlar

1. **Kalori ve Protein Hedefleri Korunur**: Local DB de kullanıcının profil bilgilerine göre hedefleri hesaplar
2. **Aynı Format**: Her iki kaynak da aynı JSON formatında döner, UI değişikliği gerekmez
3. **Çeşitlilik**: Her gün farklı öğünler için random seçim yapar
4. **Filtreleme**: Hem kalori hem protein hedefine göre en yakın öğünleri seçer
5. **Fallback Visible**: Kullanıcı offline modda olduğunu bilir

---

## 🚨 Troubleshooting

**Soru**: Local DB'den plan gelmiyor?
**Cevap**: `meal_database.dart` içindeki `_lunchMeals` ve `_dinnerMeals` listelerini kontrol et, JSON verilerini doğru yapıştırdığından emin ol.

**Soru**: Banner gösterilmiyor?
**Cevap**: `isFallback` parametresini doğru gönderdiğinden emin ol. Debug için `print(mealPlanResult)` yap.

**Soru**: Kalori tutmuyor?
**Cevap**: `targetCalories` değerini kontrol et, `_calculateCalories()` fonksiyonu doğru çalışıyor mu?

---

## ✅ Checklist

- [ ] `hybrid_meal_ai.dart` eklendi
- [ ] `meal_database.dart` eklendi  
- [ ] `fallback_banner.dart` eklendi
- [ ] Excel → JSON dönüştürüldü
- [ ] JSON verileri `meal_database.dart`'a yapıştırıldı
- [ ] `api_service.dart` güncellendi
- [ ] `plan_selection_screen.dart` güncellendi
- [ ] `meal_plan_display_screen.dart` güncellendi
- [ ] Test edildi (hem online hem offline)

---

## 🎉 Sonuç

Artık ZindeAI hem Gemini AI hem de offline local database kullanabiliyor! Kullanıcı internetse bile, API çökse bile plan alabilir. 💪