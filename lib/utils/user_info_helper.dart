// Bu fonksiyon profil bilgilerini alıp Edge Function'a gönderilecek
// user_info string'ini oluşturur

class UserInfoHelper {
  
  static String createUserInfoString(Map<String, dynamic> profile) {
    final StringBuffer info = StringBuffer();
    
    // Temel bilgiler
    info.writeln('İsim: ${profile['name']}');
    info.writeln('Yaş: ${profile['age']}');
    info.writeln('Cinsiyet: ${profile['gender']}');
    info.writeln('Boy: ${profile['height']} cm');
    info.writeln('Kilo: ${profile['weight']} kg');
    
    // Fitness bilgileri
    info.writeln('Fitness Seviyesi: ${profile['fitness_level']}');
    info.writeln('Aktivite Seviyesi: ${profile['activity_level']}');
    
    // Hedef bilgileri
    info.writeln('Ana Hedef: ${profile['primary_goal']}');
    
    // Kas koruma durumu (önemli!)
    if (profile['preserve_muscle'] == true) {
      info.writeln('Özel Durum: KAS KÜTLESİ KORUMA AKTİF');
      info.writeln('Not: Yüksek protein, yavaş kilo kaybı, ağırlık antrenmanı öncelikli');
    }
    
    // Antrenman bilgileri
    info.writeln('Haftalık Antrenman Günü: ${profile['workout_days']}');
    
    // Diyet tercihi
    info.writeln('Diyet Tipi: ${profile['diet_type']}');
    
    // Diyet notları
    switch (profile['diet_type']) {
      case 'Vejetaryen':
        info.writeln('Diyet Notu: Et YOK, süt/yumurta VAR');
        break;
      case 'Vegan':
        info.writeln('Diyet Notu: Hayvansal ürün YOK, sadece bitkisel');
        break;
      case 'Ketojenik':
        info.writeln('Diyet Notu: Çok düşük karb (max 30g), yüksek yağ');
        break;
      case 'Paleo':
        info.writeln('Diyet Notu: Tahıl YOK, baklagil YOK, işlenmiş YOK');
        break;
    }
    
    return info.toString();
  }
  
  // API'ye gönderilecek request body'yi oluştur
  static Map<String, dynamic> createAPIRequest({
    required Map<String, dynamic> profile,
    required String requestType, // 'nutrition' veya 'workout'
  }) {
    
    final userInfo = createUserInfoString(profile);
    
    return {
      'requestType': requestType,
      'userInfo': userInfo,
      'profile': profile, // Ham profil datası da gönder
    };
  }
  
  // Makro hesaplayıcı (referans için)
  static Map<String, double> calculateMacros(Map<String, dynamic> profile) {
    double weight = profile['weight']?.toDouble() ?? 70.0;
    double height = profile['height']?.toDouble() ?? 170.0;
    int age = profile['age'] ?? 30;
    String gender = profile['gender'] ?? 'Erkek';
    String goal = profile['primary_goal'] ?? 'Bakım';
    bool preserveMuscle = profile['preserve_muscle'] ?? false;
    String activityLevel = profile['activity_level'] ?? 'Orta Aktif';
    
    // BMR Hesapla (Mifflin-St Jeor)
    double bmr;
    if (gender == 'Erkek') {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }
    
    // TDEE Hesapla
    double activityMultiplier = 1.55; // varsayılan
    switch (activityLevel) {
      case 'Sedanter (Hareketsiz)':
        activityMultiplier = 1.2;
        break;
      case 'Hafif Aktif':
        activityMultiplier = 1.375;
        break;
      case 'Orta Aktif':
        activityMultiplier = 1.55;
        break;
      case 'Çok Aktif':
        activityMultiplier = 1.725;
        break;
      case 'Aşırı Aktif':
        activityMultiplier = 1.9;
        break;
    }
    
    double tdee = bmr * activityMultiplier;
    
    // Kalori hedefi
    double targetCalories = tdee;
    switch (goal) {
      case 'Kilo Verme':
        targetCalories = preserveMuscle ? tdee - 300 : tdee - 500;
        break;
      case 'Kas Kazanma':
      case 'Kilo Alma':
        targetCalories = tdee + 500;
        break;
      case 'Güç Kazanma':
        targetCalories = tdee + 300;
        break;
    }
    
    // Protein hesapla
    double proteinMultiplier = 2.0;
    if (goal == 'Kilo Verme' && preserveMuscle) {
      proteinMultiplier = 2.5; // Kas koruma için yüksek protein
    } else if (goal == 'Kas Kazanma') {
      proteinMultiplier = 2.3;
    } else if (goal == 'Bakım') {
      proteinMultiplier = 1.8;
    }
    
    double protein = weight * proteinMultiplier;
    
    // Yağ hesapla
    double fat = weight * 1.0; // Minimum
    
    // Karbonhidrat hesapla (kalan kalori)
    double proteinCalories = protein * 4;
    double fatCalories = fat * 9;
    double remainingCalories = targetCalories - proteinCalories - fatCalories;
    double carbs = remainingCalories / 4;
    
    // Ketojenik diyet ayarlaması
    if (profile['diet_type'] == 'Ketojenik') {
      carbs = 30; // Max 30g karb
      fat = (targetCalories - (protein * 4) - (carbs * 4)) / 9;
    }
    
    return {
      'calories': targetCalories,
      'protein': protein,
      'carbs': carbs > 0 ? carbs : 0,
      'fat': fat,
      'tdee': tdee,
      'bmr': bmr,
    };
  }
}

// Kullanım örneği:
void exampleUsage() {
  final profile = {
    'name': 'Ahmet Yılmaz',
    'age': 30,
    'height': 180,
    'weight': 75.0,
    'gender': 'Erkek',
    'fitness_level': 'Orta',
    'activity_level': 'Orta Aktif',
    'primary_goal': 'Kilo Verme',
    'preserve_muscle': true, // Kas koruma aktif!
    'workout_days': 4,
    'diet_type': 'Dengeli',
  };
  
  // API isteği oluştur
  final nutritionRequest = UserInfoHelper.createAPIRequest(
    profile: profile,
    requestType: 'nutrition',
  );
  
  print(nutritionRequest['userInfo']);
  
  // Makroları hesapla (referans için)
  final macros = UserInfoHelper.calculateMacros(profile);
  print('Günlük Kalori: ${macros['calories']?.toStringAsFixed(0)}');
  print('Protein: ${macros['protein']?.toStringAsFixed(0)}g');
  print('Karbonhidrat: ${macros['carbs']?.toStringAsFixed(0)}g');
  print('Yağ: ${macros['fat']?.toStringAsFixed(0)}g');
}
