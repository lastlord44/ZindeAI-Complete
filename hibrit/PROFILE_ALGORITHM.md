# 📊 Profil Algoritması Optimizasyonun için ChatGPT
## ZindeAI Hybrid Meal Planning System

### 🎯 Algoritma Dosyaları

**Bu dosyaları ChatGPT'ye gönder:**

#### 1. **Profile Collection** 📝
- `lib/models/user_profile.dart` - Profil model sınıfı
- `lib/screens/profile_screen.dart` - Profil toplama ekranı

#### 2. **Meal Algorithm** 🍽️  
- `lib/services/hybrid_meal_ai.dart` - Ana meal planning algoritması
- `lib/services/meal_database.dart` - Local database ve kategori filtreleme

#### 3. **Profile Data Usage** 🔄
- Meal plan oluşturma sırasında profil bilgilerinin nasıl kullanıldığı
- Kalori ve protein hesaplamaları
- Kategori bazlı öğün seçimi

---

## 📋 Profil Bilgileri Analizi

### Kullanıcı Profili (user_profile.dart)
```dart
class UserProfile {
  final String sex;           // 'male' | 'female'
  final int age;              // 18-80 yaş
  final int heightCm;         // Boy cm
  final double weightKg;      // Kilo kg
  final String goal;          // 'lose', 'maintain', 'gain'
  final String activity;      // 'sedentary', 'light', 'moderate', 'very_active'
  final List<String> dietFlags; // Diyet kısıtlamaları
}
```

### Profil Toplama Süreci (profile_screen.dart)
- **Kişisel Bilgiler**: Yaş, Boy, Kilo, Cinsiyet
- **Hedef**: Kilo Verme, Kilo Alma, Kas Kütlesi Koruma
- **Aktivite Seviyesi**: Sedanter → Çok Aktif
- **Diyet Türü**: Dengeli, Vegetaryan, Vegan, Glutensiz vs.
- **Antrenman**: Haftalık antrenman günü sayısı

### Kalori Hesaplama Algoritması
```dart
// BMR (Basal Metabolic Rate)
if (sex == 'male') {
  bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
} else {
  bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
}

// TDEE (Total Daily Energy Expenditure)
final activityMultipliers = {
  'sedentary': 1.2,
  'light': 1.375,
  'moderate': 1.55,
  'very_active': 1.725,
};

// Hedef Kalori
if (goal.contains('loss')) return (tdee * 0.8).round();
if (goal.contains('gain')) return (tdee * 1.15).round();
else return tdee.round();
```

### Protein Hesaplama
```dart
double proteinMultiplier = 1.8;
if (goal.contains('gain') || goal.contains('muscle')) {
  proteinMultiplier = 2.2;
} else if (goal.contains('loss') || goal.contains('fat')) {
  proteinMultiplier = 2.0;
}
```

---

## 🍽️ Meal Selection Algorithm

### Kategori Dağılımı
```dart
final distribution = {
  'Kahvaltı': {'cal': 0.25, 'protein': 0.20},  // %25 kalori, %20 protein
  'Ara Öğün 1': {'cal': 0.10, 'protein': 0.15}, // %10 kalori, %15 protein
  'Öğle': {'cal': 0.35, 'protein': 0.35},      // %35 kalori, %35 protein  
  'Ara Öğün 2': {'cal': 0.10, 'protein': 0.15}, // %10 kalori, %15 protein
  'Akşam': {'cal': 0.20, 'protein': 0.15},      // %20 kalori, %15 protein
};
```

### Öğün Seçimi Kriterleri
1. **Kategori Filtresi**: breakfast/lunch/dinner/snack
2. **Kalori Tolerance**: ±150 (öğle), ±100 (kahvaltı/akşam), ±50 (ara öğün)
3. **Random Seed**: Gün bazlı (dayIndex) - her gün farklı öğünler
4. **Protein Hedefi**: Öğün başına hesaplanan minimum protein

---

## 🔧 Optimizasyon Önerileri için Sorular

### ChatGPT'ye Sorulacaklar:

1. **Kalori Dağılımı**: Mevcut %25-%35-%20-%5-%5 dağılımı optimal mi?
   - Sedanter vs Aktif kişiler için farklılık gerekli mi?
   - Yaş gruplarına göre değişmeli mi?

2. **Protein Timing**: Sabah kahvaltısında daha çok protein mı?
   - Antrenman sonrası öğünlerde protein artışı gerekli mi?
   - Yaşlanma karşıtı protein dağılımı

3. **Kategori Seçimi**: 
   - Antrenman günleri vs dinlenme günleri farklı mı olmalı?
   - Çok aktif kişiler için öğün sayısı artırılmalı mı?

4. **Goal-Specific Logic**:
   - Kilo verme: Daha düşük kalori kahvaltıları?
   - Kilo alma: Daha sık ara öğünler?
   - Kas kütlesi: Antrenman günleri farklı protein?

5. **Activity Level Adaptation**:
   - Sedanter: Daha az kalori gerektiren öğünler?
   - Çok aktif: Daha sık ara öğünler ve smoothie'ler?

6. **Age-Related Considerations**:
   - 50+ yaş için metabolizma kaynaklı değişiklikler?
   - Yaş ile protein gereksinimi artışı?

---

### 📊 Mevcut Veri Yapısı

**meal_gold_10000_clean.json** format:
```json
{
  "id": "MEAL:00001",
  "name_tr": "Yulaf ezmesi + süt + chia tohumu + böğürtlen",
  "kcal": 275,
  "protein_g": 14.8,
  "carb_g": 42.0,
  "fat_g": 5.2,
  "category": "breakfast",
  "grams": 250,
  "portion_text": "4 yemek kaşığı yulaf + 200 ml süt + 1 avuç böğürtlen"
}
```

**Optimizasyon Alanları:**
- Kalori toleransları (±% kaç farklılaşmalı?)
- Protein minimum değerleri
- Öğün dağılım oranları  
- Kategori geçiş kuralları
- Random seed stratejisi

---

## 🎯 ChatGPT'den Beklenen Çıktılar:

1. **Yeni Kalori Dağılım Oranları** (yaş/cinsiyet/aktivite/hedef bazında)
2. **Proein Timing Optimizasyonu** (öğün bazında minimum protein)
3. **Goal-Specific Meal Patterns** (kilo verme/alma/koruma için farklı stratejiler)
4. **Activity-Seasoned Adjustments** (sedanter vs aktif için farklı yaklaşımlar)
5. **Age-Adjusted Recommendations** (yaş grupları için metabolik ayarlar)

Bu dosyaları ChatGPT'ye göndererek algoritma optimizasyonu talep edebilirsin!
