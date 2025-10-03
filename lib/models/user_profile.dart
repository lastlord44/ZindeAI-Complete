import 'dart:math';
import '../utils/json_safe.dart';

enum Sex { male, female }

enum Goal {
  cut,
  maintain,
  bulk,
  gain_muscle_loss_fat,
  gain_strength,
  gain_muscle_gain_weight
}

enum Activity { sedentary, light, moderate, very_active }

class UserProfile {
  final Sex sex;
  final int age;
  final int heightCm;
  final double weightKg;
  final Goal goal;
  final Activity activity;
  final double? bodyFatPct;
  final int trainingDaysPerWeek;
  final List<String> dietFlags;
  final List<String> dislikes;
  final TrainingPreferences training;

  const UserProfile({
    required this.sex,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.goal,
    required this.activity,
    this.bodyFatPct,
    this.trainingDaysPerWeek = 3,
    this.dietFlags = const [],
    this.dislikes = const [],
    required this.training,
  });

  // --- Bilimsel Kalori Hesapları ---
  // Mifflin-St Jeor (varsayılan, endüstri standardı)
  double _bmrMifflin() {
    final s = (sex == Sex.male) ? 5.0 : -161.0;
    return 10 * weightKg + 6.25 * heightCm - 5 * age + s;
  }

  // Body fat varsa Katch-McArdle (LBM tabanlı) daha doğru
  double _bmrKatch() {
    if (bodyFatPct == null) return _bmrMifflin();
    final lbm = weightKg * (1 - (bodyFatPct!.clamp(5, 60) / 100.0));
    return 370 + 21.6 * lbm;
  }

  double _activityMultiplier() {
    switch (activity) {
      case Activity.sedentary:
        return 1.375; // çok düşük aktif
      case Activity.light:
        return 1.55; // hafif aktif
      case Activity.moderate:
        return 1.725; // çok aktif
      case Activity.very_active:
        return 1.9; // atletik/seçkin aktif
    }
  }

  /// En güvenilir yaklaşım: (bodyFat varsa Katch), yoksa Mifflin + aktivite
  double tdeeKcal() {
    final bmr = (bodyFatPct != null) ? _bmrKatch() : _bmrMifflin();
    return bmr * _activityMultiplier();
  }

  /// Hedefe göre kalori ayarla
  double targetKcal() {
    final base = tdeeKcal();
    switch (goal) {
      case Goal.cut:
        return base * 0.80;
      case Goal.maintain:
        return base;
      case Goal.bulk:
        return base * 1.15;
      case Goal.gain_muscle_gain_weight:
        return base * 1.20;
      case Goal.gain_muscle_loss_fat:
        return base * 1.05;
      case Goal.gain_strength:
        return base * 1.10;
    }
  }

  /// Makroları belirle (protein öncelikli; yağ yüzdesi; karbonhidrat kalan)
  Map<String, double> macroTargets() {
    final kcal = targetKcal();

    // Optimized protein calculation
    double proteinPerKg;
    switch (goal) {
      case Goal.cut:
        proteinPerKg = 2.2;
      case Goal.maintain:
        proteinPerKg = 2.0;
      case Goal.bulk:
        proteinPerKg = 1.8;
      case Goal.gain_muscle_gain_weight:
        proteinPerKg = 2.3;
      case Goal.gain_muscle_loss_fat:
        proteinPerKg = 2.1;
      case Goal.gain_strength:
        proteinPerKg = 2.4;
    }

    final proteinG = (proteinPerKg * weightKg).clamp(70.0, 240.0);

    // Smart macro distribution
    double fatPct;
    switch (goal) {
      case Goal.cut:
        fatPct = 0.25;
      case Goal.maintain:
        fatPct = 0.30;
      case Goal.bulk:
        fatPct = 0.20;
      case Goal.gain_muscle_gain_weight:
        fatPct = 0.20;
      case Goal.gain_muscle_loss_fat:
        fatPct = 0.28;
      case Goal.gain_strength:
        fatPct = 0.25;
    }

    final fatKcal = kcal * fatPct;
    final fatG = fatKcal / 9.0;

    final proteinKcal = proteinG * 4.0;
    final remainingKcal = max(0, kcal - proteinKcal - fatKcal);
    final carbG =
        (remainingKcal / 4.0).roundToDouble(); // PATCH 6: Rounding fix

    return {
      "kcal": (kcal).roundToDouble(),
      "protein_g": proteinG,
      "fat_g": fatG,
      "carb_g": carbG,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'sex': sex == Sex.male ? 'male' : 'female',
      'age': age,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'goal': goal.toString().split('.').last,
      'activity': activity.toString().split('.').last,
      'body_fat_pct': bodyFatPct,
      'training_days_per_week': trainingDaysPerWeek,
      'diet_flags': dietFlags,
      'dislikes': dislikes,
      'training': training.toJson(),
    };
  }

  // === SAFE & ROBUST fromJson (INT→BOOL bug fix + alan isimleri normalize) ===
  factory UserProfile.fromJson(Map<String, dynamic> j) {
    // ---- küçük yardımcılar
    T? asNum<T extends num>(dynamic v) => (v is num) ? v as T : null;
    String asStr(dynamic v, [String d = ""]) => (v == null) ? d : v.toString();

    Sex parseSex(dynamic v) {
      final s = asStr(v, "M").toLowerCase();
      return (s == "m" || s == "male" || s == "erkek") ? Sex.male : Sex.female;
    }

    Goal parseGoal(dynamic v) {
      final s = asStr(v, "maintain").toLowerCase();
      switch (s) {
        case "cut":
        case "weight_loss":
        case "fat_loss":
        case "kilo_verme":
        case "lose":
          return Goal.cut;
        case "bulk":
        case "gain":
        case "gain_muscle":
        case "gain_muscle_gain_weight":
        case "kilo_alma":
        case "kas_kazanma_kilo_alma":
          return Goal.bulk;
        case "gain_muscle_loss_fat":
          return Goal.gain_muscle_loss_fat;
        case "gain_strength":
          return Goal.gain_strength;
        default:
          return Goal.maintain;
      }
    }

    Activity parseAct(dynamic v) {
      final s = asStr(v, "moderate").toLowerCase();
      switch (s) {
        case "low":
        case "sedentary":
        case "dusuk":
          return Activity.sedentary; // 1.375
        case "light":
          return Activity.light; // 1.55
        case "moderate":
          return Activity.moderate; // 1.725 (very_active)
        case "high":
        case "very_active":
        case "cok":
          return Activity.very_active; // 1.9 (athlete)
        case "athlete":
        case "extra_active":
          return Activity.very_active; // 1.9 (athlete)
        default:
          return Activity.moderate; // 1.725
      }
    }

    TrainingMode parseMode(dynamic v) {
      final s = asStr(v, "hybrid").toLowerCase();
      switch (s) {
        case "gym":
          return TrainingMode.gym;
        case "home":
          return TrainingMode.home;
        default:
          return TrainingMode.hybrid;
      }
    }

    SplitPreference parseSplit(dynamic v) {
      final s = asStr(v, "pushPullLegs").toLowerCase();
      switch (s) {
        case "upperlower":
        case "upper_lower":
          return SplitPreference.upperLower;
        case "pushpulllegs":
        case "push_pull_legs":
          return SplitPreference.pushPullLegs;
        case "fullbody":
        case "full_body":
          return SplitPreference.fullBody;
        case "brosplit":
        case "bro_split":
          return SplitPreference.broSplit;
        default:
          return SplitPreference.custom;
      }
    }

    // ---- kök alanlar (esnek anahtar adları destekli)
    final sex = parseSex(j["sex"] ?? j["gender"]);
    final age = asNum<int>(j["age"]) ?? 25;
    final heightCm =
        asNum<int>(j["height_cm"]) ?? asNum<int>(j["height"]) ?? 170;
    final weightKg =
        (asNum<num>(j["weight_kg"]) ?? asNum<num>(j["weight"]) ?? 70)
            .toDouble();

    // goal hem `goal` hem `primary_goal` olabilir; gönderdiğin örnek: gain_muscle_gain_weight
    final goal = parseGoal(j["goal"] ?? j["primary_goal"]);
    // activity: "moderate" gönderiyorsun → Activity.moderate
    final activity = parseAct(j["activity"] ?? j["activity_level"]);

    final dietFlags =
        (j["diet_flags"] as List?)?.map((e) => e.toString()).toList() ??
            const <String>[];
    final dislikes =
        (j["dislikes"] as List?)?.map((e) => e.toString()).toList() ??
            const <String>[];

    // ---- training bloğu (NULL→Map korunuyor)
    final Map<String, dynamic> tj = asMap(j["training"]);
    final List<String> days =
        asList<String>(tj["days"]).map((e) => e.toString()).toList();

    final dpwExplicit = (tj["daysPerWeek"] is int)
        ? tj["daysPerWeek"] as int
        : (j["training_days_per_week"] is int)
            ? j["training_days_per_week"] as int
            : (j["daysOfWeek"] is int)
                ? j["daysOfWeek"] as int
                : null;

    final daysPerWeek = (dpwExplicit != null && dpwExplicit > 0)
        ? dpwExplicit
        : (days.isNotEmpty ? days.length : 3);

    final equipment =
        asList<String>(tj["equipment"]).map((e) => e.toString()).toList();

    final mode = parseMode(tj["mode"] ?? j["mode"]);
    final split = parseSplit(
        tj["splitPreference"] ?? tj["preferredSplit"] ?? j["preferredSplit"]);

    final tp = TrainingPreferences(
      days: days,
      daysPerWeek: daysPerWeek,
      mode: mode,
      splitPreference: split,
      equipment: equipment,
    );

    // body fat opsiyonel
    final bodyFat = asNum<num>(j["body_fat_pct"])?.toDouble();

    // ---- nihai nesne
    return UserProfile(
      sex: sex,
      age: age,
      heightCm: heightCm,
      weightKg: weightKg,
      goal: goal,
      activity: activity,
      bodyFatPct: bodyFat,
      trainingDaysPerWeek: daysPerWeek,
      dietFlags: dietFlags,
      dislikes: dislikes,
      training: tp,
    );
  }
}

// --- TRAINING MODEL & ENUMS (DROP-IN) ---

enum TrainingMode { gym, home, hybrid }

enum SplitPreference { upperLower, pushPullLegs, fullBody, broSplit, custom }

class TrainingPreferences {
  /// Haftalık gün sayısı (ör. 3). Sağlanmazsa `days.length` kullanılır.
  final int daysPerWeek;

  /// gym | home | hybrid
  final TrainingMode mode;

  /// upperLower | pushPullLegs | fullBody | broSplit | custom
  final SplitPreference splitPreference;

  /// Örn: ["barbell","dumbbell","band","bodyweight"]
  final List<String> equipment;

  /// UI'den seçilen gün adları. (Örn: ["Monday","Wednesday","Friday"])
  final List<String> days;

  const TrainingPreferences({
    required this.mode,
    required this.splitPreference,
    this.equipment = const [],
    List<String> days = const [],
    int? daysPerWeek,
  })  : days = days,
        daysPerWeek = daysPerWeek ?? days.length,
        assert((daysPerWeek ?? days.length) >= 1, 'daysPerWeek must be >= 1');

  factory TrainingPreferences.fromJson(Map<String, dynamic> json) {
    TrainingMode parseMode(String? s) {
      switch (s) {
        case 'gym':
          return TrainingMode.gym;
        case 'home':
          return TrainingMode.home;
        default:
          return TrainingMode.hybrid;
      }
    }

    SplitPreference parseSplit(String? s) {
      switch (s) {
        case 'upperLower':
        case 'upper_lower':
          return SplitPreference.upperLower;
        case 'pushPullLegs':
        case 'push_pull_legs':
          return SplitPreference.pushPullLegs;
        case 'fullBody':
        case 'full_body':
          return SplitPreference.fullBody;
        case 'broSplit':
        case 'bro_split':
          return SplitPreference.broSplit;
        default:
          return SplitPreference.custom;
      }
    }

    final eq = (json['equipment'] as List?)?.cast<String>() ?? const <String>[];
    final dy = (json['days'] as List?)?.cast<String>() ?? const <String>[];

    final dpw = (json['daysPerWeek'] is int)
        ? (json['daysPerWeek'] as int)
        : (json['daysPerWeek'] is String)
            ? int.tryParse(json['daysPerWeek']) ?? dy.length
            : dy.length;

    return TrainingPreferences(
      mode: parseMode(json['mode'] as String?),
      splitPreference: parseSplit(json['splitPreference'] as String?),
      equipment: eq,
      days: dy,
      daysPerWeek: dpw,
    );
  }

  Map<String, dynamic> toJson() => {
        'daysPerWeek': daysPerWeek,
        'mode': mode.toString().split('.').last,
        'splitPreference': splitPreference.toString().split('.').last,
        'equipment': equipment,
        'days': days,
      };
}
