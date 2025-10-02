# 📁 ChatGPT İçin Dosya Özeti
## ZindeAI Profil Optimizasyonu

### 🎯 Gönderilecek Dosyalar:

#### 1️⃣ **Profil Model Yaklaşımı** 📋
**Dosya:** `lib/models/user_profile.dart`
- UserProfile sınıfı ve TrainingPreferences
- JSON serialization/deserialization 
- Profil verilerinin Dart yapısı

#### 2️⃣ **Profil Toplama Arayüzü** 📝  
**Dosya:** `lib/screens/profile_screen.dart`
- Kullanıcı input alanları (yaş, boy, kilo, cinsiyet)
- Hedef seçimi (kilo verme/alma/koruma)
- Aktivite seviyesi mapping'i
- Diet flags ve workout preferences
- Profil kaydetme mantığı

#### 3️⃣ **Ana Algoritma Motoru** 🧠
**Dosya:** `lib/services/hybrid_meal_ai.dart` 
- Profil → Kalori hesaplama (BMR/TDEE)
- Protein hesaplama (goal-based multiplier)
- Öğün dağılım algoritması (%25-%35-%20-%5-%5)
- Gün bazlı meal generation
- Random seed stratejisi (dayIndex)

#### 4️⃣ **Veri Filtreleme Motoru** 🗃️
**Dosya:** `lib/services/meal_database.dart`
- Kategori bazlı meal filtreleme
- Kalori/protein tolerance matching
- Random meal selection
- Portion size calculations

#### 5️⃣ **Algoritma Dokümanı** 📊
**Dosya:** `hibrit/PROFILE_ALGORITHM.md` (az önce oluşturduğumuz)
- Detaylı algoritma açıklaması
- Optimizasyon soruların listesi
- Beklenen ChatGPT çıktıları

---

### 🔥 ÖNEMLİ NOKTA:
ChatGPT'ye şunu söyle: 
> "Bu dosyalardaki meal planning algoritmasını profil bilgilerine göre optimize et. Şu konulara odaklan: kalori dağılımı, protein timing, goal-specific patterns, activity adjustments, yaş bazında metabolik ayarlar."

### 🎯 ChatGPT'den İstenecekler:

1. **Yeni dağılım oranları** (`distribution` map'i için)
2. **Protein timing optimizasyonu** (öğün bazında minimum protein)
3. **Goal/hedef bazında patternler** (lose/maintain/gain stratejileri)
4. **Activity level adjustments** (sedenter/light/moderate/very_active)
5. **Age-related metabolic changes** (yaş bazlı kalori/protein ayarları)

### 📥 ChatGPT Çıktısı Formatı:
```dart
// ChatGPT'den gelecek optimize edilmiş algoritma kodu
final optimizedDistribution = {
  'Kahvaltı': {'cal': X.XX, 'protein': X.XX},
  'Öğle': {'cal': X.XX, 'protein': X.XX},
  // vs...
};
```

Bu hazır dosyaları ChatGPT'ye yapıştır ve algoritma optimizasyonu talep et! 🚀
